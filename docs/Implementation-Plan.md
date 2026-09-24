# Plan

Add an opt-in, real-iPhone integration check for the remaining simultaneous AlarmKit alert and prepared-narration cutoff. Keep subjective full-session comfort separate: no automated signal or transcript check can certify that a listener finds the narration calming.

## Scope

- In: a gated device test using the bundled George audio and real AlarmKit, safe alarm cleanup, documentation of what it proves, validation, and branch save.
- Out: changing production playback behavior, treating a simulator alarm as physical-device evidence, and marking subjective listening comfort accepted.

## Action items

- [x] Inspect current AlarmKit, playback, and test seams; confirm the target iPhone's availability.
- [x] Add an opt-in device test that schedules a short real alarm, starts prepared narration at the same deadline, observes AlarmKit alerting and narration stop, and attempts alarm cleanup on every normal test exit.
- [x] Keep the test skipped in ordinary simulator and CI runs; require explicit opt-in and existing AlarmKit authorization on a connected iPhone.
- [x] Update `docs/Feasibility-Spike.md` and the durable roadmap to describe the automated device check and its physical/subjective limits.
- [x] Run focused simulator validation, repository checks, formatting, a Release build, and the broader simulator suite; run the real-device check only if the iPhone becomes available.
- [x] Commit and push the existing content-catalog branch, reporting any device validation still pending.

## Open questions

- None. The iPhone was offline during implementation, then reconnected for the opt-in physical test.

## Validation

- The opt-in test was discovered and safely skipped on the iOS 27 simulator. The full simulator suite passed 135 tests with zero failures and one intended device-only skip.
- The physical-iOS test bundle compiled before the phone reconnected. The opt-in test subsequently passed on iPhone 18 Pro Max / iOS 27.0: one pass, zero failures, zero skips. It observed AlarmKit `alerting` and wake-deadline narration stop inside the asserted timing tolerances, then cleaned up its alarm.
- Repository checks passed 31 tests; strict Swift formatting, an unsigned Release simulator build, and diff whitespace checks passed.
- Full-session subjective comfort has no reliable automated pass/fail test and remains pending for a normal listening session.
