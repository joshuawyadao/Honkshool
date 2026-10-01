# Plan

Prepare PR #14 for merge by integrating the latest main branch, preserving the approved Quiet curiosity interface and the project-checkup fixes, and addressing actionable review or CI feedback. Keep the app's audio, alarm, history, and accessibility contracts intact.

## Scope
- In: merge conflicts with main; current public guides and diagrams; confirmed Brooks/Codex feedback; narrow CI fixes; relevant tests; review and check evidence; commits and push on codex/app-icon.
- Out: new product capabilities, unrelated refactors, changing physical acceptance claims, publishing private audit artifacts, and merging the PR.

## Action items
- [x] Inspect the main-branch checkup and documentation PR, current design/screen/accessibility guidance, affected UI fixtures, and hosted checks.
- [x] Checkpoint this resolved plan before implementation.
- [x] Merge main, preserving repaired Lab duration persistence and failure diagnostics alongside shared Rest navigation and fixtures.
- [x] Reconcile README, CONTRIBUTING, current user/developer/architecture guides and diagrams with the approved functional pages while retaining setup, privacy, and historical evidence.
- [x] Run repository checks, formatting, and focused restored-duration/navigation regressions; preserve existing assertions and adapt tests only where the UI contract changed.
- [ ] Finish Brooks and Apple-contract review, classify Codex findings, and fix each actionable cluster with focused validation and saved commits.
- [ ] Push and wait for current-head Repository Verify and iOS Unit and UI Tests; investigate failures using retained diagnostics without weakening assertions.
- [ ] Record final validation and any manual limits, verify fresh review/CI/mergeability state, and leave the PR unmerged.

## Open questions
- None. All actionable PR feedback and conflict fixes are authorized. Public docs must distinguish implemented pages from future atlas concepts. Raw original audit artifacts remain local.

## Codex feedback queue

- [x] Comment 4151809411: derive Settings sound from normalized preferences and verified availability; cover available, missing, and unknown sound values and retain live saved-default updates.
- [x] Comment 4151809417: move bundled-audio scanning off the main actor with cancellation and stale-result guards; cover verified inventory and cancelled work, and verify page navigation/recheck.

- [ ] Comment 4151925030: move George preview verification off the main actor; expose a quiet preparing state and cancellable request, keep player/audio-session work on the main actor, and invalidate preparation on Stop, departure, background/interruption, or loss of eligibility. Add delayed-verification, cancellation/stale-request and verification-failure tests, then rerun preview UI, Release, and repository checks.

## Historical main-branch plan

The following is the incoming PR #12 task record, retained for context. Its merge authorization and unfinished checkboxes do not apply to PR #14; the current action items above govern this task.

> Diagnose the existing UI-test timeouts blocking PR #12 and repair demonstrated test or runner reliability defects. Preserve behavioral assertions, capture actionable failure evidence, and complete review and CI before the authorized merge and branch cleanup.
>
> ## Scope
>
> - In: feasibility UI tests, simulator test diagnostics and CI evidence, focused reliability fixes, developer verification guidance, PR #12 review and merge.
> - Out: new product behavior, audio assets, physical-device acceptance, unrelated worktrees, skipped assertions or automatic retries that conceal failures.
>
> ## Action items
>
> - [x] Inspect the two hosted timeout summaries, existing UI fixtures/helpers, CI workflow, and Development guide; confirm the current branch is clean.
> - [x] Commit this resolved plan before implementation.
> - [x] Reproduce the failing playback test and inspect its transitions; obtain independent Apple-contract diagnosis.
> - [x] Preserve assertion call sites and observed UI values in failure messages; retain hosted result evidence if needed to identify the failing transition.
> - [ ] Apply only fixes supported by evidence, preserving alarm and playback assertions; cover diagnostic script behavior with portable tests if changed.
> - [x] Update docs/Development.md for any new diagnostic controls and artifact handling; verify no private device data enters public source.
> - [ ] Run focused simulator checks and the portable gate, review the diff, then commit and push the bounded changes.
> - [ ] Request current-head Codex review and observe full hosted CI; resolve addressed threads, merge PR #12 when green, and delete only its feature branch.
>
> ## Open questions
>
> - None. The user approved extending PR #12 to diagnose and fix existing UI-test reliability. Root cause is not yet established; no timeout increase is assumed.
>
> ## Evidence
>
> - Hosted attempt 2: 233 passed, one delayed-scheduling UI waiter timeout, six expected physical skips. The failing test passed an unchanged three-iteration local simulator reproduction.
> - Hosted attempt 3: 233 passed, one alarm-enabled playback UI waiter timeout, six expected physical skips. The prior failing test passed. The summary omits the failed assertion call site and observed state; the workflow does not preserve the result bundle.
>
> - The playback failure also passed an unchanged three-iteration local reproduction. Both hosted failures remain intermittent and their causes are unproven. The bounded correction is diagnostic: preserve expected/observed labels and source locations, with existing 5/15-second waits, and retain failed hosted simulator result bundles for seven days.
> - Independent review caught and corrected the artifact root: upload the fresh parent directory so the downloaded archive retains TestResults.xcresult. Three portable regression cases verify successful result publication, failed-test exit preservation, and unreadable-summary exit preservation.
>
> - Diagnostic slice validation: both affected simulator tests passed with the updated helper; all 51 portable tests passed. Brooks diff review found no additional actionable decay or test-quality concern. No production code changed; hosted current-head validation remains required.

## Current PR verification

The merged interface passed 12 focused simulator cases (saved Lab bounds, Rest navigation and functional pages). The sound-summary fix passed four preference unit tests and two UI cases, including live Settings refresh and unavailable-rain fallback; all 51 portable checks and strict changed-Swift formatting pass. The asynchronous inventory fix passed three unit cases and the extended Recheck/reopen UI case; its final Sendable closure passed the three unit cases again. An unsigned Release simulator build and the 51-test repository gate pass. The final hosted checks, refreshed Codex review, and mergeability are live gates after this commit, recorded on PR #14 and in the local review ledger rather than claimed in advance here.
