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
- the compact-layout repair (`e398f6d`) and embedded snooze extension built with automatic signing, installed, and launched on that phone on 2026-09-15;
- the pre-automation baseline passed all 24 simulator tests;
- the expanded suite passes all 39 simulator tests: 30 unit/controller/service/layout tests and nine deterministic UI tests; and
- the same nine deterministic UI tests pass on the connected iPhone 14 Pro running iOS 26.6.2, using fixtures that do not request permission or create a real alarm; and
- all 12 repository verification tests, strict Swift formatting checks, the unsigned Release simulator build, and `git diff --check` pass.

Xcode prepared support symbols for the connected iPhone 14 Pro running iOS 26.6.1, selected it as the run destination, registered it for the active Personal Team, and completed a device build. After Developer Mode and explicit developer-profile trust were enabled on the phone, the signed app installed and launched successfully. The owner subsequently exercised the chat checklist and reported the results below. Unannotated checklist steps are treated as user-reported passes; the original results remain recorded separately from the repaired-device results.

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

### Repaired-device result, 2026-09-14

The owner completed both combined acceptance checks on the iPhone 14 Pro after the playback and AlarmKit repairs:

- locked narration, competing-audio takeover, Lock Screen pause/resume/Stop, Siri interruption, and headphone disconnection all passed;
- the real alarm fired while locked, snoozed with a matching in-app deadline, preserved that deadline across scrolling and force-quit/relaunch, fired again after the full nine-minute interval, and stopped successfully; and
- the only reported defect was visual: with larger text and standard Display Zoom, the snoozed Lock Screen Live Activity clipped its bottom **Cancel alarm** control. The alarm behavior itself passed.

## Repair implementation and focused retest

The Stop callback and live-stream metadata regressions were first run against the original code and both failed, then passed after repair. The UI test repeatedly reached the top during playback and after returning from diagnostics. Its initial final assertion used the wrong accessibility label (`Stopped` instead of the actual combined `Phase, Stopped`); that lookup was corrected without changing the expected stopped state. The owner’s repaired-device test subsequently confirmed alarm-enabled scrolling, Lock Screen controls, and the actual snooze re-ring.

- Speech callbacks now belong to one active utterance. Stop invalidates that utterance before asking AVFoundation to cancel it; completion or cancellation from an older run cannot transition a newer run.
- Resume requested before speech reaches its word-boundary pause is queued until the matching pause callback. Stop clears that request, so a late pause callback cannot restart audio.
- A media-services reset latches a relaunch requirement in every playback phase, including idle and stopped. Start, Resume, and toggle cannot reuse discarded audio objects, even after Stop. The console instructs the tester to relaunch before another run.
- Explicit Resume reactivates the exclusive audio session before continuing narration. For interrupted ambience it restarts a stopped engine when needed and always restores the loop, including route changes that purge the player queue while leaving the engine running. Activation or speech-resume failure enters a failed state without advertising playback. Adapter/controller regressions cover these paths; simulated interruption notifications are not a new real-call acceptance result.
- Narration and ambience advertise ordinary audio rather than live-stream metadata. Play, pause, and toggle commands are registered explicitly. iOS owns the exact Lock Screen layout; disabled skip/seek controls and the output selector are acceptable.
- A blocked Start presents **Test cannot start** with the reason. This is shown only in response to an explicit Start action.
- Starting an alarm-disabled run first cancels any tracked Honkshool alarm, including snooze. A cancellation failure blocks playback and explains that the previous alarm may still be active; disabling the requirement never silently leaves a prior wake alarm behind.
- Start snapshots the alarm and ambience choices and disables configuration controls while scheduling is pending, so a toggle change cannot contradict the alarm that is being created. A delayed-scheduler UI fixture exercises this in-flight state without real alarms.
- Before Start, duration mode displays a current “Wake if started now” estimate rather than a stale deadline. Scheduling/playback displays the captured “Run wake”; exact-time mode labels its fixed selection separately. The small preview updates independently without resizing the event log or polling AlarmKit.
- A new run cannot start while narration, ambience, or paused/interrupted playback is active. Stop playback first; only then may a new run replace its alarm. This prevents old audio continuing after its alarm is removed during a failed replacement.
- The main page uses an eager duration layout. The live diagnostic list has stable event identities and its own **Audio event log** screen, so new rows do not resize the main page while it is being scrolled.
- Alarm status follows system updates and refreshes while the app is foregrounded. The original fixed alarm date is never displayed as a snooze deadline. Cancellation failures retain the alarm ID and prevent replacing it until cancellation succeeds.
- Foreground polling runs only while a tracked snooze is missing its ActivityKit deadline, with five one-second retries followed by 30-second backoff. It stops when the deadline is found, the alarm state changes, or the app leaves the foreground; idle and scheduled alarms rely on system updates and a foreground-entry refresh.
- The app and new `HonkshoolAlarmWidget` extension share alarm metadata. The Live Activity shows snooze state, the system's next alert time, a countdown, and cancellation. If the precise countdown deadline has not arrived from ActivityKit, the app says it is unavailable instead of inventing a new nine-minute interval.
- The Lock Screen layout places cancellation beside the activity title and arranges snooze details beside the countdown. It keeps Apple’s 14-point horizontal margin, does not cap Dynamic Type, and stays within the 160-point Live Activity ceiling through the first accessibility text size in the renderer regression.

