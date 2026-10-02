# Plan

Make the everyday Rest screen a quick nap timer with duration, background sound, and an optional wake alarm, followed by one explicit Start resting action. Start rain as soon as a requested alarm is verified; keep narrated session planning as a secondary path with its existing immutable review contract.

## Scope
- In: one-screen timer setup, immediate sound-only runs, permission and alarm failure recovery, accessible controls, regression tests, and current flow documentation.
- Out: changes to narration content or its approval rules, automatic playback on reopen, alarm cancellation on playback Stop, and claims of physical listening acceptance.

## Action items
[x] Map Rest navigation, planning/start timing, alarm scheduling, defaults, and existing UI/service tests; read the design language, domain, user guide, screen map, and development checks.
[ ] Add an explicit sound-only timer plan and start path with a fixed deadline, no narration records, and verified alarm evidence before audio.
[ ] Replace ordinary Rest setup with inline duration, sound, and alarm choices plus one Start action; retain narrated plans behind a secondary action and show honest preparation/failure states.
[ ] Cover permission/scheduling delay, expiry, duplicate starts, background departure, unavailable rain, independent alarms, and unchanged narrated-start rules.
[ ] Update UI navigation tests and add quick-start, alarm denial, and largest-text timer coverage without weakening existing assertions.
[ ] Update User Guide, Design Language, Screen Implementation Map, Nap Planning Domain, Decision Log, and relevant onboarding text for the simpler flow.
[ ] Run focused service/UI tests, full simulator suite, compact largest-text checks, strict Swift formatting, and repository verification; inspect rendered timer screens.
[ ] Review the completed change, record validation and remaining device observations, commit coherent checkpoints, and push the current branch.

## Open questions
- None. The quick timer is the default; narration remains an explicit secondary choice. Existing saved duration, sound, and alarm defaults remain effective.
