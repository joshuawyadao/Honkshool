# Plan

Reduce the owner's long manual acceptance run by testing the complete prepared asset and real-player completion quickly on a simulator, then provide brief representative listening samples. Keep real iPhone alarm and audio-route behavior clearly separate from simulated evidence.

## Scope

- In: focused AVFoundation tests for the bundled George file, an ignored short review reel, a shorter device checklist, updated validation notes and roadmap, and branch validation/save.
- Out: changing the narration, altering production timing, scheduling a real alarm on the owner's phone, and claiming subjective approval of audio the owner has not heard.

## Action items

- [x] Map existing deadline, transition, interruption, route-loss, asset, and alarm test coverage in the code and `docs/Feasibility-Spike.md`.
- [ ] Extend `HonkshoolTests/PreparedCatalogTests.swift` to read every George PCM frame through AVFoundation, and add a fast real-player tail-completion/ambience/deadline test in `HonkshoolTests/SpikeModelsTests.swift`.
- [ ] Generate a short opening/middle/ending review reel from the unchanged bundled WAV in ignored `outputs/` for optional listening.
- [ ] Update `docs/Feasibility-Spike.md` and `docs/Project-Implementation-Plan.md` to distinguish automated technical evidence from brief remaining iPhone and subjective checks.
- [ ] Run focused tests, the complete available iOS simulator suite, repository checks, formatting, and relevant build validation; inspect the diff.
- [ ] Commit and push the branch with `$save-branch`, leaving the review reel as an ignored local artifact.

## Open questions

- None. The user's time constraint is resolved by making technical playback checks unattended and reducing subjective review to short samples. Actual system alarm delivery and AirPods/Siri behavior still require limited physical-device observation.
