# Plan

Prepare PR #4 for merge by closing the reviewed fixed-deadline edge case in the prepared-audio controller, then validate the branch and complete the PR review cycle. Keep the feasibility console's existing scope and the accepted local audio assets.

## Scope

- In: deadline checks across player setup, start, natural completion, and resume; accurate Now Playing elapsed time on pause; alarm guidance on catalog failure; focused regression tests; canonical docs; branch save and PR readiness.
- Out: production Nap Plan playback/history integration, new audio assets, subjective listening acceptance, and merging the PR.

## Action items

- [x] Inspect the controller's deadline lifecycle, the affected XCTest fixtures, and the existing feasibility documentation.
- [x] Inject a clock into the controller and prevent prepared audio from starting or resuming after its fixed wake deadline, including when setup takes time or the scheduled callback is delayed.
- [x] Add focused tests for setup latency, an expired deadline before play, a delayed cutoff during pause/resume, and natural completion after wake.
- [x] Update Now Playing elapsed time on prepared-audio pause and interruption, and tell the user when a pre-scheduled alarm survives catalog loading failure; cover both behaviors.
- [x] Correct README's console integration status.
- [x] Update `docs/Feasibility-Spike.md` to describe the controller guard, its scheduling limits, and the iOS 27 diagnostics cleanup stall.
- [x] Run focused and full simulator tests, repository checks, Swift formatting, and a Release build; inspect the PR diff for other actionable concerns.
- [ ] Commit and push the fix, address actionable Codex/CI feedback, and mark PR #4 ready only when review and checks pass.

## Open questions

- None.

## Validation

- Focused iOS 27 simulator run: 29 passed, zero failed. The earlier direct invocation stalled inside Xcode's optional simulator-diagnostics cleanup; the clean retry with diagnostics disabled passed.
- Full iOS 27 simulator suite: 141 passed, zero failed, one intentionally skipped real-device test.
- Repository verification: 31 passed. Strict Swift formatting, unsigned Release simulator build, and diff whitespace check passed.
- Read-only Apple-platform and Brooks review found the fixed-deadline edge case; Codex review also found stale pause metadata, missing active-alarm guidance, and outdated README status. All four have implementation fixes; GitHub CI and final review readiness remain pending.
