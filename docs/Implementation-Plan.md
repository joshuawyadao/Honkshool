# Plan

Connect accepted gentle rain to the production Nap Plan flow, then verify the complete nap experience on the target iPhone. Use the bundled prepared loop, retain silence as a choice and fallback, and keep audio controls, fixed deadlines, alarm ownership, and honest listening history consistent across narration and rain.

## Scope
- In: a concrete rain audition and recorded listening decision; verified local rain availability; pre-play rain selection; looping rain for approved settling, drift, and remaining rest; pause/resume, interruption, headphone-loss, Stop, and fixed-deadline behavior; automated regression coverage; documented physical acceptance; local checkpoints and a final branch push.
- Out: new factual content, journey branching, narration mixing or regeneration, voice selection, networking, cloud sync, analytics, automatic playback on relaunch, and changes to alarm ownership or saved-history schema. Full-session comfort requires an actual listening observation; simulator checks cannot close physical acceptance.

## Action items
- [x] Inspect the roadmap, product brief, D-002/D-004/D-008/D-009, audio preparation/provenance, runtime controls, review availability, and existing repository/iOS tests; confirm clean main at merged PR #8 (`7fb9801`).
- [x] Prepare a 39.465-second audition containing four exact repetitions of the bundled rain PCM, with no gain or speed changes; keep the generated file in ignored `outputs/` and request the owner's listening decision.
- [x] Resolve the rain choice: on 2026-09-28 the owner requested using the current candidate and continuing the goal. Commit this resolved plan as the first local checkpoint before implementation.
- [ ] Add verified bundled-rain resolution and an injectable looping player; expose an understandable Gentle rain choice and reviewed silence fallback only when the accepted asset is available.
- [ ] Execute the approved rest sound during settling and after narration, including rain-only short plans; share the run's fixed deadline and explicit controls, recheck the deadline after setup/resume, preserve alarm ownership, and keep rain out of narration checkpoints/completion evidence. Handle unavailable/failed rain with visible silence fallback without a mid-nap prompt.
- [ ] Extend runtime and UI tests for narration-to-rain, settling/rain-only windows, loop setup failure, pause/resume, interruptions, output disconnection, Stop, exact/late cutoff, stale callbacks, and unchanged narration history; verify real bundled decoding/loop behavior at the adapter level.
- [ ] Run targeted iOS tests, the full unit/UI suite via `scripts/test-ios.sh`, `scripts/verify-repository.sh`, strict Swift formatting, project lint, and an unsigned Release simulator build; request a focused Apple-platform correctness review and checkpoint coherent verified work.
- [ ] Update README.md and docs/Project-Implementation-Plan.md, Project-Overview.md, Product-Brief.md, Nap-Planning-Domain.md, Content-Catalog.md, Audio-Preparation.md, Decision-Log.md, and Feasibility-Spike.md as applicable, including stale history-integration notes and the exact distinction between listening acceptance, automated checks, and physical observations.
- [ ] Prepare/install the signed target-iPhone build when the device is available; guide short rain/locked-control, route-loss, alarm, and history/relaunch checks, record pass/fail/blocked observations without private identifiers, and address observed defects. Record full-session comfort only when the owner reports actual use.
- [ ] Save and push the completed branch with the plan, verification evidence, and any explicitly pending physical acceptance clearly recorded; do not describe the goal as complete while required acceptance remains unobserved.

## Open questions
- None block implementation. The owner accepted the existing rain candidate on 2026-09-28. Narration-to-rain relative level and physical-device behavior remain explicit acceptance checks after implementation; no physical outcome is inferred from this sound-selection decision.
