"""Portable checks for result publication and failure preservation in the iOS runner."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class IOSRunnerTests(unittest.TestCase):
    def run_runner(self, exit_code, summary_valid=True, scope=None, shard=None,
                   verbose=None, invalid=False):
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
            if verbose is not None:
                env["HONKSHOOL_TEST_VERBOSE"] = verbose
            if scope is not None:
                env["HONKSHOOL_TEST_SCOPE"] = scope
            if shard is not None:
                env["HONKSHOOL_UI_SHARD"] = shard
            result = subprocess.run(
                ["sh", str(ROOT / "scripts/test-ios.sh")],
                env=env, capture_output=True, text=True, check=False,
            )
            if invalid:
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
        self.assertIn("-quiet", args)
        self.assertEqual(args[args.index("-parallel-testing-enabled") + 1], "NO")

    def test_verbose_ci_keeps_full_tests_and_results_without_quiet_filter(self):
        result, args = self.run_runner(0, verbose="1")
        self.assertEqual(result.returncode, 0)
        self.assertNotIn("-quiet", args)
        self.assertNotIn("-only-testing:HonkshoolTests", args)
        self.assertIn("-resultBundlePath", args)
        self.assertEqual(args[-1], "test")

    def test_verbose_failure_preserves_original_exit_and_summary(self):
        result, _ = self.run_runner(65, verbose="1")
        self.assertEqual(result.returncode, 65)
        self.assertIn("Playback: Expected Stopped", result.stdout)

    def test_invalid_verbosity_fails_before_results_or_xcode(self):
        result, _ = self.run_runner(0, verbose="invalid", invalid=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("must be 0 or 1", result.stderr)

    def test_unit_scope_selects_only_unit_tests(self):
        result, args = self.run_runner(0, scope="unit")
        self.assertEqual(result.returncode, 0)
        self.assertIn("-only-testing:HonkshoolTests", args)
        self.assertEqual(args[-1], "test")

    def test_ui_shards_partition_entire_ui_target(self):
        _, all_ui = self.run_runner(0, scope="ui")
        _, review = self.run_runner(0, scope="ui", shard="plan-review")
        _, other = self.run_runner(0, scope="ui", shard="other")
        self.assertIn("-only-testing:HonkshoolUITests", all_ui)
        self.assertNotIn("-skip-testing:HonkshoolUITests/NapPlanReviewUITests", all_ui)
        self.assertIn("-only-testing:HonkshoolUITests/NapPlanReviewUITests", review)
        self.assertNotIn("-only-testing:HonkshoolUITests", review)
        self.assertIn("-only-testing:HonkshoolUITests", other)
        self.assertIn("-skip-testing:HonkshoolUITests/NapPlanReviewUITests", other)

    def test_invalid_selector_combinations_fail_before_xcode_or_results(self):
        cases = (
            ("invalid", None, "HONKSHOOL_TEST_SCOPE"),
            ("ui", "invalid", "HONKSHOOL_UI_SHARD"),
            ("unit", "plan-review", "requires HONKSHOOL_TEST_SCOPE=ui"),
            (None, "other", "requires HONKSHOOL_TEST_SCOPE=ui"),
        )
        for scope, shard, error in cases:
            with self.subTest(scope=scope, shard=shard):
                result, _ = self.run_runner(0, scope=scope, shard=shard, invalid=True)
                self.assertEqual(result.returncode, 2)
                self.assertIn(error, result.stderr)

    def test_failure_publishes_bundle_and_preserves_test_exit_code(self):
        result, _ = self.run_runner(65)
        self.assertEqual(result.returncode, 65)
        self.assertIn("2 passed, 1 failed, 0 skipped", result.stdout)
        self.assertIn("Playback: Expected Stopped", result.stdout)

    def test_unreadable_summary_does_not_hide_original_failure(self):
        result, _ = self.run_runner(70, summary_valid=False)
        self.assertEqual(result.returncode, 70)
        self.assertNotIn("PASS:", result.stdout)
