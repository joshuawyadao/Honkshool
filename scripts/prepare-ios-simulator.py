#!/usr/bin/env python3
"""Prepare an isolated simulator for the existing full iOS CI test runner."""

import json
import os
from pathlib import Path
import subprocess
import sys
from uuid import UUID


XCODE_PATH = "/Applications/Xcode_26.6.app/Contents/Developer"
IOS_VERSION = "26.5"
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
DEVICE_TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"


def prepare():
    xcode = os.environ.get("HONKSHOOL_XCODE_PATH", XCODE_PATH)
    output = os.environ.get("GITHUB_ENV")
    if not Path(xcode).is_dir() or any(c in xcode for c in "\r\n"):
        raise ValueError("Select an installed Xcode with HONKSHOOL_XCODE_PATH.")
    if not output:
        raise ValueError("GITHUB_ENV is required for CI simulator preparation.")
    environment = dict(os.environ, DEVELOPER_DIR=xcode)

    def run(*arguments, capture=False):
        print("Preparing iOS CI:", " ".join(arguments), flush=True)
        result = subprocess.run(
            arguments, env=environment, check=True, text=True,
            stdout=subprocess.PIPE if capture else None,
        )
        return result.stdout.strip() if capture else None

    def runtime_available():
        data = json.loads(run("xcrun", "simctl", "list", "runtimes", "--json", capture=True))
        return any(
            item.get("identifier") == RUNTIME and item.get("isAvailable") is True
            for item in data["runtimes"]
        )

    run("xcodebuild", "-version")
    run("xcodebuild", "-runFirstLaunch")
    if not runtime_available():
        run("xcodebuild", "-downloadPlatform", "iOS", "-buildVersion", IOS_VERSION)
        if not runtime_available():
            raise ValueError(f"iOS {IOS_VERSION} runtime is unavailable after installation.")

    # A fresh CI-only device avoids depending on a runner image's device names,
    # boot state, or the ambiguous OS=latest destination selector.
    device = run("xcrun", "simctl", "create", "Honkshool CI", DEVICE_TYPE, RUNTIME, capture=True)
    if str(UUID(device)).upper() != device.upper():
        raise ValueError("Simulator creation did not return a valid device UUID.")
    run("xcrun", "simctl", "boot", device)
    run("xcrun", "simctl", "bootstatus", device, "-b")

    # Publish only after successful boot; a failed preparation must never look
    # like a valid destination to the following xcodebuild test invocation.
    destination = f"platform=iOS Simulator,id={device}"
    with open(output, "a", encoding="utf-8") as stream:
        stream.write(f"HONKSHOOL_XCODE_PATH={xcode}\n")
        stream.write(f"HONKSHOOL_TEST_DESTINATION={destination}\n")
    print(f"Prepared iOS {IOS_VERSION} test destination: {destination}")


def main():
    try:
        prepare()
        return 0
    except subprocess.CalledProcessError as error:
        print(f"ERROR: Simulator preparation command failed (exit {error.returncode}).", file=sys.stderr)
        return error.returncode if error.returncode > 0 else 1
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"ERROR: Simulator preparation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
