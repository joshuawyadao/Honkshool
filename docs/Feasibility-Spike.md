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
- the matching iOS Simulator/platform component installed in Xcode;
- an iPhone running iOS 26 or newer;
- an Apple development team available to Xcode; and
- bundle identifier `com.joshuawyadao.Honkshool` available to that team.

The command-line developer directory on this Mac currently points to Command Line Tools. Opening the project in Xcode uses the full toolchain. For terminal builds without changing the machine-wide setting, prefix commands with:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

The shared Xcode configuration loads `Config/Local.xcconfig` when it exists. Create that ignored file once per checkout:

```sh
cp Config/Local.xcconfig.example Config/Local.xcconfig
```

Replace `YOUR_TEAM_ID` with the 10-character Team ID shown in Xcode under **Settings → Apple Accounts**. Do not commit the local file. The repository stores only the placeholder template; it does not store a development-team identifier, device identifier, provisioning profile, certificate, or account detail.

If Xcode reports that the bundled iOS platform is not installed, use **Xcode → Settings → Components** or install the currently available component from Terminal:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -downloadPlatform iOS
```

For a newly connected phone:

1. Unlock the iPhone, connect it by cable, and accept any **Trust This Computer** prompt.
2. Open `Honkshool.xcodeproj`, select the shared `Honkshool` scheme and the phone as the run destination, then press Run once. Xcode can register the phone and prepare device support through automatic signing.
3. When Xcode requests it, enable **Settings → Privacy & Security → Developer Mode** on the iPhone, accept the restart, unlock it, and confirm **Turn On**.
4. Keep the phone unlocked and connected, then press Run again. Accept the iPhone prompt to trust the developer if iOS presents one.

Developer Mode and device trust are security settings controlled on the iPhone; they cannot be silently enabled by this project.

After the first successful Xcode run, a signed command-line build can be reproduced without exposing the team or device identifier:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -quiet \
  -project Honkshool.xcodeproj \
  -scheme Honkshool \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/HonkshoolDeviceDerivedData \
  -allowProvisioningUpdates \
  build
```

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

Using Xcode 26.6, the iOS 26.5 SDK, and the installed iOS 26.5 simulator/platform component:

- the app builds for the generic iOS Simulator SDK destination without signing;
- the app builds for the generic physical iOS device destination without signing;
- automatic signing resolves through an ignored local configuration and produces a signed Debug device build;
- the signed Debug app installs and launches in the foreground on the iPhone 14 Pro after Developer Mode and profile trust are enabled;
- all eight focused XCTest cases execute successfully on an iOS 26.5 simulator; and
- the repository verification suite passes.

Xcode prepared support symbols for the connected iPhone 14 Pro running iOS 26.6.1, selected it as the run destination, registered it for the active Personal Team, and completed a device build. After Developer Mode and explicit developer-profile trust were enabled on the phone, the signed app installed and launched successfully. Every behavior-focused physical-device matrix result remains **Not run**; successful installation and launch do not resolve any audio or AlarmKit feasibility decision.

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
