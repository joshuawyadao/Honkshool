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
[ ] Run focused service/UI tests, full simulator suite, compact largest-text checks, strict Swift formatting, and repository verification; inspect rendered timer screens.
[ ] Review the completed change, record validation and remaining device observations, commit coherent checkpoints, and push the current branch.

## Open questions
- None. The quick timer is the default; narration remains an explicit secondary choice. Existing saved duration, sound, and alarm defaults remain effective.

## Validation in progress

- Initial focused run: 97 tests passed with no failures, covering timer domain/services and Rest screens, including AX5. A subsequent review tightened setup to at most five seconds or 5% of duration and clarified alarm-off/accessibility wording.
- Full simulator regression is running. Follow-up coverage includes leaving during authorization, inline custom/exact timing, uncertain alarm cancellation, final recovery copy, and compact AX5 layout.
- Repository verification: 51 checks passed. Changed Swift files pass strict formatting. Independent Apple-platform review findings were addressed; physical audibility and Lock Screen acceptance remain pending.

- Compact follow-up: 50 checks passed. The custom-time disclosure propagated its identifier to child controls; moving that identifier to the disclosure label fixed the regression. Both custom/exact timing and AX5 timer checks passed on rerun. A standard-height narration visibility assertion also failed when deliberately run on the smaller SE viewport; its standard destination remains under verification.
