# Plan

Reduce the owner's long manual acceptance run by testing the complete prepared asset and real-player completion quickly on a simulator, then provide brief representative listening samples. Keep real iPhone alarm and audio-route behavior clearly separate from simulated evidence.

## Scope

- In: focused AVFoundation tests for the bundled George file, an ignored short review reel, a shorter device checklist, updated validation notes and roadmap, and branch validation/save.
- Out: changing the narration, altering production timing, scheduling a real alarm on the owner's phone, and claiming subjective approval of audio the owner has not heard.

## Action items

- [x] Map existing deadline, transition, interruption, route-loss, asset, and alarm test coverage in the code and `docs/Feasibility-Spike.md`.
- [x] Extend `HonkshoolTests/PreparedCatalogTests.swift` to read every George PCM frame through AVFoundation, and add a fast real-player tail-completion/ambience/deadline test in `HonkshoolTests/SpikeModelsTests.swift`.
- [x] Add a small standard-library reel generator under `scripts/` and generate a short opening/middle/ending review WAV from the unchanged bundled source into ignored `outputs/` for optional listening.
- [x] Update `README.md`, `docs/Decision-Log.md`, `docs/Feasibility-Spike.md`, `docs/Audio-Preparation.md`, and `docs/Project-Implementation-Plan.md` to distinguish automated technical evidence from brief remaining iPhone and subjective checks.
- [x] Run focused tests, the complete available iOS simulator suite, repository checks, formatting, and relevant build validation; inspect the diff. Check that local Xcode test cleanup does not wait on optional simulator diagnostics.
- [x] Commit and push the branch with `$save-branch`, leaving the review reel as an ignored local artifact.

## Open questions

- None. The user's time constraint is resolved by making technical playback checks unattended and reducing subjective review to short samples. Actual system alarm delivery and AirPods/Siri behavior still require limited physical-device observation.

## Validation

- Two focused AVFoundation tests passed on the iOS 27 simulator, then the full suite passed 135 tests with no failures or skips. The local test-script rerun exited cleanly in about 4.5 minutes after disabling Xcode's optional post-test simulator diagnostics. CI retains failure diagnostics.
- The 31 repository checks, strict Swift formatting, Python syntax check, shell syntax check, diff whitespace check, and unsigned Release simulator build passed.
- The ignored review reel is 86.125 seconds and uses unchanged PCM from paragraphs 1, 7, and 13 of the verified bundled George narration.
- Remaining physical evidence: brief AirPods/Siri/Lock Screen checks, one-minute real-alarm delivery, and representative voice listening. Complete-session subjective comfort and simultaneous real-alarm/narration cutoff remain unverified.
