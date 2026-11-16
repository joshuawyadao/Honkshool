#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

HONKSHOOL_XCODE_PATH=${HONKSHOOL_XCODE_PATH:-/Applications/Xcode.app/Contents/Developer}
HONKSHOOL_TEST_DESTINATION=${HONKSHOOL_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=latest}
HONKSHOOL_TEST_DERIVED_DATA=${HONKSHOOL_TEST_DERIVED_DATA:-/tmp/HonkshoolAutomatedTests}
HONKSHOOL_TEST_DIAGNOSTICS=${HONKSHOOL_TEST_DIAGNOSTICS:-never}
HONKSHOOL_TEST_SCOPE=${HONKSHOOL_TEST_SCOPE:-all}
HONKSHOOL_UI_SHARD=${HONKSHOOL_UI_SHARD:-all}

case "$HONKSHOOL_TEST_SCOPE" in
  all|unit|ui) ;;
  *)
    printf 'ERROR: HONKSHOOL_TEST_SCOPE must be all, unit, or ui.\n' >&2
    exit 2
    ;;
esac
case "$HONKSHOOL_UI_SHARD" in
  all|plan-review|other) ;;
  *)
    printf 'ERROR: HONKSHOOL_UI_SHARD must be all, plan-review, or other.\n' >&2
    exit 2
    ;;
esac
if [ "$HONKSHOOL_TEST_SCOPE" != ui ] && [ "$HONKSHOOL_UI_SHARD" != all ]; then
  printf 'ERROR: HONKSHOOL_UI_SHARD requires HONKSHOOL_TEST_SCOPE=ui.\n' >&2
  exit 2
fi

if [ ! -d "$HONKSHOOL_XCODE_PATH" ]; then
  printf 'ERROR: Xcode developer directory not found: %s\n' "$HONKSHOOL_XCODE_PATH" >&2
  printf 'Set HONKSHOOL_XCODE_PATH to the active Xcode Developer directory.\n' >&2
  exit 1
fi

cd "$PROJECT_ROOT"

test_result_directory=$(mktemp -d "${TMPDIR:-/tmp}/honkshool-test-results.XXXXXX")
test_result_path="$test_result_directory/TestResults.xcresult"
printf 'Test results: %s\n' "$test_result_path"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  printf 'result_directory=%s\n' "$test_result_directory" >> "$GITHUB_OUTPUT"
fi

set -- -quiet \
  -project Honkshool.xcodeproj \
  -scheme Honkshool \
  -destination "$HONKSHOOL_TEST_DESTINATION" \
  -derivedDataPath "$HONKSHOOL_TEST_DERIVED_DATA" \
  -resultBundlePath "$test_result_path" \
  -collect-test-diagnostics "$HONKSHOOL_TEST_DIAGNOSTICS" \
  -parallel-testing-enabled NO
if [ "$HONKSHOOL_TEST_SCOPE" = unit ]; then
  set -- "$@" -only-testing:HonkshoolTests
elif [ "$HONKSHOOL_TEST_SCOPE" = ui ]; then
  if [ "$HONKSHOOL_UI_SHARD" = plan-review ]; then
    set -- "$@" -only-testing:HonkshoolUITests/NapPlanReviewUITests
  else
    set -- "$@" -only-testing:HonkshoolUITests
    if [ "$HONKSHOOL_UI_SHARD" = other ]; then
      set -- "$@" -skip-testing:HonkshoolUITests/NapPlanReviewUITests
    fi
  fi
fi

if DEVELOPER_DIR="$HONKSHOOL_XCODE_PATH" xcodebuild "$@" test; then
  printf 'PASS: Honkshool iOS automated tests completed successfully.\n'
else
  test_exit_code=$?
  if [ -d "$test_result_path" ]; then
    DEVELOPER_DIR="$HONKSHOOL_XCODE_PATH" xcrun xcresulttool get test-results summary \
      --path "$test_result_path" | python3 -c '
import json
import sys
result = json.load(sys.stdin)
print("Test summary: {} passed, {} failed, {} skipped".format(
    result.get("passedTests"), result.get("failedTests"), result.get("skippedTests")))
for failure in result.get("testFailures", []):
    print("{}: {}".format(failure.get("testName", "Test"), failure.get("failureText", "")))
' || true
  fi
  exit "$test_exit_code"
fi
