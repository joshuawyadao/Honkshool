# Plan

Implement Honkshool's deterministic nap-planning core on `codex/nap-plan-domain`, based on current main (`45dcc71`, PR #2). Keep approved routes and wake deadlines fixed, preserve partial playback and all prior listening history, and leave the feasibility console intact.

## Scope

- In: Foundation-only content identities and estimates, requests and immutable plans, preselected transitions and shorter alternatives, settling/drift/fallback timing, playback outcomes, resume checkpoints, completion-based progress, tests, and current project documentation.
- Out: product UI, production playback/alarm adapters, persistence, final content/voice/ambience selection, new dependencies, backend services, distribution, and PR creation or merge.

## Action items

- [x] Inspect supplied AGENTS instructions (no repository AGENTS.md exists), README, Product-Brief, Project-Implementation-Plan, Decision-Log, Project-Overview, Swift domain/tests, Xcode configuration, and validation scripts; confirm clean main, fetch origin, fast-forward safely, and create the requested feature branch.
- [x] Record approved D-004 and D-009 with dated resolutions and retained Phase 0 evidence; correct stale pending-review/merge wording in README and durable status docs.
- [x] Add small value types and deterministic planning rules in `Honkshool/Domain`, with injected dates, identities, catalog availability, configurable durations, and immutable route snapshots. Document allocation and preapproved shorter-candidate policy.
- [x] Add explicit playback outcomes and resumable content checkpoints, enforcing the fixed deadline and natural-completion-only advancement with append-only listening history.
- [x] Add focused XCTest coverage for timing edges, short windows and fallbacks, approved boundaries, missing content, early/late outcomes, resume, immutable routes, replay/restart/alternate history, and invalid inputs; register files in the Xcode project.
- [x] Run targeted domain XCTest cases, the complete `./scripts/test-ios.sh` suite on available iPhone 17 Pro / iOS 26.5, `./scripts/verify-repository.sh`, a Foundation-only compilation, and a Release simulator build. Results: 45 focused tests and 103 full-suite tests passed with zero failures/skips, 12 repository checks passed, Foundation-only compilation and Release simulator build passed, and all new Swift files passed strict formatting lint. Xcode 27.0 reported one internal QoS warning during the full suite; no phone installation or physical acceptance was needed. Existing test assertions were retained; the repository roadmap assertion now uses the actual feature branch name.
- [x] Review invariants and update `docs/Nap-Planning-Domain.md`, Product-Brief, README, Project-Overview, and the durable `docs/Project-Implementation-Plan.md` with completed scope and remaining prepared-content/runtime/persistence work.
- [x] Inspect the final diff, stage only task files, commit with a concrete message referencing this plan, and push `codex/nap-plan-domain` using `save-branch`.

## Open questions

- None. The owner approved fixed-deadline overrun handling and short-window fallback. Routine policies remain explicit: reserve settling then drift within the available window; preserve ordered sessions without skipping; choose shorter content only from caller-supplied preapproved alternatives; do not append content after playback starts.
