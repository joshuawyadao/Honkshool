"""CI simulator provisioning preserves full tests and removes only its own device."""

import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/ci-simulator.py"
spec = importlib.util.spec_from_file_location("ci_simulator", SCRIPT)
simulator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(simulator)
IDENTIFIER = "01234567-89AB-CDEF-0123-456789ABCDEF"


class CISimulatorTests(unittest.TestCase):
    def test_prepares_latest_compatible_runtime_and_publishes_owned_destination(self):
        runtimes = [
            {"identifier": "com.apple.CoreSimulator.SimRuntime.iOS-25-5", "version": "25.5", "isAvailable": True},
            {"identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-5", "version": "26.5", "isAvailable": True},
            {"identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-6", "version": "26.6", "isAvailable": False},
        ]
        types = [{"name": "iPhone 17 Pro", "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"}]
        calls = []

        def fake_command(*args):
            calls.append(args)
            return IDENTIFIER if args[2] == "create" else ""

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "output"
            environment = Path(directory) / "environment"
            with patch.dict(os.environ, GITHUB_OUTPUT=str(output), GITHUB_ENV=str(environment)), \
                 patch.object(simulator, "simctl_json", side_effect=lambda kind: runtimes if kind == "runtimes" else types), \
                 patch.object(simulator, "command", side_effect=fake_command):
                simulator.prepare()
            self.assertEqual(output.read_text(), f"simulator_id={IDENTIFIER}\n")
            self.assertEqual(environment.read_text(),
                             f"HONKSHOOL_TEST_DESTINATION=platform=iOS Simulator,id={IDENTIFIER}\n")
        self.assertEqual(calls, [
            ("xcrun", "simctl", "create", "Honkshool CI", types[0]["identifier"], runtimes[1]["identifier"]),
            ("xcrun", "simctl", "boot", IDENTIFIER),
            ("xcrun", "simctl", "bootstatus", IDENTIFIER, "-b"),
        ])

    def test_downloads_only_when_runtime_missing_and_fails_closed_if_still_missing(self):
        with patch.object(simulator, "simctl_json", return_value=[]), \
             patch.object(simulator, "command") as command:
            with self.assertRaisesRegex(RuntimeError, "No available iOS 26-or-newer"):
                simulator.prepare()
        command.assert_called_once_with("xcodebuild", "-downloadPlatform", "iOS")

    def test_failed_boot_still_publishes_identifier_for_always_cleanup(self):
        runtime = {"identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-5",
                   "version": "26.5", "isAvailable": True}
        device_type = {"name": "iPhone 17 Pro", "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"}

        def fake_command(*args):
            if args[2] == "create":
                return IDENTIFIER
            if args[2] == "boot":
                raise RuntimeError("boot failed")
            return ""

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "output"
            environment = Path(directory) / "environment"
            with patch.dict(os.environ, GITHUB_OUTPUT=str(output), GITHUB_ENV=str(environment)), \
                 patch.object(simulator, "simctl_json", side_effect=lambda kind: [runtime] if kind == "runtimes" else [device_type]), \
                 patch.object(simulator, "command", side_effect=fake_command):
                with self.assertRaisesRegex(RuntimeError, "boot failed"):
                    simulator.prepare()
            self.assertEqual(output.read_text(), f"simulator_id={IDENTIFIER}\n")
            self.assertIn(f"id={IDENTIFIER}", environment.read_text())

    def test_cleanup_rejects_unowned_identifier_before_simctl(self):
        with patch.object(simulator.subprocess, "run") as run, \
             patch.object(simulator, "command") as command:
            with self.assertRaisesRegex(RuntimeError, "invalid simulator identifier"):
                simulator.cleanup("all")
        run.assert_not_called()
        command.assert_not_called()

    def test_cleanup_deletes_only_published_identifier_even_if_shutdown_fails(self):
        with patch.object(simulator.subprocess, "run") as run, \
             patch.object(simulator, "command") as command:
            simulator.cleanup(IDENTIFIER)
        run.assert_called_once_with(("xcrun", "simctl", "shutdown", IDENTIFIER),
                                    check=False, capture_output=True, timeout=30)
        command.assert_called_once_with("xcrun", "simctl", "delete", IDENTIFIER)

    def test_command_timeout_is_finite_and_reported(self):
        arguments = ("xcrun", "simctl", "bootstatus", IDENTIFIER, "-b")
        with patch.object(simulator.subprocess, "run",
                          side_effect=subprocess.TimeoutExpired(arguments, 300)) as run:
            with self.assertRaisesRegex(RuntimeError, "bootstatus.*timed out after 300 seconds"):
                simulator.command(*arguments)
        run.assert_called_once_with(arguments, check=False, text=True,
                                    capture_output=True, timeout=300)

    def test_shutdown_timeout_still_attempts_owned_deletion(self):
        with patch.object(simulator.subprocess, "run",
                          side_effect=subprocess.TimeoutExpired("shutdown", 30)), \
             patch.object(simulator, "command") as command:
            simulator.cleanup(IDENTIFIER)
        command.assert_called_once_with("xcrun", "simctl", "delete", IDENTIFIER)


if __name__ == "__main__":
    unittest.main()
