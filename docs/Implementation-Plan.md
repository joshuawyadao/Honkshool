# Plan

Create the first iOS 26 feasibility spike for Honkshool on `spike/audio-and-alarm-feasibility`. Build only enough signable SwiftUI application surface to measure direct on-device narration, exclusive background audio, a narration-to-ambience transition, remote controls, interruption reporting, and AlarmKit authorization and scheduling before those choices shape the production architecture.

## Scope

- In: an iOS 26 SwiftUI app with bundle identifier `com.joshuawyadao.Honkshool`, a short “Turning Fuel Into Motion” sample, direct AVSpeechSynthesizer playback, generated neutral ambience, basic Lock Screen controls, observable interruption events, AlarmKit test scheduling/cancellation, focused state tests, setup instructions, and a physical-device test checklist.
- Out: the complete session script, Nap Plan assembly, SwiftData history, journey progression, polished product UI, a distributable ambience asset, final playback architecture decisions, and claims that simulator or compile-time checks establish physical-device reliability.

## Action items

- [x] Add a dependency-free Xcode project and iOS 26 SwiftUI app target configured for background audio and `com.joshuawyadao.Honkshool`.
- [x] Add a compact spike state model with tests for alarm gating, playback transitions, interruption handling, and stable UI status messages.
- [x] Implement exclusive AVAudioSession setup, direct AVSpeechSynthesizer narration, a generated neutral-noise ambience transition, and diagnostic event logging.
- [x] Add Now Playing metadata and intentional play, pause, and stop remote commands without exposing route-changing controls.
- [x] Add AlarmKit authorization, fixed-date test alarm scheduling, cancellation, and strict blocking when an alarm-enabled run is not authorized or cannot be scheduled.
- [x] Build a single SwiftUI test console that exposes the agreed sample, 20/30/45/60/custom durations, a reusable 35-minute default, ambience selection, and explicit feasibility actions.
- [x] Add setup and physical-device verification documentation; record the accepted user decisions and keep unresolved device findings pending in the decision log and project roadmap.
- [x] Compile the focused unit-test bundle, run simulator-SDK and generic-device builds, run repository and formatting checks, review stale references, and document why execution and physical-device validation remain manual.

## Open questions

- None. Physical-device results are evidence to collect during the spike, not clarifying input required before implementation.
