#!/usr/bin/env python3
"""Conservative policy for selecting iOS CI and checking the final job state."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys


ROOT_MARKDOWN = frozenset({
    "README.md", "CONTRIBUTING.md", "CODE_OF_CONDUCT.md", "SECURITY.md",
})
SHA = re.compile(r"(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})\Z")
RAW_HEADER = re.compile(rb":([0-7]{6}) ([0-7]{6}) [0-9a-f]+ [0-9a-f]+ ([AMD])\Z")


class PolicyError(Exception):
    """A change cannot be classified safely."""


def git(root: Path, *arguments: str) -> bytes:
    result = subprocess.run(
        ["git", *arguments], cwd=root, capture_output=True, check=False,
    )
    if result.returncode:
        raise PolicyError(result.stderr.decode("utf-8", "replace").strip() or "git failed")
    return result.stdout


def changed_entries(root: Path, base: str, head: str) -> list[tuple[str, str, str]]:
    for name, revision in (("base", base), ("head", head)):
        if not SHA.fullmatch(revision):
            raise PolicyError(f"invalid {name} commit SHA")
        resolved = git(root, "rev-parse", "--verify", f"{revision}^{{commit}}").strip()
        if resolved.lower() != revision.lower().encode("ascii"):
            raise PolicyError(f"unresolved {name} commit SHA")

    raw = git(root, "diff", "--raw", "-z", "--no-renames", "--no-ext-diff",
              "--no-textconv", base, head, "--")
    if not raw:
        raise PolicyError("empty commit diff")
    parts = raw.split(b"\0")
    if parts[-1] != b"" or len(parts[:-1]) % 2:
        raise PolicyError("malformed git diff")
    entries = []
    for header, path in zip(parts[0:-1:2], parts[1:-1:2]):
        match = RAW_HEADER.fullmatch(header)
        if match is None or not path or path.startswith(b"/"):
            raise PolicyError("malformed git diff entry")
        old_mode, new_mode, status = (item.decode("ascii") for item in match.groups())
        entries.append((os.fsdecode(path), old_mode, new_mode))
    return entries


def is_document(path: str) -> bool:
    if path in ROOT_MARKDOWN:
        return True
    pieces = path.split("/")
    return (len(pieces) >= 2 and pieces[0] == "docs"
            and all(piece not in ("", ".", "..") for piece in pieces[1:])
            and pieces[-1].endswith((".md", ".svg")))


def needs_ios(root: Path, base: str, head: str) -> bool:
    for path, old_mode, new_mode in changed_entries(root, base, head):
        if not is_document(path):
            return True
        # The absent side of an add or deletion is 000000. Executables and
        # symlinks can change CI behavior even when their names look like docs.
        if any(mode not in ("000000", "100644") for mode in (old_mode, new_mode)):
            return True
    return False


def gate(verify: str, ios: str, run_ios: str) -> bool:
    if verify != "success" or run_ios not in ("true", "false"):
        return False
    return ios == ("success" if run_ios == "true" else "skipped")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    classify = subparsers.add_parser("classify")
    classify.add_argument("--event", required=True, choices=("pull_request", "workflow_dispatch"))
    classify.add_argument("--base", default="")
    classify.add_argument("--head", default="")
    check = subparsers.add_parser("gate")
    check.add_argument("--verify", required=True)
    check.add_argument("--ios", required=True)
    check.add_argument("--run-ios", required=True)
    args = parser.parse_args()

    if args.command == "gate":
        if gate(args.verify, args.ios, args.run_ios):
            print("CI Verify passed")
            return 0
        print("CI Verify failed: inconsistent or unsuccessful job state", file=sys.stderr)
        return 1

    try:
        selected = (True if args.event == "workflow_dispatch" else
                    needs_ios(Path.cwd(), args.base, args.head))
        value = "true" if selected else "false"
        print(f"run_ios={value}")
        if os.environ.get("GITHUB_OUTPUT"):
            with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
                output.write(f"run_ios={value}\n")
        return 0
    except (PolicyError, OSError) as error:
        print(f"CI classification failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
