# Plan

Correct alarm uncertainty, expired-start readiness, and silence-only wording while preserving approved timing and separate alarm ownership, then verify and save a new branch.

## Scope
- In: UX-001–003, state-derived copy and expiry presentation, permanent unit/UI regressions, canonical behavior documentation, local checkpoint commits, and branch push.
- Out: accessibility-audit remediation, physical-device acceptance, layout redesign, scheduling-policy changes, PR creation, and release publishing.

## Action items
- [x] Inspect the review findings, Quiet curiosity design language, User Guide, Troubleshooting, Screen Implementation Map, Nap Planning domain contract, and existing XCTest/verification setup.
- [x] Create `codex/ux-status-recovery-fixes` and checkpoint this resolved plan before implementation.
- [x] Derive alarm recovery headings from verified service state; use plain uncertainty/cancellation wording and extend alarm-service regressions.
- [x] Present expired confirmed plans before Start is tapped, refresh on lifecycle return, preserve fixed timing until renewed review, and test time boundaries and permission/foreground paths.
- [x] Make silence-only waiting, ending, and controls describe quiet rest; preserve audio-bearing plan behavior, alarm consequences, and empty narration history.
- [x] Add UI regressions for the three reported defects and inspect updated normal/large-text states; coordinate view ownership centrally and delegate only disjoint service/test files.
- [x] Update User Guide, Troubleshooting, Screen Implementation Map, and Nap Planning domain documentation for the changed behavior.
- [ ] Run focused XCTest cases, the full simulator suite, repository verification, and correctness review; record results and retained device/VoiceOver gaps.
- [ ] Commit coherent implementation checkpoints, finish this ledger, and push the new branch with only task files staged.

## Open questions
- None. Preserve the existing approved-start boundary and immutable deadline; use a calm renewed-review action instead of silently rescheduling.

## Validation ledger
- Plan checkpoint: `e21d20a`, based on main `2fed8d3`.
- Repository verification: 66 checks passed.
- Correctness review found a missing retry control in uncertain alarm recovery; added **Check again** and explicit system-controls guidance for unreadable alarm details. A second review prompted preserving permission-denial guidance and Settings access after timing expires, now covered by a UI regression.
- Focused final simulator run: 64 passed, zero failures or skips. The first run also passed both real-clock expiry UI paths; its one quiet-rest assertion capitalization error was corrected and passed on rerun.
- Normal and largest-text screenshots inspected: expiry messaging, preserved timestamps, reachable renewed-review action, quiet-rest control, and uncertain-alarm heading.
- Swift formatting lint passed for all changed Swift files. Full-suite validation is in progress.
- Physical-device alarm/audio acceptance and manual VoiceOver traversal remain outside this change.
