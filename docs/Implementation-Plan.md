# Plan

Add an opt-in, real-iPhone integration check for the remaining simultaneous AlarmKit alert and prepared-narration cutoff. Keep subjective full-session comfort separate: no automated signal or transcript check can certify that a listener finds the narration calming.

## Scope

- In: a gated device test using the bundled George audio and real AlarmKit, safe alarm cleanup, documentation of what it proves, validation, and branch save.
- Out: changing production playback behavior, treating a simulator alarm as physical-device evidence, and marking subjective listening comfort accepted.

## Action items

- [x] Inspect current AlarmKit, playback, and test seams; confirm the target iPhone's availability.
- [ ] Add an opt-in device test that schedules a short real alarm, starts prepared narration at the same deadline, observes AlarmKit alerting and narration stop, and always cleans up its alarm.
- [ ] Keep the test skipped in ordinary simulator and CI runs; require explicit opt-in and existing AlarmKit authorization on a connected iPhone.
- [ ] Update `docs/Feasibility-Spike.md` and the durable roadmap to describe the automated device check and its physical/subjective limits.
- [ ] Run focused simulator validation, repository checks, formatting, a Release build, and the broader simulator suite; run the real-device check only if the iPhone becomes available.
- [ ] Commit and push the existing content-catalog branch, reporting any device validation still pending.

## Open questions

- None. The iPhone currently appears offline in Xcode, so device execution may remain pending; implementation and simulator validation can proceed.
