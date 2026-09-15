# Plan

Close the feasibility milestone using completed physical-device evidence, resolve supported decisions, align the durable roadmap, and prepare the existing branch for review. Do not merge or begin Phase 1 implementation.

## Closeout action items

- [x] Record the final larger-text snooze pass and resolve or explicitly defer Phase 0 decisions.
- [x] Align the feasibility guide, roadmap, overview, README, and contribution guidance.
- [x] Verify repository checks and public-safe documentation (12/12 and `git diff --check` pass); prepare for commit and push.
- [x] Open [PR #2](https://github.com/joshuawyadao/Honkshool/pull/2), request Codex review, and perform a sampled Brooks review. Latest-commit review and CI status remain authoritative on the PR.
- [x] Fix the Brooks review finding that UI-test fixtures share real alarm/preferences storage; isolate all three consumers and add a regression. The full simulator suite, Release build, strict formatting, repository checks, and diff check pass.
- [x] Address Codex feedback: cancel tracked alarms before alarm-disabled starts, expose a terminal state after media reset, and reactivate audio on manual resume, including stopped ambience engines. Focused regressions and the complete simulator suite pass; save each item separately.
- Report latest review/CI readiness without merging. Leave nap-planning work for the next targeted branch.
- [ ] Address final-review races: snapshot/lock run options across scheduling and restore the ambience loop even when its engine remains running; validate and save each fix.

## Completed layout-repair context

The preceding task extracted and compacted the snoozed Lock Screen presentation, added a renderer regression, and retained one physical visual check. Its scope and validation are preserved below.

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

- PR follow-up: 46/46 simulator tests (35 unit/controller/service/layout and 11 UI), 12/12 repository checks, strict formatting, and the unsigned Release simulator build pass. The original physical evidence below predates the narrow review fixes; it is not relabeled as a new hardware run.

- Red: the extracted pre-fix snoozed layout measured 216 points at xLarge against the 160-point system ceiling.
- Green: the compact snoozed layout passes at xLarge, xxLarge, xxxLarge, and accessibility1; paused, alerting, and fallback states also pass at accessibility1.
- Complete simulator suite: 39 of 39 tests pass.
- Public-repository checks: 12 of 12 pass.
- Strict Swift formatting, property-list validation, the unsigned Release simulator build, and `git diff --check` pass.
- Follow-up on 2026-09-15: the signed repair was installed and launched on the iPhone 14 Pro, nine deterministic device UI tests passed, and the owner confirmed the snoozed card fits correctly at the existing larger text setting. No further manual check is needed for this documentation-only closeout.
