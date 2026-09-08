# Audio and alarm feasibility spike

## Purpose

This spike tests the riskiest Honkshool assumptions before they become production architecture. It is a diagnostic console, not the intended product interface and not a supported release.

The current candidate implementation exercises:

- direct on-device narration with AVSpeechSynthesizer;
- an exclusive AVAudioSession playback category;
- locked-screen background audio capability;
- a transition to generated neutral noise or silence;
- pause/resume media commands and in-app Stop with Now Playing metadata;
- interruption and audio-route event logging on a separate diagnostics screen;
- AlarmKit authorization, fixed-date scheduling, cancellation, system stop, and a nine-minute countdown-style snooze;
- snooze countdown presentation on the Lock Screen and Dynamic Island, plus current alarm state on foreground return;
- strict blocking with a visible explanation when an alarm-enabled run is not authorized or cannot be scheduled; and
- recommended, custom, exact-wake-time, and reusable-default rest timing.

The generated noise exists only to test the transition and background audio path. It is not the lawful ambience asset intended for the prototype catalog. The short “Turning Fuel Into Motion” script is likewise provisional and has not passed the future content-research pipeline.

## Local setup

Requirements:

- Xcode 26.6 or newer with an iOS 26 SDK;
- the matching iOS Simulator/platform component installed in Xcode;
- an iPhone running iOS 26 or newer;
- an Apple development team available to Xcode; and
- bundle identifiers `com.joshuawyadao.Honkshool` and `com.joshuawyadao.Honkshool.AlarmWidget` available to that team.

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
- the original signed Debug app installed and launched on the iPhone 14 Pro after Developer Mode and profile trust were enabled;
- the repair app and embedded snooze extension build with automatic signing and install successfully on that phone; its locked screen prevented the automated launch attempt, so open Honkshool after unlocking;
- all 24 simulator tests pass: 22 model/controller/alarm-service tests and two UI tests, with no failures or skips; and
- all 10 repository verification tests, strict Swift formatting checks, and `git diff --check` pass.

Xcode prepared support symbols for the connected iPhone 14 Pro running iOS 26.6.1, selected it as the run destination, registered it for the active Personal Team, and completed a device build. After Developer Mode and explicit developer-profile trust were enabled on the phone, the signed app installed and launched successfully. The owner subsequently exercised the chat checklist and reported the results below. Unannotated checklist steps are treated as user-reported passes; the repair build still needs the focused device retest.

## Physical-device test matrix

Use the iPhone 14 Pro running iOS 26.6.1 as the first baseline. Repeat critical acceptance checks on the replacement iPhone when available. Do not record serial numbers, UDIDs, personal alarm schedules, or private diagnostics in the public repository.

Results below are the owner's report from the original build on iPhone 14 Pro / iOS 26.6.1. They are distinct from automated regression results and have not been silently changed to passes after code fixes.

| Area | Expected behavior | Original device result / follow-up |
| --- | --- | --- |
| Authorization gate | No narration until permission and scheduling succeed; explain a blocked Start. | Blocking passed; explanation was not apparent. Visible alert added; retest. |
| Explicit denial | Denied permission blocks alarm-enabled playback; audio-only remains available. | Denial was not a separate step in the chat checklist; automated gating coverage retained. |
| Locked alarm | A 60-second alarm fires while the app is backgrounded and the screen locked. | User-reported pass. |
| Alarm Stop | Stop dismisses the alert. | User-reported pass. |
| Snooze | Show Snoozed, next alert time, and countdown; ring again after nine minutes. | Feedback failed: original alarm time remained visible. Owner cancelled before nine minutes, so repeat ringing is untested. |
| Terminated app | A scheduled alarm still fires after force-quitting Honkshool; relaunch reconciles state. | User-reported pass for the unsnoozed alarm. |
| Alarm cancellation | Cancel removes the scheduled alarm and it does not fire. | User-reported pass. Retest cancellation during snooze. |
| Audio takeover | Existing music/podcast yields to Honkshool. | User-reported pass. |
| Locked narration | Narration continues while locked/backgrounded. | User-reported pass. |
| Natural completion | Narration ends in generated ambience or silence according to the chosen option. | User-reported pass for both choices. |
| Playback Stop | Stop immediately ends all Honkshool audio; it does not cancel the wake alarm. | Failed: Stop skipped narration and started ambience. Callback guard added; retest in app and through any offered system Stop. |
| Lock Screen controls | Usable pause/resume; skip and seek must be noninteractive. | Failed: central control was Stop, without pause/resume. Skip/seek were visible but disabled, which satisfies the functional requirement. |
| Interruption | Siri pauses playback; manual resume is required and events are logged. | User-reported pass. A real call remains a separate optional check. |
| Headphone disconnection | Pause narration/ambience rather than move unexpectedly to the speaker. | User-reported pass. |
| Alarm-enabled start | Confirm scheduling before narration begins. | User reported scheduling as expected. |
| Scrolling | Scroll freely from the bottom to the top while the alarm/audio are active. | Failed: page jitter prevented returning to the top. Diagnostics isolated and eager duration layout added; device retest required. |
| Timing | Compare actual narration and alarm timings with the displayed window. | Timing behavior accepted in the chat checklist; numerical measurements were not supplied. |

