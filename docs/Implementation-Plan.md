# Plan

Reduce the Honkshool feasibility spike's manual test burden by making simulator UI tests deterministic, expanding service and controller regression coverage, and running the complete iOS suite locally and in pull-request CI. Preserve a short physical-device checklist only for behaviors that depend on real iOS system UI, background execution, audio hardware, or alarm delivery.

## Scope

- In: Debug-only UI-test launch fixtures, alarm and playback UI flows, controller interruption coverage, alarm-state/error coverage, a single simulator test command, macOS GitHub Actions execution, public-repository safeguards, and updated feasibility documentation.
- Out: Automating private iOS system UI, claiming simulator substitutes prove physical alarm reliability, production feature work, and changing the nine-minute product snooze interval.

## Action items

- [x] Record the current 24-test baseline and identify each manual check that can be represented by deterministic controller, service, or UI state.
- [x] Add debug-only app launch fixtures for authorized, denied, scheduling-failed, snoozed, paused, alerting, and unavailable AlarmKit states plus deterministic speech.
- [x] Expand UI tests for blocked explanations, successful and failed scheduling, Stop, pause/resume, active-alarm scrolling, snooze presentation/cancellation, other alarm states, and saved duration behavior.
- [x] Expand controller and alarm-service tests for interruptions, inactive-event safety, authorization transitions, repeated snooze deadlines, schedule failure, and cancellation/relaunch boundaries.
- [x] Add a portable `scripts/test-ios.sh` entry point that defaults to the CI-compatible latest iPhone 17 Pro simulator, supports a destination override, and runs the full test scheme without signing.
- [x] Add a read-only macOS 26 pull-request CI job for the complete iOS suite and extend publication tests to protect the fixture, script, and workflow contract.
- [x] Update README.md, CONTRIBUTING.md, the pull-request template, Feasibility-Spike.md, Project-Implementation-Plan.md, and Project-Overview.md with the automated/manual boundary and minimal combined device checklist.
- [x] Run targeted tests, the complete iOS suite, strict Swift formatting, repository verification, Debug test builds, a Release build, and workflow syntax checks; document anything only a physical phone can establish.
- [x] Review and prepare the scoped test-automation changes for commit and push on the current spike branch.

## Open questions

- None. Keep test substitutes debug-only and describe their evidence limits explicitly.

## Validation

- Pre-change baseline: 24 simulator tests passed.
- Final simulator suite: 37 of 37 passed, comprising 28 unit/controller/service tests and 9 deterministic UI tests.
- The same nine deterministic UI tests passed on the connected iPhone 14 Pro running iOS 26.6.2 without requesting permission or creating a real alarm.
- Public-repository verification: 11 of 11 tests passed.
- Strict Swift formatting, property-list validation, workflow syntax parsing, `git diff --check`, build-for-testing, and the unsigned Release simulator build passed.
- Two combined physical-device checks remain because private Lock Screen/system alarm UI, background execution, hardware audio routing, and real alarm delivery cannot be established by simulator substitutes.
