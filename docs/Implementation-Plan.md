# Plan

Move the completed pre-play Nap Plan review slice from its original content-branch base onto the squash-merged `main` tip. Preserve the reviewed behavior, tests, and documentation while keeping the merged content branch and original review worktree intact.

## Scope

- In: transplant review-only changes from `8a23174de451e5c8f714af9ff71b1b7e7fbf7dc0..codex/nap-plan-review` onto `39bd2a260417419dc436c5a66e99fc31369dc50d`; reconcile documentation with merged content; validate, push, and open a review PR when ready.
- Out: production playback, real alarm scheduling, SwiftData history, rain acceptance, physical-iPhone testing, and merging the PR.

## Action items

- [x] Verify the clean original checkout, the merged `origin/main` tip, the original parent commit, the three review-only commits, and the existing isolated review worktree.
- [x] Checkpoint this transplant plan on `codex/nap-plan-review-main` in its isolated worktree.
- [x] Supersede the old plan commit with this checkpoint, cherry-pick the implementation and transition commits in order, and resolve the README and task-plan conflicts using merged `main` as the content baseline.
- [x] Inspect the transplanted app, domain, tests, README, and canonical docs for stale content-branch assumptions; update `docs/Project-Implementation-Plan.md` and other affected docs to describe the actual review boundary.
- [x] Exclude sessions without a resolvable bundled narration file from selectable content and the review planner's subsequent route; inject availability and add unit/UI regressions for the empty state.
- [x] Verify that the existing focused unit and UI tests still cover timing input, invalid deadlines, short and missing content, fallback sound, transitions, immutable confirmation, and accessibility; change tests only for the availability gap found during review.
- [x] Address PR #5 Codex feedback: show a future planned start, preserve the full chosen duration through confirmation, support short exact wake windows, reject confirmation outside the review-to-start interval or after the deadline, refresh for renewed approval, and add deterministic unit/UI coverage for tight routes and clock rollback.
- [x] Run targeted review tests, the full simulator suite, repository checks, strict Swift formatting, Foundation typecheck, Debug and Release simulator builds, and a diff review. Keep physical-device and real-alarm checks with the owner.
- [x] Push the initial validated branch, open PR #5 against merged `main`, request Codex review, inspect the first passing CI run, and address its actionable finding without merging.

## Open questions

- None. The existing review slice is complete; this task changes its ancestry and reconciles merge-era documentation, with code changes only if validation exposes a defect.

## Results

- Squash-merged content base: `39bd2a260417419dc436c5a66e99fc31369dc50d` from PR #4. Original review parent: `8a23174de451e5c8f714af9ff71b1b7e7fbf7dc0`. The original plan commit was superseded by `f577e5d`; implementation and transition commits became `be391e2` and `8a89a3b` on this branch.
- Review found that catalog entries without a resolvable narration file could be offered for confirmation. The picker and planner now use the same injected availability filter; one unit and one UI regression cover the quiet empty state.
- Focused iOS 26.5 simulator review run: 10 passed, zero failed or skipped. Full iOS 26.5 simulator run: 151 passed, zero failed, one intentionally skipped device-only test. An earlier full run passed 150 tests but lost XCTest's alert snapshot on the final OK tap of an existing feasibility test; that test passed alone and the clean full rerun passed. No product code change was needed for that simulator interaction.
- Repository checks: 31 passed. Strict Swift formatting, Foundation typecheck, diff whitespace check, Debug compilation through tests, and unsigned Release simulator build passed. The physical iPhone and real alarms were not used.
- PR #5 review found that a route approved after its planned start could no longer fit its immutable window. The review now displays a future planned start and deadline with seconds; duration mode keeps its full length, short exact wake windows keep their absolute deadline, and confirmation outside the review-to-start interval prompts another review. The snapshot remains unchanged once confirmed. Final focused iOS 26.5 simulator run: 15 passed; full suite: 156 passed, zero failed, one intentionally skipped device-only test. Repository checks (31), strict format, Foundation typecheck, diff whitespace, and unsigned Release simulator build passed on the final change. The PR's new-head CI run is evaluated after push.
