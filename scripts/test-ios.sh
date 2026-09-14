#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

HONKSHOOL_XCODE_PATH=${HONKSHOOL_XCODE_PATH:-/Applications/Xcode.app/Contents/Developer}
HONKSHOOL_TEST_DESTINATION=${HONKSHOOL_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=latest}
HONKSHOOL_TEST_DERIVED_DATA=${HONKSHOOL_TEST_DERIVED_DATA:-/tmp/HonkshoolAutomatedTests}

if [ ! -d "$HONKSHOOL_XCODE_PATH" ]; then
  printf 'ERROR: Xcode developer directory not found: %s\n' "$HONKSHOOL_XCODE_PATH" >&2
  printf 'Set HONKSHOOL_XCODE_PATH to the active Xcode Developer directory.\n' >&2
  exit 1
fi

cd "$PROJECT_ROOT"

DEVELOPER_DIR="$HONKSHOOL_XCODE_PATH" xcodebuild -quiet \
  -project Honkshool.xcodeproj \
  -scheme Honkshool \
  -destination "$HONKSHOOL_TEST_DESTINATION" \
  -derivedDataPath "$HONKSHOOL_TEST_DERIVED_DATA" \
  -parallel-testing-enabled NO \
  test

printf 'PASS: Honkshool iOS automated tests completed successfully.\n'
