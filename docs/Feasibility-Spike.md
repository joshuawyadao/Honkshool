# Audio and alarm feasibility spike

## Purpose

This spike tests the riskiest Honkshool assumptions before they become production architecture. It is a diagnostic console, not the intended product interface and not a supported release.

The current candidate implementation exercises:

- prepared offline Kokoro George narration with AVAudioPlayer, while retaining direct AVSpeechSynthesizer as historical regression coverage;
- an exclusive AVAudioSession playback category;
- locked-screen background audio capability;
- a transition to generated neutral noise or silence;
- pause/resume media commands and in-app Stop with Now Playing metadata;
- interruption and audio-route event logging on a separate diagnostics screen;
- AlarmKit authorization, fixed-date scheduling, cancellation, system stop, and a nine-minute countdown-style snooze;
- snooze countdown presentation on the Lock Screen and Dynamic Island, plus current alarm state on foreground return;
- strict blocking with a visible explanation when an alarm-enabled run is not authorized or cannot be scheduled; and
- recommended, custom, exact-wake-time, and reusable-default rest timing; and
- a captured deadline that stops prepared narration or following ambience without changing the system alarm.

The generated noise exists only to test the transition and background audio path. It is not the lawful ambience asset intended for the prototype catalog. Narration now uses the complete reviewed **Turning Fuel Into Motion** session, prepared with Kokoro George at model speed `0.86`. The app bundles the verified PCM file and its provenance rather than the model or a live synthesis runtime.

## Prepared narration slice, 2026-09-21

The catalog resolves `Turning-Fuel-Into-Motion-George.wav` by resource name and records its exact 727.625-second duration and SHA-256. Start visibly fails if catalog or audio loading fails; there is no Apple-voice fallback. AVAudioPlayer exposes pause/resume and completion while the existing controller owns the exclusive audio session, route and interruption policy, remote commands, Now Playing metadata, ambience/silence transition, and Stop behavior.

The run captures its planned wake deadline before playback. An injected clock lets the controller schedule only the time remaining after audio setup and refuse playback if setup has already passed wake. It also checks the deadline before resume and natural-completion transitions in case the scheduled callback is delayed. The scheduler stops either prepared narration or subsequent ambience at the fixed date when the app can execute; iOS scheduling may still deliver a callback late while the process is suspended. Stop and replacement invalidate the run identity and deadline task before touching AVFoundation, so a late completion callback cannot start ambience for an old run. This console records events but does not persist partial position or mark sessions complete; the production Nap Plan/history adapter must use the domain completion rules later.

The complete asset is 34,926,044 bytes versus 327,212,226 bytes for the pinned model checkpoint alone. Preparation-time generation is the selected prototype architecture under D-024. It preserves exact audio and duration, avoids inference latency and power use during a nap, and requires no network. See [Audio-Preparation.md](Audio-Preparation.md) for fingerprints and reproduction steps.

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

The prepared-narration slice adds bundled-asset/catalog checks and injected controller tests for loading, pause/resume, natural completion, stale callbacks, invalid deadlines, narration cutoff, and ambience cutoff. On 2026-09-21, all 31 repository verification tests and all 134 iOS simulator tests passed with zero failures or skips. Strict Swift formatting, `git diff --check`, and unsigned Release builds for both the generic simulator and generic physical-device target also passed. A current physical iPhone was unavailable during implementation, so the earlier AVSpeechSynthesizer device evidence must not be presented as proof of the new AVAudioPlayer asset path.

On 2026-09-22, all 31 repository checks passed again and the complete iOS 26.5 iPhone 17 Pro simulator suite passed 134 tests with zero failures or skips. A separate complete-suite attempt on the iOS 27.0 iPhone 18 Pro Max simulator stopped making progress during Xcode's test-session cleanup; it produced no final result bundle and was interrupted after about ten minutes. That attempt remains inconclusive, not a reported assertion failure. After shutting down the other simulator and freshly booting the same iOS 27.0 destination, the full suite passed 134 tests with zero failures or skips using the same test script and derived-data path. The stall did not recur, so its cause is unknown; the successful retry is evidence for the iOS 27.0 simulator, not proof of real locked audio or alarm behavior. The two focused physical iOS 27.0 UI tests and the owner's Lock Screen report are recorded in the manual acceptance section below.

