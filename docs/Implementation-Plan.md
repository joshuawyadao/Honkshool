# Plan

Persist verified Nap Plan playback locally and expose history, Continue, Resume, and Replay through a fresh plan review. Keep the Foundation domain independent of SwiftData, preserve earlier attempts, and recover only the last saved evidence after an unexpected exit.

## Scope
- In: a versioned local SwiftData store; durable partial/completed records and in-flight checkpoints; explicit resume with content-revision validation; completion-only journey progress; history UI; isolated persistence/runtime/UI tests; canonical documentation; a reviewed, passing PR.
- Out: rain playback, new content, full journey branching, automatic playback on relaunch, cloud sync, analytics, changes to alarm ownership, and merging the PR. Physical locked-screen and headphone acceptance remains separately documented.

## Action items
- [x] Inspect the domain, runtime, chooser, fixtures, test configuration, roadmap, decision log, and Apple SwiftData configuration/save documentation; confirm D-002/D-004 and existing resume contracts need no product decision.
- [x] Add a versioned SwiftData adapter with explicit saves, append-only finalized attempts, replaceable verified checkpoints, safe restoration, duplicate protection, and visible load/save failures without erasing existing data.
- [x] Connect runtime completion, partial outcomes, and periodic/pause checkpoints to storage; preserve the fixed deadline and separately owned alarm, and recover uncertain exits as partial evidence without inferring a stop time or completion.
- [x] Add chronological history and Continue/Resume/Replay entry points that validate current prepared content and seed a fresh Nap Plan review; expose completion-based progress without rewriting prior attempts.
- [x] Add persistence reopen/round-trip, checkpoint recovery, idempotency, stale-revision, storage-failure, runtime, and critical history-to-review UI coverage with isolated test stores.
- [ ] Run targeted simulator tests, the full iOS suite, repository verification, strict Swift formatting, project lint, and an unsigned Release build; review timing, storage, and privacy boundaries.
- [x] Update README.md, docs/Nap-Planning-Domain.md, docs/Project-Implementation-Plan.md, docs/Project-Overview.md, and docs/Feasibility-Spike.md with storage, recovery, user flow, and remaining device acceptance.
- [ ] Save coherent local checkpoints, push codex/local-history, open a PR, request Codex review, run Brooks review, and address actionable feedback/CI until merge-ready or a concrete blocker remains.

## Open questions
- None. Relaunch restores saved evidence only; the listener explicitly chooses and approves a new plan before playback. Checkpoints are partial evidence at their captured time, not proof of when a terminated run stopped. Save failures are visible and do not interrupt an active nap or cancel its alarm.

## Review and verification ledger
- Initial state: clean main at merged PR #7 (5af6bd4); created codex/local-history from current origin/main.
- Physical production locked-screen alarm, route/interruption, and long-form subjective acceptance remain pending; simulator results will not be reported as physical evidence.

- Focused simulator suite: 53 passed, no failures on iPhone 17e / iOS 26.5; added a final storage-failure runtime regression for the full run. New history UI suite passed. Repository checks: 31 passed. Strict formatting and project lint passed.
- Correctness review: no blocker; corrected Continue wording to describe resuming the current session. Additional checks bind saved audio positions to the prepared render fingerprint and distinguish unavailable history/content from completed journeys.
