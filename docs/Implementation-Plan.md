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
- [ ] Run targeted simulator regressions, the full simulator suite, repository verification, formatting lint, and an Apple-platform correctness review; inspect normal/AX5 recovery screenshots.
- [ ] Commit coherent changes and the validation ledger, then push the current branch with only task files staged.

## Open questions
- None. Return to Rest means the actual Rest tab; deliberate selection of an older History entry remains unchanged. Invalid absolute wake times require user correction rather than silent extension.

## Validation ledger
- Plan checkpoint: `a9d3eb8`. Implementation and verification in progress.
- Initial focused run: eight passed; the largest-text exact-time setup needed scrolling that avoids pinned/native overlays. The resulting regression then caught a real recovery layout overflow; shortened the error, moved the time correction first, and stacked native date/time controls at accessibility sizes. Normal recovery and expired-confirmation checks passed; the final AX5 recovery test then passed with both date/time controls fully visible. Screenshots inspected.
- Apple-platform review found two remaining generic sound-copy references; both corrected. No further navigation, timing, cancellation, or alarm ownership issue was identified in source review.
- Repository verification: 66 checks passed. Formatting lint passed. Full simulator suite is running on the larger light-appearance phone.
- Manual VoiceOver and physical-device bedtime/alarm validation remain separate gates from these simulator-tested fixes.
