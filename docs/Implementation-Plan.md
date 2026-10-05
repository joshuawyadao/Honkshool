# Plan

Repair the blank system-hosted Rest Live Activity and give the active Rest page a prominent remaining-time countdown with clear timer and wake-alarm confirmation. Keep the reviewed deadline fixed and describe playback, rest timing, and verified alarms separately.

## Scope
- In: WidgetKit rendering diagnosis and regression coverage; accessible active-Rest countdown and state wording; canonical user/design/development documentation; signed build and installation after any current rest ends.
- Out: Changing playback, alarm scheduling, snooze, rest duration, listening acceptance, PR merge, or scheduled automation.

## Action items
[x] Capture the current blank-card symptom and build a repeatable WidgetKit rendering/diagnostic feedback loop; retain personal-device evidence only in ignored local-data.
[x] Reproduce and minimize the rendering failure, compare falsifiable causes, and fix the verified rendering boundary with regression coverage.
[x] Add a prominent remaining-time countdown and explicit active timer confirmation to the Rest page using admitted run timing; keep waiting, paused, interrupted, stopped, failed, finished, and expired states honest.
[x] Cover active countdown, deadline stability, no-alarm and verified-alarm wording, larger text, and narrow-screen behavior with focused unit/layout/UI tests.
[x] Update User-Guide, Design-Language, Architecture, Development and Troubleshooting where behavior or validation changes.
[ ] Run focused regression tests, the full simulator suite, strict Swift formatting and repository checks; verify a signed Release build and retain provenance.
[ ] Save coherent local checkpoints and push codex/device-acceptance-ui; install in place when the phone is free, launch normally and record hardware observations without inferring them.

## Open questions
- None. Use a calm, prominent native numeric countdown; never extend the fixed deadline or treat the countdown as proof that an alarm sounded.

## Discovery and regression evidence

The original widget displayed only its Rest title in the system host. Accessibility-only checks passed despite blank pixels. The hosted screenshot regression fails on the original intrinsic-size timer; using an explicit scaled width follows WidgetKit's flexible timer sizing contract. Keep screenshot and permission diagnostics ignored. The app countdown evaluates the current time on a timeline starting now; starting the schedule at the future deadline caused the first render to claim the rest had ended. Native timer text handles the visible ticking.

The corrected hosted rendering, active countdown, pause/deadline, one-minute ticking and larger-text checks pass together (13 focused tests). Strict formatting and all 51 repository checks pass. The full simulator suite and final signed build/installation remain in progress.
