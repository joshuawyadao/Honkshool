# Plan

Make the accepted Kokoro George `0.86` narration playable in the iPhone app through a deterministic prepared-audio path. Render the complete catalog session locally, bundle a lossless file and provenance, connect it to the existing feasibility console with fixed-deadline stopping, and keep live on-device model inference out of this slice because it would add a roughly 327 MB model plus an unproven runtime for one curated session.

## Scope

- In: reproducible full-session preparation, a bundled George narration asset, catalog-to-asset metadata, prepared-file playback and pause/resume, fixed wake-deadline cutoff, focused tests, device/simulator builds, and updated audio/roadmap evidence.
- Out: shipping Kokoro model weights or an inference dependency, runtime downloads, production Nap Plan UI or persistence, partial-position persistence, voice selection, rain acceptance/integration, additional sessions, PR creation, and merge.

## Action items

- [x] Verify the clean branch, current catalog/audio architecture, accepted George settings, available model cache, Xcode destinations, and existing playback/catalog tests.
- [x] Add a reusable offline preparation script that renders every catalog paragraph with pinned Kokoro/George inputs, assembles the approved gaps and level, exports a lossless app asset, and writes verifiable provenance.
- [x] Extend the prepared catalog metadata so the session identifies its exact narration asset and measured duration without coupling the domain layer to AVFoundation.
- [x] Add a small prepared-audio adapter to the feasibility controller, preserving exclusive playback, pause/resume, interruptions, Lock Screen commands, natural completion, ambience/silence routing, and cancellation of stale callbacks.
- [x] Pass the captured wake deadline into playback and stop the active prepared narration or ambience at that fixed deadline without accelerating audio or delaying the alarm.
- [x] Switch the feasibility console from provisional AVSpeechSynthesizer text to the bundled George session, with a visible load failure instead of a silent Apple-voice fallback.
- [x] Add focused catalog, asset, controller, completion, stale-callback, invalid-deadline, and fixed-deadline tests while preserving the existing direct-speech regression coverage.
- [x] Update the narration evidence, decision log, product/roadmap status, and feasibility instructions with the selected prepared-audio architecture and its remaining physical-device checks.
- [x] Run the asset checks, targeted and full iOS suites where destinations permit, repository checks, formatter, simulator and generic-device builds, then review, commit, and push with `save-branch`.

## Open questions

- None. Use prepared lossless audio for this curated prototype session; retain live on-device Kokoro inference as a later option only if catalog scale makes its model size and runtime cost worthwhile.

## Results

- Prepared the complete 1,829-word **Turning Fuel Into Motion** session with Kokoro George at speed `0.86` as a 727.625-second mono PCM WAV. The catalog uses a configurable 730-second planning estimate and verifies the asset's SHA-256 before publication.
- Added deterministic provenance and an offline preparation script without shipping Kokoro model weights or a live inference dependency in the app.
- Replaced the console's provisional text-to-speech start path with the prepared file, including pause/resume, natural completion, silence/ambience routing, stale-callback protection, and a fixed wake-deadline cutoff.
- Passed all 31 repository verification tests and all 134 iOS simulator tests with zero failures or skips. Strict Swift formatting, `git diff --check`, and unsigned Release builds for the generic simulator and generic iPhone device also pass.
- A compatible physical iPhone was unavailable for this implementation pass. The six-step prepared-playback device checklist in `docs/Feasibility-Spike.md` remains the only acceptance work before this audio path can be treated as device-verified.
