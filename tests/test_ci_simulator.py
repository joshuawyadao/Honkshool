"""Portable subprocess checks for CI's iOS simulator preparation."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/prepare-ios-simulator.py"
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
DEVICE_TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
DEVICE_ID = "0C4744A9-B51D-4247-97E9-42C32E3FC917"

FAKE_TOOL = r'''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

root = Path(os.environ["FAKE_STATE_DIR"])
name = Path(sys.argv[0]).name
args = sys.argv[1:]
with (root / "commands.jsonl").open("a") as log:
    log.write(json.dumps({"tool": name, "args": args,
                          "developer_dir": os.environ.get("DEVELOPER_DIR")}) + "\n")

if name == "xcodebuild":
    if args == ["-version"]:
        print("Xcode 26.6\nBuild version 17G40")
    elif args == ["-runFirstLaunch"]:
        pass
    elif args == ["-downloadPlatform", "iOS", "-buildVersion", "26.5"]:
        if os.environ.get("FAKE_FAIL") == "download":
            sys.exit(42)
        (root / "downloaded").touch()
    elif args[-1:] == ["test"] and "-resultBundlePath" in args:
        result_path = Path(args[args.index("-resultBundlePath") + 1])
        result_path.mkdir(parents=True)
    else:
        sys.exit(91)
elif name == "xcrun":
    if args == ["simctl", "list", "runtimes", "--json"]:
        if os.environ.get("FAKE_BAD_JSON") == "1":
            print("not JSON")
        else:
            mode = os.environ.get("FAKE_RUNTIME_MODE", "installed")
            downloaded = (root / "downloaded").exists()
            available = mode == "installed" or (
                downloaded and os.environ.get("FAKE_UNAVAILABLE_AFTER_DOWNLOAD") != "1"
            )
            runtimes = [] if mode == "missing" and not downloaded else [{
                "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-5",
                "version": "26.5", "isAvailable": available,
            }]
            print(json.dumps({"runtimes": runtimes}))
    elif args == ["simctl", "create", "Honkshool CI",
                  "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
                  "com.apple.CoreSimulator.SimRuntime.iOS-26-5"]:
        print(os.environ.get("FAKE_CREATE_ID", "0C4744A9-B51D-4247-97E9-42C32E3FC917"))
    elif args[:2] == ["simctl", "boot"] and len(args) == 3:
        pass
    elif args[:2] == ["simctl", "bootstatus"] and len(args) == 4 and args[3] == "-b":
        if os.environ.get("FAKE_FAIL") == "bootstatus":
            sys.exit(43)
    else:
        sys.exit(92)
else:
    sys.exit(93)
'''


class CISimulatorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.bin_dir = self.root / "bin"
        self.bin_dir.mkdir()
        for tool in ("xcodebuild", "xcrun"):
            executable = self.bin_dir / tool
            executable.write_text(FAKE_TOOL, encoding="utf-8")
            executable.chmod(0o755)
        self.developer_dir = self.root / "Xcode_26.6.app" / "Contents" / "Developer"
        self.developer_dir.mkdir(parents=True)
        self.github_env = self.root / "github-env"
        self.github_env.write_text("existing=value\n", encoding="utf-8")
        self.env = os.environ.copy()
        for key in tuple(self.env):
            if key.startswith("HONKSHOOL_") or key.startswith("FAKE_"):
                del self.env[key]
        self.env.update(
            PATH=f"{self.bin_dir}{os.pathsep}{self.env.get('PATH', '')}",
            FAKE_STATE_DIR=str(self.root),
            GITHUB_ENV=str(self.github_env),
            HONKSHOOL_XCODE_PATH=str(self.developer_dir),
        )

    def run_setup(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT)], env=self.env,
            capture_output=True, text=True, check=False,
        )

    def commands(self) -> list[dict[str, object]]:
        log = self.root / "commands.jsonl"
        if not log.exists():
            return []
        return [json.loads(line) for line in log.read_text().splitlines()]

    def command_pairs(self) -> list[tuple[str, list[str]]]:
        return [(command["tool"], command["args"]) for command in self.commands()]

    def assert_destination_unpublished(self) -> None:
        self.assertEqual(self.github_env.read_text(), "existing=value\n")

    def test_installed_runtime_boots_created_simulator_and_publishes_id(self) -> None:
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.command_pairs(), [
            ("xcodebuild", ["-version"]),
            ("xcodebuild", ["-runFirstLaunch"]),
            ("xcrun", ["simctl", "list", "runtimes", "--json"]),
            ("xcrun", ["simctl", "create", "Honkshool CI", DEVICE_TYPE, RUNTIME]),
            ("xcrun", ["simctl", "boot", DEVICE_ID]),
            ("xcrun", ["simctl", "bootstatus", DEVICE_ID, "-b"]),
        ])
        self.assertTrue(all(command["developer_dir"] == str(self.developer_dir)
                            for command in self.commands()))
        self.assertEqual(self.github_env.read_text().splitlines(), [
            "existing=value",
            f"HONKSHOOL_XCODE_PATH={self.developer_dir}",
            f"HONKSHOOL_TEST_DESTINATION=platform=iOS Simulator,id={DEVICE_ID}",
        ])

    def test_published_destination_reaches_ios_test_runner(self) -> None:
        setup = self.run_setup()
        self.assertEqual(setup.returncode, 0, setup.stderr)
        runner_env = self.env.copy()
        for line in self.github_env.read_text().splitlines():
            key, value = line.split("=", 1)
            runner_env[key] = value
        runner_env["TMPDIR"] = str(self.root)
        runner_env["GITHUB_OUTPUT"] = str(self.root / "github-output")
        runner = subprocess.run(
            ["sh", str(ROOT / "scripts/test-ios.sh")], env=runner_env,
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(runner.returncode, 0, runner.stderr)
        test_command = self.commands()[-1]
        self.assertEqual(test_command["tool"], "xcodebuild")
        args = test_command["args"]
        self.assertEqual(args[args.index("-destination") + 1],
                         f"platform=iOS Simulator,id={DEVICE_ID}")
        self.assertEqual(test_command["developer_dir"], str(self.developer_dir))
        self.assertTrue((self.root / "github-output").read_text().startswith(
            "result_directory="))

    def test_missing_runtime_downloads_then_rechecks(self) -> None:
        self.env["FAKE_RUNTIME_MODE"] = "missing"
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.command_pairs()[2:5], [
            ("xcrun", ["simctl", "list", "runtimes", "--json"]),
            ("xcodebuild", ["-downloadPlatform", "iOS", "-buildVersion", "26.5"]),
            ("xcrun", ["simctl", "list", "runtimes", "--json"]),
        ])
        self.assertIn(f"id={DEVICE_ID}", self.github_env.read_text())

    def test_unavailable_runtime_downloads_then_rechecks(self) -> None:
        self.env["FAKE_RUNTIME_MODE"] = "unavailable"
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(("xcodebuild", ["-downloadPlatform", "iOS", "-buildVersion", "26.5"]),
                      self.command_pairs())

    def test_failed_download_does_not_publish_destination(self) -> None:
        self.env.update(FAKE_RUNTIME_MODE="missing", FAKE_FAIL="download")
        result = self.run_setup()
        self.assertEqual(result.returncode, 42)
        self.assert_destination_unpublished()
        self.assertFalse(any(args[:2] == ["simctl", "create"]
                             for _, args in self.command_pairs()))

    def test_runtime_still_unavailable_after_download_fails(self) -> None:
        self.env.update(FAKE_RUNTIME_MODE="unavailable",
                        FAKE_UNAVAILABLE_AFTER_DOWNLOAD="1")
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assert_destination_unpublished()
        self.assertFalse(any(args[:2] == ["simctl", "create"]
                             for _, args in self.command_pairs()))

    def test_failed_bootstatus_does_not_publish_destination(self) -> None:
        self.env["FAKE_FAIL"] = "bootstatus"
        result = self.run_setup()
        self.assertEqual(result.returncode, 43)
        self.assert_destination_unpublished()
        self.assertEqual(self.command_pairs()[-1],
                         ("xcrun", ["simctl", "bootstatus", DEVICE_ID, "-b"]))

    def test_malformed_runtime_json_fails_without_download_or_destination(self) -> None:
        self.env["FAKE_BAD_JSON"] = "1"
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assert_destination_unpublished()
        self.assertEqual(self.command_pairs()[-1],
                         ("xcrun", ["simctl", "list", "runtimes", "--json"]))

    def test_invalid_created_id_fails_before_boot_or_publication(self) -> None:
        self.env["FAKE_CREATE_ID"] = "not a device id"
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assert_destination_unpublished()
        self.assertEqual(self.command_pairs()[-1][1][:2], ["simctl", "create"])

    def test_invalid_developer_directory_fails_before_commands(self) -> None:
        self.env["HONKSHOOL_XCODE_PATH"] = str(self.root / "does-not-exist")
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assert_destination_unpublished()
        self.assertEqual(self.commands(), [])

    def test_missing_github_env_fails_before_commands(self) -> None:
        del self.env["GITHUB_ENV"]
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assert_destination_unpublished()
        self.assertEqual(self.commands(), [])


if __name__ == "__main__":
    unittest.main()
