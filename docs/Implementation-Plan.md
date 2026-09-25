# Plan

Connect alarm-requested confirmed Nap Plans to production AlarmKit while preserving the fixed approved deadline and D-021 start gate. Give production alarms their own recoverable identity and explicit controls, then validate the complete schedule-before-play sequence with deterministic tests and the strongest available device checks.

## Scope
- In: one Honkshool-owned production wake alarm per active plan; authorization, scheduling and system verification before playback; persisted alarm identity and relaunch reconciliation; explicit cancellation; truthful playback and alarm status; focused tests and current-state documentation.
- Out: SwiftData history/resume UI, rain acceptance, new content, changes to the feasibility spike alarm's stored identity, and merging the PR.

## Action items
- [x] Add a production Nap Plan alarm service around the existing `AlarmSystem` adapter with separate storage and metadata, exact plan/deadline binding, system-state reconciliation, and explicit cancellation; retain identity after uncertain schedule or cancellation failures.
- [x] Preflight the immutable confirmed route and approved start before scheduling, then require verified alarm evidence for that exact plan and deadline when `NapRunController` begins; reject stale, denied, failed, mismatched, or already-tracked starts without audio.
- [x] Connect the confirmed review and parent screen to asynchronous scheduling, in-progress and failure feedback, active alarm status, and a reachable cancel action; keep Stop, interruption, and audio failure semantics consistent with D-002.
- [x] Add unit tests for authorization, successful fixed-deadline scheduling, verification failure, uncertain outcomes, relaunch, cancellation, stale starts, alarm-free regression, and Stop retaining the alarm; update critical UI tests using isolated alarm fixtures.
- [x] Run focused iOS tests, the full simulator suite, repository verification, Swift formatting, and a Release simulator build; inspect timing and alarm ownership edges and record physical-device checks that require the owner's iPhone.
- [x] Update `README.md`, `docs/Nap-Planning-Domain.md`, `docs/Project-Implementation-Plan.md`, `docs/Project-Overview.md`, and the physical-device guide to describe the production boundary and remaining acceptance work.
- [ ] Give the hosted iOS suite enough time to finish: the first PR run was still launching simulator tests when the 20-minute job limit cancelled it. Increase the CI limit, then verify the replacement run reaches a terminal passing result.
- [ ] Commit the implementation in reviewable checkpoints, push `codex/nap-plan-alarmkit`, open the PR, request Codex review, run Brooks review, and shepherd CI and feedback until merge-ready or a concrete blocker remains.

## Open questions
- None. D-002, D-003, D-004, and D-021 establish the deadline, alarm ownership, Stop behavior, and authorization gate. A previous production alarm must be explicitly cancelled before starting another plan.

## Verification
- Focused simulator integration: 29 passed, 0 failed on iPhone 17e / iOS 26.5 on an intermediate snapshot. The complete suite below validates the final simulator code. The final device-test cleanup edit passed a signed physical-device build.
- Opt-in iPhone 18 Pro Max / iOS 27.0 production alarm and audio-cutoff test: 1 passed, 0 failed or skipped. It verified real alerting within five seconds and production audio cutoff within three seconds of the fixed deadline. Locked-screen interaction remains manual acceptance work.
- Repository verification: 31 passed. Strict Swift formatting, Xcode project lint, and unsigned Release simulator build passed.
- Complete iPhone 17e / iOS 26.5 simulator suite: 186 passed, 0 failed, 2 intentionally skipped physical-device tests. PR CI rerun remains in progress; Codex and Brooks review are complete.
- PR #7 review: Codex and Brooks found no actionable issues. The first hosted iOS run was cancelled by the 20-minute job timeout while `xcodebuild` continued launching simulator tests; Repository Verify passed.
