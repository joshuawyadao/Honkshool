# Plan

Make the everyday Rest screen a quick nap timer with duration, background sound, and an optional wake alarm, followed by one explicit Start resting action. Start rain as soon as a requested alarm is verified; keep narrated session planning as a secondary path with its existing immutable review contract.

## Scope
- In: one-screen timer setup, immediate sound-only runs, permission and alarm failure recovery, accessible controls, regression tests, and current flow documentation.
- Out: changes to narration content or its approval rules, automatic playback on reopen, alarm cancellation on playback Stop, and claims of physical listening acceptance.

## Action items
[x] Map Rest navigation, planning/start timing, alarm scheduling, defaults, and existing UI/service tests; read the design language, domain, user guide, screen map, and development checks.
[x] Add an explicit sound-only timer plan and start path with a fixed deadline, no narration records, and verified alarm evidence before audio.
[x] Replace ordinary Rest setup with inline duration, sound, and alarm choices plus one Start action; retain narrated plans behind a secondary action and show honest preparation/failure states.
[x] Cover permission/scheduling delay, expiry, duplicate starts, background departure, unavailable rain, independent alarms, and unchanged narrated-start rules.
[x] Update UI navigation tests and add quick-start, alarm denial, and largest-text timer coverage without weakening existing assertions.
[x] Update User Guide, Design Language, Screen Implementation Map, Nap Planning Domain, Decision Log, and relevant onboarding text for the simpler flow.
[x] Run focused service/UI tests, full simulator suite, compact largest-text checks, strict Swift formatting, and repository verification; inspect rendered timer screens.
[x] Review the completed change, record validation and remaining device observations, commit coherent checkpoints, and push the current branch.

## Open questions
- None. The quick timer is the default; narration remains an explicit secondary choice. Existing saved duration, sound, and alarm defaults remain effective.

## Validation results

- Initial focused run: 97 passed, no failures. Timer domain and alarm/runtime cases cover fixed deadlines, bounded setup, permission denial, matching receipts, duplicate/background starts, immediate rain/silence, cutoff, and no narration history.
- Full iPhone 17 Pro / iOS 26.5 run: 291 passed, one layout failure, six intentionally skipped physical-device cases. The added narrated-flow back button pushed the alarm row below the pinned action. Moving it into the navigation bar preserved the existing assertion; the exact failed test then passed on the same destination. The first rerun could not launch its simulator runner; a booted retry passed. The complete suite was not repeated after these narrow repairs.
- Compact iPhone SE / iOS 26.5 follow-up: 50 passed initially. One new custom-time test exposed a disclosure identifier overriding its child controls; scoping the identifier to the label fixed it. Custom/exact timing and AX5 timer checks both passed on rerun. A separate narration assertion intended for the standard viewport also failed on SE and passed on its standard destination; its assertion was preserved.
- Additional UI checks passed for leaving during authorization, alarm-denial recovery, immediate rain with a verified alarm, retaining cancellation after uncertain scheduling, and clearing the error after cancellation. The final cancellation-recovery test passed separately. Normal and AX5 screenshots were inspected.
- Repository verification: 51 checks passed. Changed Swift files pass strict formatting. Independent Apple-platform review findings were addressed. Signed Release build and signature verification passed.
- Updated the user/onboarding guides, design language, screen map, planning domain, decision log, README, and first-nap illustration. No personal logs or device artifacts are included in Git.
- Device installation remains pending: the previously connected iPhone is unreachable. Physical audibility and Lock Screen acceptance remain unobserved for this new build.
