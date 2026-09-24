# Plan

Connect a confirmed Nap Plan to a production playback run using the bundled prepared audio and the existing fixed-deadline domain. Keep the approved route immutable, retain truthful audio-position checkpoints, and allow alarm-free runs while the separate production AlarmKit/history slice remains pending.

## Scope
- In: a production run coordinator and play/pause/stop UI; approved-start and deadline enforcement; prepared-audio route sequencing; silence after narration; explicit interruption recovery; in-memory completion and partial evidence; audio-position resume support in the domain; focused automated and simulator validation; current-status documentation.
- Out: scheduling production alarms, SwiftData persistence and history UI, accepted rain playback, new content, device-only manual acceptance, and merging the PR. An alarm-requested plan must not start in this slice.

## Action items
- [x] Extend `ResumePoint` and prepared-content validation for revision-bound prepared-audio positions without deriving a script offset from elapsed audio; cover planning, playback, and invalid checkpoints in domain/catalog tests.
- [x] Add a production run coordinator under `Honkshool/Services` that consumes the exact confirmed snapshot, resolves and validates route assets, waits for the approved start, and rejects stale starts or alarm-requested runs before audio begins.
- [x] Drive the approved route through `NapPlayback` using actual player completion, active playback time, explicit pause/resume and stop, silent rest, and a fixed cutoff; require the app to remain foregrounded until narration starts, record late cutoff using the actual stop time and a verified pre-deadline audio checkpoint, and guard stale callbacks and expected interruptions without automatic resume.
- [x] Connect the confirmed review screen to a clear Start resting action and run controls/status, including visible terminal status after leaving the review, and a path to review again after a missed start or alarm gate; keep the feasibility console independent.
- [x] Add coordinator unit tests for start/alarm gates, route and deadline behavior, pause/interruption/stop evidence, stale callbacks, and failure paths; update critical review UI tests for the new action and messaging.
- [x] Run focused tests, the full simulator suite, repository verification, Swift formatting, and an unsigned Release simulator build; inspect the diff for timing and audio ownership risks. Record device-only checks as pending.
- [ ] Update `README.md`, `docs/Project-Implementation-Plan.md`, `docs/Project-Overview.md`, `docs/Nap-Planning-Domain.md`, and `docs/Content-Catalog.md` to describe the implemented boundary, then commit, push, and open a PR for review.

## Open questions
- None. The approved D-021 alarm gate keeps alarm-requested runs unavailable until the production scheduling slice, and prepared audio positions provide truthful partial checkpoints without script-time alignment.

## Verification
- Focused playback and catalog tests passed on iPhone 17 Pro / iOS 26.5 Simulator.
- Full iOS simulator suite: 170 passed, 0 failed, 1 intentionally skipped device-only test.
- Public repository verification: 31 passed. Strict Swift formatting and unsigned Release simulator build passed.
- Apple-platform review found no remaining code blocker in the foreground-start or late-cutoff paths. Locked-screen playback, route changes, and interruption recovery on the target iPhone remain manual acceptance work.

## PR feedback
- [x] Preserve a verified pre-deadline checkpoint when Stop is pressed after a delayed deadline callback.
- [x] Allow a fresh confirmed plan to start after a previous run reached a terminal phase without clearing prior in-memory evidence during review.
- [ ] Keep the UI test review clock valid across calendar time.
