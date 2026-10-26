"""Portable checks for result publication and failure preservation in the iOS runner."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class IOSRunnerTests(unittest.TestCase):
    def run_runner(self, exit_code, summary_valid=True, scope=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            xcodebuild = bin_dir / "xcodebuild"
            xcodebuild.write_text(
                '#!/bin/sh\n'
                'printf "%s\\n" "$@" > "$FAKE_XCODE_ARGS"\n'
                'while [ "$#" -gt 0 ]; do\n'
                '  if [ "$1" = "-resultBundlePath" ]; then mkdir -p "$2"; fi\n'
                '  shift\n'
                'done\n'
                f'exit {exit_code}\n'
            )
            xcrun = bin_dir / "xcrun"
            summary = (
                '{"passedTests": 2, "failedTests": 1, "skippedTests": 0, '
                '"testFailures": [{"testName": "Playback", "failureText": "Expected Stopped"}]}'
                if summary_valid else 'invalid summary'
            )
            xcrun.write_text(f"#!/bin/sh\nprintf '%s\\n' '{summary}'\n")
            for executable in (xcodebuild, xcrun):
                executable.chmod(0o755)
            output = root / "outputs"
            env = os.environ.copy()
            for key in tuple(env):
                if key.startswith("HONKSHOOL_"):
                    del env[key]
            env.update(
                PATH=f"{bin_dir}{os.pathsep}{env['PATH']}",
                HONKSHOOL_XCODE_PATH=str(root),
                GITHUB_OUTPUT=str(output),
                TMPDIR=str(root),
                FAKE_XCODE_ARGS=str(root / "xcode-args"),
            )
            if scope is not None:
                env["HONKSHOOL_TEST_SCOPE"] = scope
            result = subprocess.run(
                ["sh", str(ROOT / "scripts/test-ios.sh")],
                env=env, capture_output=True, text=True, check=False,
            )
            if scope == "invalid":
                self.assertFalse(output.exists())
                self.assertFalse((root / "xcode-args").exists())
                self.assertEqual(list(root.glob("honkshool-test-results.*")), [])
                return result, []
            key, directory = output.read_text().strip().split("=", 1)
            bundle = str(Path(directory) / "TestResults.xcresult")
            self.assertEqual(key, "result_directory")
            self.assertTrue(Path(bundle).is_dir())
            self.assertEqual(Path(bundle).name, "TestResults.xcresult")
            self.assertIn(bundle, result.stdout)
            return result, (root / "xcode-args").read_text().splitlines()

    def test_success_publishes_created_result_bundle(self):
        result, args = self.run_runner(0)
        self.assertEqual(result.returncode, 0)
        self.assertIn("PASS:", result.stdout)
        self.assertEqual(args[-1], "test")
        self.assertNotIn("-only-testing:HonkshoolTests", args)
        self.assertEqual(args[args.index("-parallel-testing-enabled") + 1], "NO")

    def test_unit_scope_selects_only_unit_tests(self):
        result, args = self.run_runner(0, scope="unit")
        self.assertEqual(result.returncode, 0)
        self.assertIn("-only-testing:HonkshoolTests", args)
        self.assertEqual(args[-1], "test")

    def test_invalid_scope_fails_before_creating_results_or_invoking_xcode(self):
        result, _ = self.run_runner(0, scope="invalid")
        self.assertEqual(result.returncode, 2)
        self.assertIn("must be all or unit", result.stderr)

    def test_failure_publishes_bundle_and_preserves_test_exit_code(self):
        result, _ = self.run_runner(65)
        self.assertEqual(result.returncode, 65)
        self.assertIn("2 passed, 1 failed, 0 skipped", result.stdout)
        self.assertIn("Playback: Expected Stopped", result.stdout)

    def test_unreadable_summary_does_not_hide_original_failure(self):
        result, _ = self.run_runner(70, summary_valid=False)
        self.assertEqual(result.returncode, 70)
        self.assertNotIn("PASS:", result.stdout)
