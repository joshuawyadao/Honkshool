# Plan

Prepare PR #4 for merge by closing the reviewed fixed-deadline edge case in the prepared-audio controller, then validate the branch and complete the PR review cycle. Keep the feasibility console's existing scope and the accepted local audio assets.

## Scope

- In: deadline checks across player setup, start, natural completion, and resume; focused regression tests; the canonical feasibility note; branch save and PR readiness.
- Out: production Nap Plan playback/history integration, new audio assets, subjective listening acceptance, and merging the PR.

## Action items

- [ ] Inspect the controller's deadline lifecycle, the affected XCTest fixtures, and the existing feasibility documentation.
- [ ] Inject a clock into the controller and prevent prepared audio from starting or resuming after its fixed wake deadline, including when setup takes time or the scheduled callback is delayed.
- [ ] Add focused tests for setup latency, an expired deadline before play, a delayed cutoff during pause/resume, and natural completion after wake.
- [ ] Update `docs/Feasibility-Spike.md` to describe the controller guard and its scheduling limits.
- [ ] Run focused and full simulator tests, repository checks, Swift formatting, and a Release build; inspect the PR diff for other actionable concerns.
- [ ] Commit and push the fix, address actionable Codex/CI feedback, and mark PR #4 ready only when review and checks pass.

## Open questions

- None.