Xcode prepared support symbols for the connected iPhone 14 Pro running iOS 26.6.1, selected it as the run destination, registered it for the active Personal Team, and completed a device build. After Developer Mode and explicit developer-profile trust were enabled on the phone, the signed app installed and launched successfully. The owner subsequently exercised the chat checklist and reported the results below. Unannotated checklist steps are treated as user-reported passes; the original results remain recorded separately from the repaired-device results.

## Physical-device test matrix

The iPhone 14 Pro running iOS 26.6.1 is the historical first baseline. The current acceptance target is the iPhone 18 Pro Max running iOS 27.0. Do not record serial numbers, UDIDs, personal alarm schedules, or private diagnostics in the public repository.

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
- Start and Resume are unavailable while a system interruption is active. An interruption cancels any queued resume; its end only re-enables explicit manual recovery and never resumes automatically. Stop does not bypass this gate.
- Initial audio-activation failure shows a blocking explanation instead of announcing that playback started. Any successfully scheduled wake alarm stays active and the alert explicitly explains how to cancel it; deterministic UI tests cover alarm-enabled and alarm-disabled failures.
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
- The Lock Screen layout places cancellation beside the activity title, pairs snooze state with the countdown, and gives the next-alert time a full-width row. It keeps Apple’s 14-point horizontal margin and does not cap Dynamic Type. CI exposed a 179-point overflow for a longer US/UTC time label; the regression now checks US/UK locales and three time-zone offsets through the first accessibility text size against the unchanged 160-point ceiling.