## Repair implementation and focused retest

The Stop callback and live-stream metadata regressions were first run against the original code and both failed, then passed after repair. The UI test repeatedly reached the top during playback and after returning from diagnostics. Its initial final assertion used the wrong accessibility label (`Stopped` instead of the actual combined `Phase, Stopped`); that lookup was corrected without changing the expected stopped state. The exact alarm-enabled scrolling problem, Lock Screen controls, and actual snooze re-ring remain device-only retests, not claims established by simulator success.

- Speech callbacks now belong to one active utterance. Stop invalidates that utterance before asking AVFoundation to cancel it; completion or cancellation from an older run cannot transition a newer run.
- Narration and ambience advertise ordinary audio rather than live-stream metadata. Play, pause, and toggle commands are registered explicitly. iOS owns the exact Lock Screen layout; disabled skip/seek controls and the output selector are acceptable.
- A blocked Start presents **Test cannot start** with the reason. This is shown only in response to an explicit Start action.
- The main page uses an eager duration layout. The live diagnostic list has stable event identities and its own **Audio event log** screen, so new rows do not resize the main page while it is being scrolled.
- Alarm status follows system updates and refreshes while the app is foregrounded. The original fixed alarm date is never displayed as a snooze deadline. Cancellation failures retain the alarm ID and prevent replacing it until cancellation succeeds.
- The app and new `HonkshoolAlarmWidget` extension share alarm metadata. The Live Activity shows snooze state, the system's next alert time, a countdown, and cancellation. If the precise countdown deadline has not arrived from ActivityKit, the app says it is unavailable instead of inventing a new nine-minute interval.

Apple requires a Live Activity for alarm countdown functionality; its countdown presentation includes the authoritative fire date. See [AlarmKit countdown guidance](https://developer.apple.com/videos/play/wwdc2025/230/) and [countdown fireDate](https://developer.apple.com/documentation/alarmkit/alarmpresentationstate/mode-swift.enum/countdown/firedate).

Run the automated app and UI suite on an installed simulator:

Use a simulator where Honkshool's AlarmKit authorization has not been granted (or has been denied). The blocked-start UI test intentionally exercises that real system state; the suite never taps Authorize. Controller tests use deterministic speech and alarm substitutes, and cannot establish physical-device alarm reliability.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -quiet -project Honkshool.xcodeproj -scheme Honkshool \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /tmp/HonkshoolFixesDerivedData \
  -parallel-testing-enabled NO test
```

On the repaired iPhone build, concentrate on:

1. Start without alarm permission and confirm the explanation is visible. If permission is already granted, temporarily revoke it in iOS Settings, test, then restore it.
2. With the alarm explicitly disabled, start narration and press Stop midway. Remain in silence, then start again and test Lock Screen pause/resume. Repeat Stop during ambience.
3. Start an alarm-enabled run and scroll repeatedly between the bottom and top. Open **Audio event log**, return, and repeat.
4. Schedule a **60-second test**, lock the phone, and tap Snooze when it rings. Confirm a visible countdown on the Lock Screen; reopen Honkshool and confirm **Snoozed**, the same next alert time, and a decreasing countdown. Let all nine minutes elapse without cancelling or scheduling another test and confirm it rings again.
5. Repeat snooze, cancel it from the app or Live Activity, and confirm the alarm does not ring. During a separate snooze, force-quit/reopen and confirm the displayed deadline does not reset.

## Recording results

For each test, record only:

- device model and public iOS version;
- pass, fail, or blocked;
- observed timing rounded to a useful precision;
- whether the screen was locked and the app foregrounded, backgrounded, or terminated; and
- a concise behavior note or reproducible failure.

Resolve or refine decisions D-001 through D-005 in the [decision log](Decision-Log.md) only after the relevant physical-device evidence exists. Keep Phase 0 unchecked in the [project implementation plan](Project-Implementation-Plan.md) until the exit criteria are met.
