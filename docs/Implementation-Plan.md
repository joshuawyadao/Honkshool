# Plan

Make specific rest durations easy to set with native hours-and-minutes wheels, clarify sound and switch selection, and show a truthful remaining-rest countdown on the Lock Screen. Preserve the fixed deadline, explicit Start, independent wake alarm, and existing narration rules.

## Scope
- In: shared custom-duration wheels, explicit selected/On/Off states, a fixed-deadline rest Live Activity, targeted regression and layout checks, current user/design/platform documentation, and the owner's latest device observations.
- Out: changing alarm delivery or snooze policy, extending a deadline when audio pauses, autoplay, new narration content, scheduled installation, and claiming new Lock Screen acceptance without device observation.

## Action items
[x] Map timing/selection controls, native alarm and playback ownership, current widget, UI tests, and the Design Language, User Guide, Development guide, and device evidence.
[ ] Verify the platform countdown contract and define honest states for alarm-free rest, audio pause/Stop, deadline, and relaunch.
[ ] Replace minute steppers in routine timer and narrated time choices with bounded hours/minutes wheel pickers; clarify sound/preset selection and switch states while preserving accessibility semantics.
[ ] Add the remaining-rest Live Activity using the immutable run deadline and accurate alarm status; keep its lifecycle independent from media controls and alarm cancellation.
[ ] Update affected UI tests, add meaningful duration-boundary and countdown lifecycle/layout coverage, and retain existing timer/narration/alarm invariants.
[ ] Update User Guide, Design Language, architecture/widget documentation and device evidence; record rain and alarm observations without inferring cutoff or comfort.
[ ] Run focused UI/service/layout tests, the relevant broader suite, repository verification, strict formatting, and a Release build; inspect normal, dark, compact, and large-text layouts.
[ ] Review the Apple-platform change, record verification and remaining physical checks, commit coherent checkpoints, and push the current branch.

## Open questions
- None. Duration remains one through 180 whole minutes. Lock Screen presentation may be disabled by system Live Activity settings; rest/alarm behavior must continue correctly in that case.