Apple requires a Live Activity for alarm countdown functionality; its countdown presentation includes the authoritative fire date. Apple also notes that the system may truncate a Live Activity above 160 points and specifies a 14-point Lock Screen margin. See [AlarmKit countdown guidance](https://developer.apple.com/videos/play/wwdc2025/230/), [countdown fireDate](https://developer.apple.com/documentation/alarmkit/alarmpresentationstate/mode-swift.enum/countdown/firedate), and [Live Activity layout guidance](https://developer.apple.com/design/human-interface-guidelines/live-activities).

Run the complete automated app and UI suite on an installed simulator:

```sh
./scripts/test-ios.sh
```

Set `HONKSHOOL_TEST_DESTINATION` when the default latest iPhone 17 Pro simulator is unavailable. Pull requests run the same command on GitHub's macOS 26 runner. Debug-only launch fixtures exercise not-determined, denied, authorized, scheduling-failed, snoozed, paused, alerting, and unavailable alarm states without showing a system permission prompt or creating an alarm. Deterministic speech makes Stop and pause/resume tests fast. These substitutes verify Honkshool logic and UI only; they do not prove that iOS delivers audio or alarms while locked.

UI-test launches use a dedicated preferences suite for fake alarm identity and saved duration, shared by the fixture setup, alarm service, and duration UI. Ordinary launches and Release builds retain standard preferences. This prevents a simulator or physical-device test from overwriting the real app's tracked alarm or saved default. A storage-isolation regression supplements the existing saved-duration relaunch UI test.

The PR review safeguards were validated on 2026-09-15 with Xcode 27.0 against the installed iOS 26.5 iPhone 17 Pro simulator, plus an unsigned Release simulator build, strict formatting, and all 12 repository checks. The final suite includes test-storage isolation, alarm-disabled cancellation, terminal reset state, audio reactivation, and ambience-engine recovery regressions. One run was blocked by simulator launch preflight errors; booting the simulator to readiness and rerunning passed. On machines with newer runtimes, select this baseline explicitly with `HONKSHOOL_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' ./scripts/test-ios.sh`; the default `OS=latest` may have no matching iPhone 17 Pro. This does not replace the earlier physical alarm evidence or imply iOS 27 device acceptance.

## Minimal physical-device acceptance

All requested checks for this feasibility milestone are complete. On 2026-09-15, after installation of the compact Live Activity repair, the owner confirmed that the snoozed Lock Screen card fits correctly at the existing larger text setting with standard Display Zoom. No additional manual test is required for this documentation-only closeout.

Authorization messaging, scheduling failure, in-app Stop and pause/resume, active-alarm scrolling, event-log navigation, snooze/paused/ringing/unavailable presentation, cancellation routing, reusable duration persistence, exact-time control availability, and the Live Activity’s large-text height are automated. The renderer cannot reproduce Apple’s system-hosted card exactly; the owner’s visual confirmation is separate physical-device evidence. Repeat affected physical checks when audio/alarm behavior or the target device/OS changes. A separate real-call check, numerical narration-duration measurements, and accessibility sizes beyond the first accessibility setting are not covered by this closeout.

## Recording results

For each test, record only:

- device model and public iOS version;
- pass, fail, or blocked;
- observed timing rounded to a useful precision;
- whether the screen was locked and the app foregrounded, backgrounded, or terminated; and
- a concise behavior note or reproducible failure.

Phase 0 is complete: the [decision log](Decision-Log.md) accepts D-001, D-002, D-003, and D-005 and explicitly defers D-004 with a safe fallback. The next milestone is the nap-planning core after this branch is reviewed and merged; this console is not a supported product release.