Apple requires a Live Activity for alarm countdown functionality; its countdown presentation includes the authoritative fire date. Apple also notes that the system may truncate a Live Activity above 160 points and specifies a 14-point Lock Screen margin. See [AlarmKit countdown guidance](https://developer.apple.com/videos/play/wwdc2025/230/), [countdown fireDate](https://developer.apple.com/documentation/alarmkit/alarmpresentationstate/mode-swift.enum/countdown/firedate), and [Live Activity layout guidance](https://developer.apple.com/design/human-interface-guidelines/live-activities).

Run the complete automated app and UI suite on an installed simulator:

```sh
./scripts/test-ios.sh
```

The script prints a fresh result-bundle path for every run and prints failed assertions from that bundle while preserving Xcode's failure exit code. The final local PR-repair run passed 55 tests (42 unit/controller/service/layout and 13 UI); repository checks and Release compilation also passed. Raw device diagnostics and result bundles remain local, not committed.

Set `HONKSHOOL_TEST_DESTINATION` when the default latest iPhone 17 Pro simulator is unavailable. Pull requests run the same command on GitHub's macOS 26 runner. Debug-only launch fixtures exercise not-determined, denied, authorized, scheduling-failed, snoozed, paused, alerting, and unavailable alarm states without showing a system permission prompt or creating an alarm. UI tests start the bundled prepared file and exercise Stop and pause/resume without waiting for natural completion. These substitutes verify Honkshool logic and UI only; they do not prove that iOS delivers audio or alarms while locked.

UI-test launches use a dedicated preferences suite for fake alarm identity and saved duration, shared by the fixture setup, alarm service, and duration UI. Ordinary launches and Release builds retain standard preferences. This prevents a simulator or physical-device test from overwriting the real app's tracked alarm or saved default. A storage-isolation regression supplements the existing saved-duration relaunch UI test.

The PR review safeguards were validated on 2026-09-15 with Xcode 27.0 against the installed iOS 26.5 iPhone 17 Pro simulator, plus an unsigned Release simulator build, strict formatting, and all 12 repository checks. The final suite includes test-storage isolation, alarm-disabled cancellation, terminal reset state, audio reactivation, and ambience-engine recovery regressions. One run was blocked by simulator launch preflight errors; booting the simulator to readiness and rerunning passed. On machines with newer runtimes, select this baseline explicitly with `HONKSHOOL_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' ./scripts/test-ios.sh`; the default `OS=latest` may have no matching iPhone 17 Pro. This does not replace the earlier physical alarm evidence or imply iOS 27 device acceptance.

## Minimal physical-device acceptance

The original AlarmKit and direct-speech milestone was completed on 2026-09-15. Prepared George audio uses AVAudioPlayer and a 34.9 MB bundled file instead of AVSpeechSynthesizer. On 2026-09-22, the app installed and launched on the iPhone 18 Pro Max running iOS 27.0. Two focused UI tests passed there with fake AlarmKit fixtures: in-app pause/resume/Stop and alarm-enabled scrolling/Stop behavior. Those tests neither requested alarm permission nor scheduled a real alarm. The owner separately reported that George continued while locked and that Lock Screen play/pause worked. This is a user-reported pass for those controls, not for the checks below.

### Manual checks to do later on iPhone 18 Pro Max / iOS 27.0

The time-consuming technical checks can run unattended. Simulator tests verify every bundled George PCM frame can be read by AVFoundation, and a real AVAudioPlayer reaches the file's natural ending, starts generated ambience, and stops it when the injected fixed deadline fires. Existing tests cover interruption and route-loss policy, disabled seek, alarm gating, and deadline math. A separate opt-in physical-device test now covers real AlarmKit alerting alongside narration cutoff. None of these checks proves headphone routing or whether the voice feels comfortable to a listener.

Only brief physical and listening checks remain. Record pass/fail and a short observation using the fields below; leave any unperformed item pending.

- [x] **Locked playback and Lock Screen play/pause:** Owner reported on 2026-09-22 that George kept playing when locked and followed Lock Screen play/pause. The focused device UI tests independently covered in-app pause/resume/Stop, but did not test the locked screen.
- [ ] **Quick controls and route check (about two active minutes):** With **Require a wake alarm** off, start a 20-minute window while wearing AirPods; do not wait for the window to end. Confirm Lock Screen seek/skip cannot be used. Invoke Siri and verify narration pauses until manually resumed. Disconnect AirPods and verify audio pauses rather than moving to the speaker. Reconnect and use Lock Screen Stop to end audio.
- [x] **Real alarm state and narration cutoff:** On 2026-09-23, the opt-in XCTest passed on iPhone 18 Pro Max / iOS 27.0: one pass, zero failures, zero skips. It scheduled a real AlarmKit alarm and started the bundled George audio with the same 75-second deadline. AlarmKit entered `alerting` within five seconds of wake, prepared narration stopped within three seconds, and the status identified the wake deadline. The test cleaned up its alarm. The owner separately reported that the alarm rang as expected. Locked-screen presentation was not reported.
- [x] **Brief opening voice check:** During that short device run, the owner reported that George narration sounded clear and natural. This covers the beginning of the bundled session, not its middle or ending.
- [ ] **Longer-form voice comfort:** The optional 86-second opening/middle/ending reel made by `python3 scripts/make-george-review-reel.py` can expose representative later passages. Full-session subjective comfort remains unassessed until natural use; no 12-minute attentive listen is required for this technical follow-up.

The former five-minute combined deadline run and 15-minute attentive playback run are no longer interactive checklist items. Simulator checks cover app-controlled timing and transition rules, and the opt-in iPhone test has now verified simultaneous AlarmKit alerting and narration cutoff. No automated check certifies every spoken word's subjective quality. Controller tests also cover natural completion into silence.

To run the gated real-alarm check on a connected iPhone after authorizing Honkshool alarms, use:

```sh
TEST_RUNNER_HONKSHOOL_REAL_ALARM_TEST=1 xcodebuild \
  -project Honkshool.xcodeproj -scheme Honkshool \
  -destination 'platform=iOS,id=<connected-device-id>' \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:HonkshoolTests/RealAlarmCutoffDeviceTests test
```

The environment prefix passes the opt-in flag to the XCTest runner. The test skips in normal runs and on simulators, never requests authorization, and uses a unique alarm ID so it does not replace the console's tracked alarm. It can verify AlarmKit state and playback timing, but it cannot assess how loud the alarm sounds to a person or whether the full narration remains soothing. The owner may judge complete-session comfort during a normal nap rather than a dedicated test listen.
If the test runner is interrupted during the alert, dismiss the one-time Honkshool alarm on the phone.

On 2026-09-23, the full iOS 27 simulator suite passed 135 tests, but Xcode spent several minutes collecting optional `simctl diagnose` data after tests had finished. A later focused invocation that omitted `-collect-test-diagnostics never` stalled during cleanup; a process sample showed Xcode waiting inside `XCTHRunDestinationAllocator.collectSimulatorDiagnostics`, with no active test runner. After stopping that invocation and rebooting the iOS 27 simulator, the same focused tests passed 29/29 in 34 seconds with diagnostics disabled. This identifies the blocking cleanup operation, though not why Xcode entered it on that run. The local test script disables verbose diagnostics by default; CI opts back into failure diagnostics with `HONKSHOOL_TEST_DIAGNOSTICS=on-failure`. The result bundle and ordinary failure summary remain available locally.

PR #4's deadline and Now Playing follow-up passed 141 iOS 27 simulator tests with zero failures and one intentionally skipped real-device test, plus 31 repository checks, strict Swift formatting, and an unsigned Release simulator build. The focused controller and catalog-failure UI run passed 29 tests. The prepared-audio controller now subtracts setup time from the wake interval and checks the fixed deadline before start, resume, and natural-completion transitions; this does not guarantee a suspended iOS process will execute a timer at the exact wall-clock instant.

The earlier physical confirmation is retained as historical evidence, not represented as a test of prepared playback. A separate real-call check remains optional. No model inference, download, thermal, or synthesis-latency test is needed for this architecture because the phone only decodes a bundled PCM file.

## Production Nap Plan alarm acceptance

The production Nap Plan flow now schedules a separately tracked AlarmKit wake alarm before an alarm-requested run starts. Its deterministic simulator tests exercise permission denial, scheduling and readback failure, exact deadline binding, cancellation, and relaunch reconciliation. The earlier real-alarm cutoff test exercised the feasibility controller. The new integrated device test below passed on iPhone 18 Pro Max / iOS 27.0 on 2026-09-25: one pass, zero failures or skips, with a real system alert within five seconds of the fixed deadline and the production run controller's audio cutoff within three seconds. The test did not lock the phone or assess audible loudness.

An opt-in XCTest uses the production alarm service and run controller with a short test-only planning estimate. It schedules a real one-shot alarm for the same 90-second window as prepared narration, checks that both the system alert and audio cutoff occur near the fixed deadline, then cancels the test alarm. Run it only on the connected physical iPhone after authorizing Honkshool alarms:

```sh
TEST_RUNNER_HONKSHOOL_REAL_NAP_PLAN_ALARM_TEST=1 xcodebuild \
  -project Honkshool.xcodeproj -scheme Honkshool \
  -destination 'platform=iOS,id=<connected-device-id>' \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:HonkshoolTests/RealNapPlanAlarmDeviceTests test
```

The automated device test does not lock the screen, test the alarm's audible loudness, or assess long-form listening comfort; keep those manual checks separate.

On the target iPhone with a signed build, clear any older tracked Nap Plan alarm, then choose and confirm a plan with **Request a wake alarm** on. Start within the approved minute and check that the screen reports a system alarm scheduled before the run status changes to waiting or narrating. An authorized short silence-only plan can check the alarm alert and snooze/cancel path with little active listening time. For a simultaneous narration/cutoff check, choose a 13-minute window so the prepared 730-second estimate fits, keep the app foregrounded until narration begins, then lock the phone. At the fixed deadline, observe whether narration stops and the system alarm alerts; record actual timing and whether the phone was locked. Stop playback early in a separate run and confirm the wake alarm remains available for explicit cancellation. Force-quit/relaunch while an alarm is pending and verify that its identity and next alert state reconcile without creating a replacement. Record pass, fail, or blocked below; do not treat simulator fixtures as physical evidence.

Authorization messaging, scheduling failure, in-app Stop and pause/resume, active-alarm scrolling, event-log navigation, snooze/paused/ringing/unavailable presentation, cancellation routing, reusable duration persistence, exact-time control availability, and the Live Activity’s large-text height are automated. The renderer cannot reproduce Apple’s system-hosted card exactly; the owner’s visual confirmation is separate physical-device evidence. Repeat affected physical checks when audio/alarm behavior or the target device/OS changes. A separate real-call check, numerical narration-duration measurements, and accessibility sizes beyond the first accessibility setting are not covered by this closeout.

## Recording results

For each test, record only:

- device model and public iOS version;
- pass, fail, or blocked;
- observed timing rounded to a useful precision;
- whether the screen was locked and the app foregrounded, backgrounded, or terminated; and
- a concise behavior note or reproducible failure.

Phase 0 and the framework-independent Nap Plan core are complete. D-023 selects the George sound and D-024 connects a prepared version to this console. The next milestone is focused device acceptance followed by production plan-review, playback-progress, and history integration; this console is not a supported product release.
