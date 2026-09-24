# Plan

Move the completed pre-play Nap Plan review slice from its original content-branch base onto the squash-merged `main` tip. Preserve the reviewed behavior, tests, and documentation while keeping the merged content branch and original review worktree intact.

## Scope

- In: transplant review-only changes from `8a23174de451e5c8f714af9ff71b1b7e7fbf7dc0..codex/nap-plan-review` onto `39bd2a260417419dc436c5a66e99fc31369dc50d`; reconcile documentation with merged content; validate, push, and open a review PR when ready.
- Out: production playback, real alarm scheduling, SwiftData history, rain acceptance, physical-iPhone testing, and merging the PR.

## Action items

- [x] Verify the clean original checkout, the merged `origin/main` tip, the original parent commit, the three review-only commits, and the existing isolated review worktree.
- [x] Checkpoint this transplant plan on `codex/nap-plan-review-main` in its isolated worktree.
- [ ] Cherry-pick the review-only plan, implementation, and transition commits in order; resolve any conflicts using merged `main` as the content baseline and retain the current task plan.
- [ ] Inspect the transplanted app, domain, tests, README, and canonical docs for stale content-branch assumptions; update `docs/Project-Implementation-Plan.md` and other affected docs to describe the actual review boundary.
- [ ] Verify that the existing focused unit and UI tests still cover timing input, invalid deadlines, short and missing content, fallback sound, transitions, immutable confirmation, and accessibility; change tests only if the transplant changes executable behavior.
- [ ] Run targeted review tests, the full simulator suite, repository checks, strict Swift formatting, Foundation typecheck, Debug and Release simulator builds, and a diff review. Keep physical-device and real-alarm checks with the owner.
- [ ] Push the validated branch, then open the PR and complete the review and CI cycle without merging it.

## Open questions

- None. The existing review slice is complete; this task changes its ancestry and reconciles merge-era documentation, with code changes only if validation exposes a defect.
