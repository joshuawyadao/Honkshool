# Plan

Make specific rest durations easy to set with native hours-and-minutes wheels, clarify sound and switch selection, and show a truthful remaining-rest countdown on the Lock Screen. Preserve the fixed deadline, explicit Start, independent wake alarm, and existing narration rules.

## Scope
- In: shared custom-duration wheels, explicit selected/On/Off states, a fixed-deadline rest Live Activity, targeted regression and layout checks, current user/design/platform documentation, and the owner's latest device observations.
- Out: changing alarm delivery or snooze policy, extending a deadline when audio pauses, autoplay, new narration content, scheduled installation, and claiming new Lock Screen acceptance without device observation.

## Action items
[x] Map timing/selection controls, native alarm and playback ownership, current widget, UI tests, and the Design Language, User Guide, Development guide, and device evidence.
[x] Verify the platform countdown contract and define honest states for alarm-free rest, audio pause/Stop, deadline, and relaunch.
[x] Replace minute steppers in routine timer and narrated time choices with bounded hours/minutes wheel pickers; clarify sound/preset selection and switch states while preserving accessibility semantics.
[x] Add the remaining-rest Live Activity using the immutable run deadline and accurate alarm status; keep its lifecycle independent from media controls and alarm cancellation.
[x] Update affected UI tests, add meaningful duration-boundary and countdown lifecycle/layout coverage, and retain existing timer/narration/alarm invariants.
[x] Update User Guide, Design Language, architecture/widget documentation and device evidence; record rain and alarm observations without inferring cutoff or comfort.
[x] Run focused UI/service/layout tests, the relevant broader suite, repository verification, strict formatting, and a Release build; inspect normal, dark, compact, and large-text layouts.
[x] Review the Apple-platform change, record verification and remaining physical checks, commit coherent checkpoints, and push the current branch.

## Open questions
- None. Duration remains one through 180 whole minutes. Lock Screen presentation may be disabled by system Live Activity settings; rest/alarm behavior must continue correctly in that case.

## Verification notes
- Apple correctness review tightened silent-settling admission, quick-pause admission and persistent card wording. The native timer retains its numeric accessibility value.
- Focused wheel tests pass for custom values, one-minute saved defaults, largest-text narration and the three-hour boundary on a compact iPhone SE simulator. Queries use each picker container’s native wheel. Gestures stay inside the content gutter so pinned actions and wheel controls cannot consume page scrolling. Wrapped labels keep both selected wheel rows aligned.
- All 252 unit/service tests pass; five physical-only unit cases are intentionally skipped. Countdown renderings reject blank output. A 166-point layout at the first accessibility size led to reduced vertical padding while preserving native text sizes and the 160-point ceiling. Fixture isolation now also protects an owner’s existing system activity from updates or cleanup.
- Repository gate: 51 checks pass; strict formatting passes for all 16 changed Swift files. The signed Release app includes its widget and matches the recorded source manifest.
- The broader dark-mode suite completed with 307 passes, six physical-only skips and two switch-interaction failures. Captured accessibility geometry shows an adaptive switch beneath its compound label; tests now find and scroll to the native control instead of assuming its position. Both repaired cases and the normal custom-timer regression pass on the original dark-mode destination, with state and persistence assertions retained. Combined final coverage is 252 unit/service tests and all 58 simulator-capable UI cases passing; this combines completed suites and focused reruns rather than claiming that the original failing bundle passed.
- Inspected normal, dark, compact, and accessibility-size screenshots. Temporary diagnostic instrumentation was removed. The temporary compact simulator was removed, and the original test simulator was returned to light appearance and shutdown. New Lock Screen hardware visibility and spoken output remain unverified.
