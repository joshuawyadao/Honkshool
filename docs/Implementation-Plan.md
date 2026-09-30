# Plan

Diagnose the existing UI-test timeouts blocking PR #12 and repair demonstrated test or runner reliability defects. Preserve behavioral assertions, capture actionable failure evidence, and complete review and CI before the authorized merge and branch cleanup.

## Scope

- In: feasibility UI tests, simulator test diagnostics and CI evidence, focused reliability fixes, developer verification guidance, PR #12 review and merge.
- Out: new product behavior, audio assets, physical-device acceptance, unrelated worktrees, skipped assertions or automatic retries that conceal failures.

## Action items

- [x] Inspect the two hosted timeout summaries, existing UI fixtures/helpers, CI workflow, and Development guide; confirm the current branch is clean.
- [x] Commit this resolved plan before implementation.
- [x] Reproduce the failing playback test and inspect its transitions; obtain independent Apple-contract diagnosis.
- [x] Preserve assertion call sites and observed UI values in failure messages; retain hosted result evidence if needed to identify the failing transition.
- [ ] Apply only fixes supported by evidence, preserving alarm and playback assertions; cover diagnostic script behavior with portable tests if changed.
- [x] Update docs/Development.md for any new diagnostic controls and artifact handling; verify no private device data enters public source.
- [ ] Run focused simulator checks and the portable gate, review the diff, then commit and push the bounded changes.
- [ ] Request current-head Codex review and observe full hosted CI; resolve addressed threads, merge PR #12 when green, and delete only its feature branch.

## Open questions

- None. The user approved extending PR #12 to diagnose and fix existing UI-test reliability. Root cause is not yet established; no timeout increase is assumed.

## Evidence

- Hosted attempt 2: 233 passed, one delayed-scheduling UI waiter timeout, six expected physical skips. The failing test passed an unchanged three-iteration local simulator reproduction.
- Hosted attempt 3: 233 passed, one alarm-enabled playback UI waiter timeout, six expected physical skips. The prior failing test passed. The summary omits the failed assertion call site and observed state; the workflow does not preserve the result bundle.

- The playback failure also passed an unchanged three-iteration local reproduction. Both hosted failures remain intermittent and their causes are unproven. The bounded correction is diagnostic: preserve expected/observed labels and source locations, with existing 5/15-second waits, and retain failed hosted simulator result bundles for seven days.
- Independent review caught and corrected the artifact root: upload the fresh parent directory so the downloaded archive retains TestResults.xcresult. Three portable regression cases verify successful result publication, failed-test exit preservation, and unreadable-summary exit preservation.

- Diagnostic slice validation: both affected simulator tests passed with the updated helper; all 51 portable tests passed. Brooks diff review found no additional actionable decay or test-quality concern. No production code changed; hosted current-head validation remains required.
