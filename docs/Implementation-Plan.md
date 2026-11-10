# Plan

Fix the three follow-up UX findings with truthful sound-only copy, visible exact-time recovery, and a real return to Rest using current progress, then verify, commit, and push the existing branch.

## Scope
- In: UX-005–007, regression tests, canonical user-flow documentation, checkpoint commits, and push to `codex/ux-status-recovery-fixes`.
- Out: accessibility-audit remediation, physical-device acceptance, playback/scheduling policy changes, PR creation, and release publishing.

## Action items
- [x] Inspect the follow-up report, Quiet curiosity design language, User Guide, Screen Implementation Map, Development test instructions, and relevant view/navigation tests.
- [x] Checkpoint this resolved plan on the current branch before implementation.
- [x] Make the post-run return action switch to Rest and refresh its latest selection without changing intentional History Resume/Replay choices, autoplay guards, or retained alarm ownership.
- [x] Show invalid exact-wake feedback in the Time sheet with an immediately reachable correction; preserve the selected absolute time and Cancel behavior.
- [x] Use rest-sound and permission wording appropriate to empty narration routes; omit checkpoint promises when no narration plays.
- [x] Add permanent UI regressions for History return, exact-time recovery at standard/AX5 text, and sound-only review/Ready/permission states; preserve existing narration and expiry tests.
- [x] Update User Guide and Screen Implementation Map; retain the existing domain/audio policy and document remaining manual validation gaps here.
- [x] Preserve an acknowledged recovered checkpoint when returning after a waiting-only run; add regression coverage for this navigation edge.
- [x] Stabilize the existing largest-text sound-navigation test by keeping targets clear of navigation/pinned controls, preserving all selection and accessibility assertions.
- [x] Run targeted simulator regressions, the full simulator suite, repository verification, formatting lint, and an Apple-platform correctness review; inspect normal/AX5 recovery screenshots.
- [x] Commit coherent changes and the validation ledger; push the current branch with only task files staged.

## Open questions
- None. Return to Rest means the actual Rest tab; deliberate selection of an older History entry remains unchanged. Invalid absolute wake times require user correction rather than silent extension.

## Validation ledger
- Plan checkpoint: `a9d3eb8`; implementation checkpoint: `b72950e`.
- Added six permanent UI regressions in `NapPlanReviewUITests.swift` and `ListeningHistoryUITests.swift`. Updated existing assertions in `FunctionalPagesUITests.swift` and scrolling in `AccessibilityRefreshUITests.swift`; no behavioral assertions were removed or relaxed.
- Targeted tests caught a real largest-text recovery overflow after the initial setup tap was corrected. Shortened the error, put the correction first, and stacked native date/time fields at accessibility sizes. Normal/AX5 recovery screenshots show the full error and editable time above Apply; Cancel preserves the selected time.
- Apple-platform review prompted completing generic sound wording and preserving recovery acknowledgement after a waiting-only run. The final return action refreshes the existing Rest view and reseeds saved progress without recreating it. Latest-checkpoint, older-record selection, retained-alarm, no-autoplay, and acknowledged-checkpoint regressions pass.
- Final validation on the compact dark simulator: 251 passed, zero failures, five opt-in physical-device skips. This includes all 233 unit tests and 18 relevant UI tests against the final navigation change, including all three accessibility tests.
- Broader full-suite run on the larger light simulator at `b72950e`: 288 passed, one failed, six opt-in physical-device skips. Its existing largest-text sound-selection test could not reach Silence after the sound-row tap (the recording confirms it opened Review instead of Sound); the strengthened helper and the complete three-test accessibility suite passed in final validation. Preserve the original run result rather than describing it as clean.
- Repository verification: 66 checks passed after the final code changes. Swift formatting lint and diff whitespace checks passed. Existing internal QoS warnings remain in unit-test results; no new user-facing performance defect was established.
- User Guide and Screen Implementation Map updated. Domain, storage, playback, and alarm policy are unchanged, so their canonical documents need no revision.
- Logs, synthetic screenshots, and result bundles are excluded from commits. Manual VoiceOver and physical-device bedtime/alarm validation remain separate gates.
- Saved branch: `codex/ux-status-recovery-fixes`; final commit records the verified recovery refinement and this ledger. No PR or merge is part of this task.
