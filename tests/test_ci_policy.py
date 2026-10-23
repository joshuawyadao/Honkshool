"""Portable fixture checks for conservative CI selection and final gating."""

import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/ci-policy.py"
spec = importlib.util.spec_from_file_location("ci_policy", SCRIPT)
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


class CIPolicyTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.git("init", "--quiet")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.write("README.md", "initial\n")
        self.write("App.swift", "initial\n")
        self.base = self.commit()

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.root, check=True,
                              capture_output=True).stdout.decode().strip()

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def commit(self):
        self.git("add", "-A")
        self.git("commit", "--quiet", "-m", "fixture")
        return self.git("rev-parse", "HEAD")

    def check(self, expected):
        self.assertEqual(policy.needs_ios(self.root, self.base, self.commit()), expected)

    def test_known_markdown_and_docs_svg_edits_are_docs_only(self):
        self.write("README.md", "changed\n")
        self.write("docs/guide/scene.svg", "<svg/>\n")
        self.check(False)

    def test_docs_delete_is_docs_only(self):
        self.write("docs/old.md", "old\n")
        self.base = self.commit()
        (self.root / "docs/old.md").unlink()
        self.check(False)

    def test_code_changes_and_unknown_markdown_require_ios(self):
        for name in ("App.swift", "HonkshoolTests/Unit.swift", "Assets/data.json",
                     ".github/workflows/ci.yml", "scripts/verify-repository.sh",
                     "Honkshool.xcodeproj/project.pbxproj", "CHANGELOG.md"):
            with self.subTest(name=name):
                self.write(name, "changed\n")
                head = self.commit()
                self.assertTrue(policy.needs_ios(self.root, self.base, head))

    def test_code_delete_requires_ios(self):
        (self.root / "App.swift").unlink()
        self.check(True)

    def test_renames_classify_both_sides(self):
        self.write("docs/guide.md", "guide\n")
        self.base = self.commit()
        (self.root / "docs/guide.md").rename(self.root / "moved.swift")
        self.check(True)
        self.base = self.git("rev-parse", "HEAD")
        (self.root / "App.swift").rename(self.root / "docs/App.md")
        self.check(True)

    def test_newline_path_is_parsed_without_splitting(self):
        self.write("docs/line\nbreak.md", "text\n")
        self.check(False)

    def test_executable_and_symlink_docs_require_ios(self):
        self.write("docs/executable.md", "text\n")
        (self.root / "docs/executable.md").chmod(0o755)
        self.check(True)
        self.base = self.git("rev-parse", "HEAD")
        (self.root / "docs/link.md").symlink_to("executable.md")
        self.check(True)

    def test_empty_and_bad_references_fail_closed(self):
        with self.assertRaises(policy.PolicyError):
            policy.needs_ios(self.root, self.base, self.base)
        with self.assertRaises(policy.PolicyError):
            policy.needs_ios(self.root, "invalid", self.base)
        with self.assertRaises(policy.PolicyError):
            policy.needs_ios(self.root, "0" * 40, self.base)

    def test_gate_requires_exact_consistent_states(self):
        self.assertTrue(policy.gate("success", "success", "true"))
        self.assertTrue(policy.gate("success", "skipped", "false"))
        for state in (("failure", "skipped", "false"),
                      ("cancelled", "skipped", "false"),
                      ("success", "failure", "true"),
                      ("success", "cancelled", "true"),
                      ("success", "skipped", "true"),
                      ("success", "success", "false"),
                      ("success", "skipped", "")):
            with self.subTest(state=state):
                self.assertFalse(policy.gate(*state))

    def test_dispatch_selects_ios_without_refs(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "classify", "--event", "workflow_dispatch"],
            cwd=self.root, capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("run_ios=true", result.stdout)

    def test_classifier_publishes_exact_boolean_output(self):
        self.write("docs/guide.md", "guide\n")
        head = self.commit()
        output = self.root / "github-output"
        env = dict(os.environ, GITHUB_OUTPUT=str(output))
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "classify", "--event", "pull_request",
             "--base", self.base, "--head", head],
            cwd=self.root, env=env, capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0)
        self.assertEqual(output.read_text(), "run_ios=false\n")

    def test_classifier_error_does_not_publish_output(self):
        output = self.root / "github-output"
        env = dict(os.environ, GITHUB_OUTPUT=str(output))
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "classify", "--event", "pull_request",
             "--base", "invalid", "--head", self.base],
            cwd=self.root, env=env, capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 1)
        self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
