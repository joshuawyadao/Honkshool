#!/usr/bin/env python3
"""Provision and remove one CI-owned iOS simulator for the complete test suite."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys


DEVICE_NAME = "iPhone 17 Pro"
UUID = re.compile(r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\Z")


def command(*args: str) -> str:
    timeout = 900 if args[:2] == ("xcodebuild", "-downloadPlatform") else {
        "list": 30,
        "create": 60,
        "boot": 90,
        "bootstatus": 300,
        "delete": 60,
    }.get(args[2], 30)
    try:
        result = subprocess.run(args, check=False, text=True, capture_output=True, timeout=timeout)
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(f"{' '.join(args)} timed out after {timeout} seconds") from error
    if result.returncode:
        detail = result.stderr.strip() or result.stdout.strip() or f"exit {result.returncode}"
        raise RuntimeError(f"{' '.join(args)}: {detail}")
    return result.stdout.strip()


def simctl_json(kind: str) -> list[dict]:
    data = json.loads(command("xcrun", "simctl", "list", "-j", kind))
    return data[kind]


def current_runtime() -> dict | None:
    candidates = [
        runtime for runtime in simctl_json("runtimes")
        if runtime.get("isAvailable") is True
        and runtime.get("identifier", "").startswith("com.apple.CoreSimulator.SimRuntime.iOS-")
        and re.fullmatch(r"\d+(?:\.\d+)*", runtime.get("version", ""))
        and tuple(map(int, runtime["version"].split("."))) >= (26, 0)
    ]
    return max(candidates, key=lambda runtime: tuple(map(int, runtime["version"].split("."))), default=None)


def prepare() -> None:
    runtime = current_runtime()
    if runtime is None:
        print("No compatible installed iOS simulator runtime; downloading Xcode's iOS platform.", flush=True)
        command("xcodebuild", "-downloadPlatform", "iOS")
        runtime = current_runtime()
    if runtime is None:
        raise RuntimeError("No available iOS 26-or-newer simulator runtime after platform download")

    device_type = next((item for item in simctl_json("devicetypes") if item.get("name") == DEVICE_NAME), None)
    if device_type is None:
        raise RuntimeError(f"Simulator device type unavailable: {DEVICE_NAME}")

    identifier = command("xcrun", "simctl", "create", "Honkshool CI", device_type["identifier"], runtime["identifier"])
    if not UUID.fullmatch(identifier):
        raise RuntimeError(f"simctl create returned an invalid simulator identifier: {identifier!r}")

    # Publish before boot, so the always() cleanup can remove a failed boot.
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        output.write(f"simulator_id={identifier}\n")
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as environment:
        environment.write(f"HONKSHOOL_TEST_DESTINATION=platform=iOS Simulator,id={identifier}\n")

    command("xcrun", "simctl", "boot", identifier)
    command("xcrun", "simctl", "bootstatus", identifier, "-b")
    print(f"Booted CI-owned {DEVICE_NAME} on iOS {runtime['version']}: {identifier}")


def cleanup(identifier: str) -> None:
    if not UUID.fullmatch(identifier):
        raise RuntimeError("Refusing to clean up an invalid simulator identifier")
    try:
        subprocess.run(("xcrun", "simctl", "shutdown", identifier), check=False,
                       capture_output=True, timeout=30)
    except subprocess.TimeoutExpired:
        print(f"Simulator shutdown timed out; deleting {identifier} directly.", file=sys.stderr)
    command("xcrun", "simctl", "delete", identifier)
    print(f"Removed CI-owned simulator {identifier}")


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["prepare"]:
            prepare()
        elif len(sys.argv) == 3 and sys.argv[1] == "cleanup":
            cleanup(sys.argv[2])
        else:
            raise RuntimeError("usage: ci-simulator.py prepare | cleanup <created-simulator-uuid>")
    except (KeyError, ValueError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"CI simulator provisioning failed: {error}", file=sys.stderr)
        sys.exit(1)
