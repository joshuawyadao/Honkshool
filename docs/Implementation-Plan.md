# Plan

Repair the failures reported during the first iPhone 14 Pro feasibility run on the existing spike branch. Preserve the owner's passing observations, reproduce callback and presentation failures, add focused regression coverage, and prepare an updated build for device retesting.

## Scope

- In: Stop/callback correctness, Lock Screen pause/resume, visible blocked-start feedback, stable scrolling, current AlarmKit snooze state and timing, cancellation, regression tests, updated device results, and installing the repaired build.
- Out: production playback architecture, new product features, assuming a nine-minute snooze re-ring passed (the owner cancelled it), and publishing personal device/signing data.

## Action items

- [x] Capture failing controller regressions and inspect Apple SDK/documentation for media commands and authoritative snooze timing.
- [x] Invalidate stopped/replaced speech before cancellation and ignore stale callbacks; configure ordinary pause/resume media controls.
- [x] Observe system alarm updates and foreground refresh, render snoozed/alerting/paused states, and preserve cancellation tracking on errors. Add the Live Activity extension required by AlarmKit for visible snooze countdowns and use its authoritative fire date rather than estimating from foreground time.
- [x] Make blocked-start feedback visible and isolate changing diagnostics from the main scrolling layout.
- [x] Test callback races, alarm reconciliation/cancellation, and critical UI behavior; document any device-only reproduction limits.
- [x] Update Feasibility-Spike.md, Project-Implementation-Plan.md, Decision-Log.md, Project-Overview.md, and README.md with user-reported results, fixes, and pending retests.
- [x] Run simulator tests, formatting, repository checks, and a signed device build; install on the connected phone and attempt launch. Installation succeeded; iOS blocked launch because the phone was locked.
- [x] Review and save the scoped changes and task plan to the spike branch using the commit/push workflow.

## Validation and handoff

- Original-code regression run: both Stop/callback and live-stream metadata assertions failed as expected before their repairs.
- Final iOS 26.5 simulator run: 24/24 tests passed (22 unit/controller/service, two UI), with zero skips. Tests live in `HonkshoolTests/SpikeModelsTests.swift` and `HonkshoolUITests/FeasibilityUITests.swift`.
- Repository verification: 10/10 passed. Strict Swift formatting and whitespace checks passed.
- Signed iPhone app and embedded Live Activity build/install succeeded. No alarm was scheduled during installation. Unlock the iPhone and open Honkshool to begin retesting.
- The exact device scrolling symptom, Lock Screen pause/resume, and full nine-minute snooze cycle require the owner's focused retest in [Feasibility-Spike.md](Feasibility-Spike.md). Phase 0 remains open; implementation completion is not a physical-device pass.

## Open questions

- None. Treat unannotated checks from the chat checklist as user-reported passes. Separate automated regression results from the pending physical retest.
