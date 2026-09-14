# Plan

Fix the snoozed AlarmKit Live Activity so its cancellation control remains inside the 160-point Lock Screen presentation at the owner’s larger text setting. Extract the Lock Screen layout into a renderable seam, reproduce the overflow with an image-renderer regression test, compact the layout without capping Dynamic Type, and retain one real-device confirmation for Apple’s system-hosted surface.

## Scope

- In: Snoozed Lock Screen Live Activity layout, larger Dynamic Type rendering, cancellation-control accessibility, a focused layout regression test, physical-test evidence documentation, and installation of the repaired build for confirmation.
- Out: Changing the nine-minute snooze behavior, reducing the owner’s text size, changing alarm reliability logic, redesigning the in-app feasibility console, or claiming that a rendered test fully substitutes for Apple’s Lock Screen host.

## Action items

- [x] Extract the Lock Screen presentation from `HonkshoolAlarmWidget.swift` into a reusable SwiftUI layout that preserves the current overflowing structure before repair.
- [x] Add an `ImageRenderer` XCTest at the iPhone 14 Pro’s 371-point content width, Apple’s 160-point Live Activity height limit, and larger Dynamic Type; confirm it fails on the captured snoozed layout at 216 points.
- [x] Move the cancellation action into a compact header/body composition, use the 14-point Lock Screen horizontal margin, retain an accessible “Cancel alarm” label, and avoid capping Dynamic Type.
- [x] Verify countdown, paused, alerting, and fallback states still fit the Lock Screen ceiling and that the unchanged Dynamic Island presentations compile.
- [x] Update `Feasibility-Spike.md`, `Project-Implementation-Plan.md`, `Project-Overview.md`, and the decision evidence to record the functional physical-device passes and isolate the remaining visual confirmation.
- [x] Run the focused red/green regression, complete iOS suite, public-repository checks, strict Swift formatting, Release build, and `git diff --check`.
- [x] Check for a connected iPhone; none is currently available, so leave only installation and a 60-second alarm/snooze Lock Screen visual confirmation for the owner.
- [x] Review and prepare the scoped fix for commit and push on the current feasibility branch.

## Open questions

- None. Preserve the user’s larger text setting and treat the screenshot as the authoritative system-hosted reproduction.

## Validation

- Red: the extracted pre-fix snoozed layout measured 216 points at xLarge against the 160-point system ceiling.
- Green: the compact snoozed layout passes at xLarge, xxLarge, xxxLarge, and accessibility1; paused, alerting, and fallback states also pass at accessibility1.
- Complete simulator suite: 39 of 39 tests pass.
- Public-repository checks: 12 of 12 pass.
- Strict Swift formatting, property-list validation, the unsigned Release simulator build, and `git diff --check` pass.
- No physical iPhone was connected for installation; Apple’s system-hosted snooze card still requires one visual confirmation after installation.
