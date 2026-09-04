# Audio and alarm feasibility spike

## Purpose

This spike tests the riskiest Honkshool assumptions before they become production architecture. It is a diagnostic console, not the intended product interface and not a supported release.

The current candidate implementation exercises:

- direct on-device narration with AVSpeechSynthesizer;
- an exclusive AVAudioSession playback category;
- locked-screen background audio capability;
- a transition to generated neutral noise or silence;
- play, pause, and stop commands with Now Playing metadata;
- interruption and audio-route event logging;
- AlarmKit authorization, fixed-date scheduling, cancellation, system stop, and a nine-minute countdown-style snooze;
- strict blocking when an alarm-enabled run is not authorized or cannot be scheduled; and
- recommended, custom, exact-wake-time, and reusable-default rest timing.

The generated noise exists only to test the transition and background audio path. It is not the lawful ambience asset intended for the prototype catalog. The short “Turning Fuel Into Motion” script is likewise provisional and has not passed the future content-research pipeline.

## Local setup

Requirements:

- Xcode 26.6 or newer with an iOS 26 SDK;
- an iPhone running iOS 26 or newer;
- an Apple development team available to Xcode; and
- bundle identifier `com.joshuawyadao.Honkshool` available to that team.

The command-line developer directory on this Mac currently points to Command Line Tools. Opening the project in Xcode uses the full toolchain. For terminal builds without changing the machine-wide setting, prefix commands with:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

Open `Honkshool.xcodeproj`, select the Honkshool target, choose the appropriate development team under Signing & Capabilities, select the connected iPhone, and run the shared `Honkshool` scheme. The repository does not store a development-team identifier, provisioning profile, or other signing material.

## Compile-time verification

Simulator-SDK build without signing:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Honkshool.xcodeproj \
  -scheme Honkshool \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/HonkshoolDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

Generic physical-device build without signing:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Honkshool.xcodeproj \
  -scheme Honkshool \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/HonkshoolDeviceDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

Compile the unit-test bundle when no compatible simulator runtime is installed:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Honkshool.xcodeproj \
  -scheme Honkshool \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/HonkshoolTestDerivedData \
  CODE_SIGNING_ALLOWED=NO build-for-testing
```

Compile success is not evidence that background narration or an alarm is reliable.

## Current validation status

Using Xcode 26.6 and the installed iOS 26.5 SDK:

- the app builds for the generic iOS Simulator SDK destination without signing;
- the app builds for the generic physical iOS device destination without signing;
- the unit-test bundle compiles with `build-for-testing`; and
- the repository verification suite passes.

The connected iPhone was visible to Xcode tooling but did not have usable Developer Disk Image support during this run. No compatible iOS simulator runtime is installed. Therefore the XCTest cases have compiled but have not executed, and every physical-device matrix result remains **Not run**. Open the project in Xcode, let it finish device preparation, select the development team, and rerun on the phone before resolving any feasibility decision.

## Physical-device test matrix

Use the iPhone 14 Pro running iOS 26.6.1 as the first baseline. Repeat critical acceptance checks on the replacement iPhone when available. Do not record serial numbers, UDIDs, personal alarm schedules, or private diagnostics in the public repository.

| Area | Test | Expected observation | Result |
| --- | --- | --- | --- |
| Authorization | Attempt an alarm-enabled run before authorizing AlarmKit. | Playback is blocked and no alarm promise is made. | Not run |
| Authorization | Deny AlarmKit, then retry an alarm-enabled run. | Playback remains blocked; disabling the alarm explicitly permits an audio-only test. | Not run |
| Alarm | Authorize, schedule the 60-second test, lock the phone, and background the app. | The system alarm fires near the displayed time. | Not run |
| Alarm | Stop and snooze the alert from system UI. | Stop dismisses it; snooze begins the configured countdown and alerts again. | Not run |
| Alarm | Schedule another test, terminate Honkshool, and wait. | The system alarm still fires; reopening the app reconciles its alarm state. | Not run |
| Alarm | Schedule and then cancel from Honkshool. | The system alarm is removed and does not fire. | Not run |
| Audio takeover | Play music or a podcast, then start an alarm-disabled spike run. | Existing audio yields when Honkshool activates its exclusive session. | Not run |
| Background narration | Start narration, lock the screen, and leave the app backgrounded. | Narration continues without an app prompt or unrelated audio. | Not run |
| Transition | Let the short narration complete with ambience enabled. | Generated neutral ambience starts once and loops quietly. | Not run |
| Silence | Repeat with ambience disabled. | Narration ends without starting another sound. | Not run |
| Remote controls | Use Lock Screen play, pause, and stop controls. | State and audio follow the command; skip and seek controls are absent. | Not run |
| Interruption | Invoke Siri or accept a call during narration. | Playback pauses, the event is logged, and the spike waits for manual resume. | Not run |
| Route change | Disconnect headphones during narration and ambience. | Playback pauses instead of unexpectedly moving to the speaker; the route event is logged. | Not run |
| Timing | Compare displayed start/wake time with narration completion and alarm firing. | Actual timings are recorded so planner slack can be decided later. | Not run |

## Recording results

For each test, record only:

- device model and public iOS version;
- pass, fail, or blocked;
- observed timing rounded to a useful precision;
- whether the screen was locked and the app foregrounded, backgrounded, or terminated; and
- a concise behavior note or reproducible failure.

Resolve or refine decisions D-001 through D-005 in the [decision log](Decision-Log.md) only after the relevant physical-device evidence exists. Keep Phase 0 unchecked in the [project implementation plan](Project-Implementation-Plan.md) until the exit criteria are met.
