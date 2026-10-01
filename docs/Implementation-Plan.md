# Plan

Complete the merged-build iPhone acceptance run and repair the reproducible physical UI test setup failure. Preserve the production app and its audio, alarm, history, and privacy contracts while testing the custom-duration path through the current Rest interface.

## Scope
- In: custom-duration UI test diagnosis and correction; focused simulator coverage of that setup path; physical acceptance evidence in `docs/Feasibility-Spike.md`; signed merged Release installation; private raw device results.
- Out: new product features, production playback or timing changes, invented manual listening results, publishing device logs, and PR creation or merge.

## Action items
- [x] Read the device, development, trial, and Rest interface guidance; inspect test isolation and preserve a clean merged-build provenance record.
- [x] Build the merged source and run the four real audio/history/alarm tests; reproduce the custom-duration UI setup failure in a second isolated device run.
- [x] Checkpoint this plan before editing the test.
- [x] Inspect the current control hierarchy, correct the test selector or sheet navigation at the demonstrated failure, and retain all deadline, background, history, and no-autoplay assertions.
- [x] Exercise the custom-duration setup in ordinary simulator tests at normal and largest text sizes so the physical-only path cannot silently lose this coverage.
- [x] Run the complete simulator suite, focused regressions, formatting, and repository verification; investigate failures without weakening assertions. Preserve the separate reproduced accessibility failure below as unresolved.
- [x] Run the corrected physical UI case after the owner unlocks the phone. Duration setup, first controls, and background return passed; the later Pause tap did not change the visible playing state.
- [ ] Diagnose the post-background Pause tap with immediate status/control evidence and rerun the full physical case without removing its control or deadline assertions.
- [x] Record sanitized evidence and remaining human observations in `docs/Feasibility-Spike.md`, install the signed merged Release app in place, and retain raw results only in ignored local data.
- [x] Restore and launch the installed Release app normally after unlocking. Direct listening and Lock Screen observations remain pending until provided.
- [x] Review the final test diff and checkpoint the correction. Save the final evidence update and push the focused branch with the validation limits explicit.

## Open questions
- None for the test repair. Locked-screen controls, headphone disconnection, audible alarm/cutoff, and listening comfort require direct owner observations and remain pending until provided.

## Evidence
- Clean merged source: `e22edca`. Signed Debug test build and signed Release build passed on Xcode 27.0; Release signature verification passed.
- iPhone 18 Pro Max / iOS 27.0: four real audio/history/alarm cases passed with zero failures or skips. The physical UI case failed twice at the custom-duration Stepper lookup before playback began. The recording shows the Time sheet and control visibly present; inspect the accessibility query before choosing the correction.
- Raw device outputs and build provenance are ignored under `local-data/device-acceptance/`; no personal identifiers or raw records belong in the committed evidence.
- The largest-text iOS 27 simulator reproduced the non-hittable Stepper setup failure. Targeting the native Decrement button and asserting the resulting one-minute value passed both focused simulator cases. No production source changed.
- All 51 repository checks, strict Swift formatting, and diff checks passed. The merged Release app installed in place; the phone subsequently blocked ordinary launch and further physical tests because it was locked. Direct observations and the corrected physical UI rerun remain pending.
- The complete iOS 27 simulator run reported 274 passes, one failure, and six intentional physical-only skips. Both new cases passed. The unchanged largest-text duration/sound test failed because `napPlanPreset-60` was reported unreachable, and a focused unchanged rerun failed the same way. The recording shows the preset, so a production interaction defect is not established. This separate accessibility finding remains unresolved; the full suite is not green.
- Independent Apple-contract review found no issue in the narrow test correction: all physical playback/deadline/history assertions remain, and one-minute selection is checked directly. No raw diagnostics, personal observations, or signing data are committed.
- On the unlocked phone, the corrected physical test reached real rain, first pause/resume, 12 seconds in the background, and the same deadline on return. Its second Pause tap left the visible status at “Gentle rain resumed” with Pause still shown; the deadline was still in the future. The test eventually failed searching for Resume. Capture that state directly rather than allowing scrolling to obscure the original failure. The normal merged Release app was restored and launched successfully afterward.
