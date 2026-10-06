from __future__ import annotations

import re
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.parse import unquote


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def public_repository_files(root: Path) -> list[Path]:
    """Include published and candidate files without walking ignored private trees."""
    result = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        cwd=root, check=True, capture_output=True,
    )
    paths = {root / name.decode("utf-8") for name in result.stdout.split(b"\0") if name}
    return sorted(path for path in paths if path.is_file())


class PublicRepositoryTests(unittest.TestCase):
    def test_required_public_repository_files_exist(self) -> None:
        required = (
            ".gitignore",
            "README.md",
            "LICENSE",
            "SECURITY.md",
            "CONTRIBUTING.md",
            "CODE_OF_CONDUCT.md",
            "docs/Project-Overview.md",
            "docs/Implementation-Plan.md",
            "docs/Project-Implementation-Plan.md",
            "docs/Product-Brief.md",
            "docs/Decision-Log.md",
            "docs/Feasibility-Spike.md",
            "Honkshool.xcodeproj/project.pbxproj",
            "Honkshool.xcodeproj/xcshareddata/xcschemes/Honkshool.xcscheme",
            "Honkshool/App/HonkshoolApp.swift",
            "Honkshool/App/FeasibilityConsoleView.swift",
            "Honkshool/App/UITestFixtures.swift",
            "Honkshool/Domain/SpikeModels.swift",
            "Honkshool/Services/AudioSpikeController.swift",
            "Honkshool/Services/AlarmSpikeService.swift",
            "Honkshool/Resources/Info.plist",
            "Honkshool/Resources/GeorgeNarration-Provenance.json",
            "Honkshool/Resources/Turning-Fuel-Into-Motion-George.wav",
            "Honkshool/Resources/Air-Fuel-and-Spark-George.wav",
            "Honkshool/Resources/Air-Fuel-and-Spark-George-Provenance.json",
            "HonkshoolTests/SpikeModelsTests.swift",
            "HonkshoolUITests/FeasibilityUITests.swift",
            "HonkshoolAlarmWidget/AlarmLockScreenLayout.swift",
            "HonkshoolAlarmWidget/HonkshoolAlarmWidget.swift",
            "HonkshoolTests/AlarmLockScreenLayoutTests.swift",
            "Config/Signing.xcconfig",
            "Config/Local.xcconfig.example",
            ".github/pull_request_template.md",
            ".github/ISSUE_TEMPLATE/config.yml",
            ".github/ISSUE_TEMPLATE/bug_report.yml",
            ".github/ISSUE_TEMPLATE/feature_request.yml",
            ".github/workflows/ci.yml",
            "scripts/verify-repository.sh",
            "scripts/test-ios.sh",
            "scripts/prepare-kokoro-narration.py",
        )

        missing = [path for path in required if not (PROJECT_ROOT / path).is_file()]
        self.assertEqual(missing, [])

    def test_readme_is_honest_about_feasibility_status(self) -> None:
        readme = (PROJECT_ROOT / "README.md").read_text(encoding="utf-8")

        for statement in (
            "Project status:** Feasibility spike",
            "there is no supported release",
            "calm, uninterrupted factual narration",
            "does not claim subconscious learning",
            "./scripts/verify-repository.sh",
            "SECURITY.md",
            "MIT License",
        ):
            with self.subTest(statement=statement):
                self.assertIn(statement, readme)

    def test_ios_spike_preserves_platform_and_safety_configuration(self) -> None:
        project = (PROJECT_ROOT / "Honkshool.xcodeproj/project.pbxproj").read_text(
            encoding="utf-8"
        )
        info = (PROJECT_ROOT / "Honkshool/Resources/Info.plist").read_text(
            encoding="utf-8"
        )
        audio = (
            PROJECT_ROOT / "Honkshool/Services/AudioSpikeController.swift"
        ).read_text(encoding="utf-8")
        alarm = (
            PROJECT_ROOT / "Honkshool/Services/AlarmSpikeService.swift"
        ).read_text(encoding="utf-8")
        signing = (PROJECT_ROOT / "Config/Signing.xcconfig").read_text(
            encoding="utf-8"
        )

        self.assertIn("com.joshuawyadao.Honkshool", project)
        self.assertIn("IPHONEOS_DEPLOYMENT_TARGET = 26.0", project)
        self.assertIn("NSAlarmKitUsageDescription", info)
        self.assertIn("<string>audio</string>", info)
        self.assertIn("setCategory(.playback, mode: .spokenAudio, options: [])", audio)
        self.assertIn("AlarmManager.shared", alarm)
        self.assertIn("baseConfigurationReference", project)
        self.assertIn('#include? "Local.xcconfig"', signing)
        self.assertNotRegex(
            project + signing,
            r"DEVELOPMENT_TEAM\s*=\s*[A-Z0-9]{10}",
        )

    def test_product_context_and_roadmap_preserve_key_boundaries(self) -> None:
        brief = (PROJECT_ROOT / "docs/Product-Brief.md").read_text(encoding="utf-8")
        project_plan = (
            PROJECT_ROOT / "docs/Project-Implementation-Plan.md"
        ).read_text(encoding="utf-8")
        decisions = (PROJECT_ROOT / "docs/Decision-Log.md").read_text(
            encoding="utf-8"
        )

        for statement in (
            "Helping the listener relax and fall asleep is the primary purpose",
            "played**, not learned, mastered, or retained",
            "Once playback starts, the route is fixed",
            "No backend, accounts, analytics, cloud sync, subscriptions, ads",
            "approximately ten real naps",
        ):
            with self.subTest(document="product brief", statement=statement):
                self.assertIn(statement, brief)

        for statement in (
            "spike/audio-and-alarm-feasibility",
            "codex/nap-plan-domain",
            "codex/nap-playback-runtime",
            "validation/ten-nap-trial",
            "Physical-device acceptance",
        ):
            with self.subTest(
                document="project implementation plan", statement=statement
            ):
                self.assertIn(statement, project_plan)

        for decision_id in ("D-001", "D-003", "D-004", "D-010", "D-017", "D-024"):
            with self.subTest(document="decision log", decision_id=decision_id):
                self.assertIn(decision_id, decisions)

    def test_durable_project_plan_is_distinct_from_replaceable_task_plan(self) -> None:
        readme = (PROJECT_ROOT / "README.md").read_text(encoding="utf-8")
        overview = (PROJECT_ROOT / "docs/Project-Overview.md").read_text(
            encoding="utf-8"
        )

        self.assertIn("docs/Project-Implementation-Plan.md", readme)
        self.assertIn("docs/Implementation-Plan.md", readme)
        self.assertIn("Task plans may be overwritten", overview)

    def test_privacy_sensitive_artifacts_are_ignored(self) -> None:
        ignore = (PROJECT_ROOT / ".gitignore").read_text(encoding="utf-8")

        for pattern in (
            ".env",
            "*.key",
            "*.pem",
            "credentials*.json",
            "secrets*.json",
            "Local.xcconfig",
            "*.mobileprovision",
            "/local-data/",
            "/reports/",
            "*.sqlite",
            "*.log",
        ):
            with self.subTest(pattern=pattern):
                self.assertIn(pattern, ignore)

    def test_ci_uses_read_only_pinned_quota_aware_workflow(self) -> None:
        workflow = (PROJECT_ROOT / ".github/workflows/ci.yml").read_text(
            encoding="utf-8"
        )

        self.assertIn("pull_request:", workflow)
        self.assertIn("workflow_dispatch:", workflow)
        self.assertNotRegex(workflow, r"(?m)^  push:")
        self.assertIn("contents: read", workflow)
        self.assertIn("persist-credentials: false", workflow)
        self.assertRegex(workflow, r"actions/checkout@[0-9a-f]{40}")
        self.assertIn("cancel-in-progress: true", workflow)

    def test_ios_tests_run_in_pull_requests_with_debug_only_fixtures(self) -> None:
        workflow = (PROJECT_ROOT / ".github/workflows/ci.yml").read_text(
            encoding="utf-8"
        )
        test_script = (PROJECT_ROOT / "scripts/test-ios.sh").read_text(
            encoding="utf-8"
        )
        fixtures = (
            PROJECT_ROOT / "Honkshool/App/UITestFixtures.swift"
        ).read_text(encoding="utf-8")
        ui_tests = (
            PROJECT_ROOT / "HonkshoolUITests/FeasibilityUITests.swift"
        ).read_text(encoding="utf-8")

        self.assertIn("runs-on: macos-26", workflow)
        self.assertIn("./scripts/test-ios.sh", workflow)
        self.assertIn("timeout-minutes: 60", workflow)
        self.assertIn("xcodebuild -quiet", test_script)
        self.assertIn("-parallel-testing-enabled NO", test_script)
        self.assertIn("HONKSHOOL_TEST_DESTINATION", test_script)
        self.assertTrue(test_script.startswith("#!/bin/sh\nset -eu\n"))
        self.assertIn("#if DEBUG", fixtures)
        self.assertIn('launchArgument = "-ui-testing"', fixtures)
        self.assertIn('app.launchArguments = ["-ui-testing"]', ui_tests)

    def test_alarm_lock_screen_layout_preserves_larger_text_support(self) -> None:
        layout = (
            PROJECT_ROOT / "HonkshoolAlarmWidget/AlarmLockScreenLayout.swift"
        ).read_text(encoding="utf-8")
        tests = (
            PROJECT_ROOT / "HonkshoolTests/AlarmLockScreenLayoutTests.swift"
        ).read_text(encoding="utf-8")

        self.assertIn(".padding(.horizontal, 14)", layout)
        self.assertNotIn(".dynamicTypeSize(", layout)
        self.assertIn("DynamicTypeSize.xLarge", tests)
        self.assertIn(".accessibility1", tests)
        self.assertIn("160", tests)

    def test_markdown_relative_links_resolve(self) -> None:
        broken: list[str] = []
        link_pattern = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")

        for markdown in public_repository_files(PROJECT_ROOT):
            if markdown.suffix != ".md":
                continue
            content = markdown.read_text(encoding="utf-8")
            for target in link_pattern.findall(content):
                cleaned = target.strip().split()[0].strip("<>")
                if cleaned.startswith(("http://", "https://", "mailto:", "#")):
                    continue
                relative = unquote(cleaned.split("#", 1)[0])
                if relative and not (markdown.parent / relative).exists():
                    broken.append(f"{markdown.relative_to(PROJECT_ROOT)} -> {target}")

        self.assertEqual(broken, [])

    def test_working_tree_has_no_unignored_private_or_generated_artifacts(self) -> None:
        forbidden_names = {
            ".DS_Store",
            "Local.xcconfig",
            "Secrets.xcconfig",
        }
        forbidden_suffixes = {
            ".key",
            ".pem",
            ".p8",
            ".p12",
            ".pfx",
            ".mobileprovision",
            ".sqlite",
            ".sqlite3",
            ".db",
            ".log",
        }
        offenders: list[str] = []

        for path in public_repository_files(PROJECT_ROOT):
            if path.name in forbidden_names or path.suffix.lower() in forbidden_suffixes:
                offenders.append(str(path.relative_to(PROJECT_ROOT)))

        self.assertEqual(offenders, [])

    def test_public_docs_do_not_contain_device_identifiers(self) -> None:
        device_identifier = re.compile(
            r"\b(?:"
            r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-"
            r"[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"
            r"|[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}"
            r")\b"
        )
        offenders: list[str] = []

        for path in (*PROJECT_ROOT.glob("*.md"), *PROJECT_ROOT.glob("docs/*.md")):
            if device_identifier.search(path.read_text(encoding="utf-8")):
                offenders.append(str(path.relative_to(PROJECT_ROOT)))

        self.assertEqual(offenders, [])


class PublicationScopeTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.git("init", "--quiet")
        (self.root / ".gitignore").write_text(
            "/local-data/\n/outputs/\n.venv/\n*.key\n/ignored-public.md\n")
        (self.root / "README.md").write_text("# Public fixture\n")

    def git(self, *arguments: str) -> None:
        subprocess.run(["git", *arguments], cwd=self.root, check=True,
                       capture_output=True)

    def run_gate(self, method: str) -> unittest.TestResult:
        result = unittest.TestResult()
        with patch(__name__ + ".PROJECT_ROOT", self.root):
            PublicRepositoryTests(method).run(result)
        self.assertEqual(result.errors, [], "The gate must evaluate its inputs without errors")
        return result

    def test_ignored_private_and_generated_markdown_cannot_break_public_gate(self):
        for directory in ("local-data", "outputs", ".venv"):
            path = self.root / directory / "notes.md"
            path.parent.mkdir()
            path.write_text("[private note](missing.md)\n")
        result = self.run_gate("test_markdown_relative_links_resolve")
        self.assertTrue(result.wasSuccessful(), result.failures)

    def test_nonignored_untracked_document_with_broken_link_still_fails(self):
        (self.root / "new public.md").write_text("[reference](missing.md)\n")
        result = self.run_gate("test_markdown_relative_links_resolve")
        self.assertEqual(len(result.failures), 1)
        self.assertIn("new public.md", result.failures[0][1])

    def test_tracked_document_is_checked_even_when_its_name_matches_ignore_rule(self):
        (self.root / "ignored-public.md").write_text("[reference](missing.md)\n")
        self.git("add", "--force", "ignored-public.md")
        result = self.run_gate("test_markdown_relative_links_resolve")
        self.assertEqual(len(result.failures), 1)
        self.assertIn("ignored-public.md", result.failures[0][1])

    def test_tracked_ignored_name_artifact_is_still_rejected(self):
        (self.root / "synthetic.key").write_text("synthetic fixture, not a credential\n")
        self.git("add", "--force", "synthetic.key")
        result = self.run_gate("test_working_tree_has_no_unignored_private_or_generated_artifacts")
        self.assertEqual(len(result.failures), 1)
        self.assertIn("synthetic.key", result.failures[0][1])

    def test_untracked_nonignored_sensitive_artifact_is_still_rejected(self):
        (self.root / "synthetic.pem").write_text("synthetic fixture, not a credential\n")
        result = self.run_gate("test_working_tree_has_no_unignored_private_or_generated_artifacts")
        self.assertEqual(len(result.failures), 1)
        self.assertIn("synthetic.pem", result.failures[0][1])


if __name__ == "__main__":
    unittest.main()
