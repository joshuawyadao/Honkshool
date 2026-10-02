# Getting started

[Documentation index](README.md) · [User guide](User-Guide.md) · [Troubleshooting](Troubleshooting.md)

Honkshool is an experimental source app. There is no supported release or documented public App Store/TestFlight installation path. These instructions let a contributor or willing tester build it in Xcode. They do not establish that a particular phone, audio route, or alarm setup has passed acceptance.

## What you need

| To do this | You need |
| --- | --- |
| Read or change documentation; run repository checks | Git, a shell, and Python 3; no iPhone or Apple account |
| Build and explore the app in Simulator | A Mac that runs Xcode 26.6 or newer, with compatible iOS platform and simulator components installed |
| Run on your iPhone | The above, an iPhone on iOS 26 or newer, and an Apple development team available in Xcode for signing |

The deployment target is iOS 26.0. The documented toolchain baseline is Xcode 26.6; a newer phone OS may need newer Xcode/device support. Simulator tests cannot establish real alarm audibility, Lock Screen controls, or headphone behavior.

The repository already includes both prepared narration files and Gentle rain. Building and listening do not require Python audio packages, downloaded voices, Kokoro, a paid API, or an account in Honkshool. Installing Xcode/components and setting up Apple signing may require a network connection.

## Open a local copy

```sh
git clone https://github.com/joshuawyadao/Honkshool.git
cd Honkshool
open Honkshool.xcodeproj
```

Contributors can clone their own fork instead. In Xcode, select the shared **Honkshool** scheme. Let Xcode finish installing any required platform components.

## Explore with a simulator

1. Select an installed iPhone simulator running iOS 26 or newer as the run destination.
2. Press **Run** (Command-R).
3. Dismiss the first-launch welcome screen to reach **Rest**. Choose duration, sound, and wake alarm, then tap **Start resting**. Use **Plan a narrated rest** for prepared sessions. **History** is the other tab; **Feasibility Lab** is under **Settings → Advanced**.
4. Follow the [user guide](User-Guide.md). Turn **Wake alarm** off when exploring without a physical alarm test.

You do not need to set a development-team identifier for an unsigned simulator build. For command-line builds and automated tests, use [Development](Development.md#verification).

## Install a development build on an iPhone

1. In Xcode's **Settings → Apple Accounts**, add your Apple account and confirm an available development team.
2. From the repository root, create the ignored local signing file:

   ```sh
   cp Config/Local.xcconfig.example Config/Local.xcconfig
   ```

   Do this only if you have not already configured that file. Replace `YOUR_TEAM_ID` with your own 10-character Team ID. The shared configuration applies it to the app, widget, and test targets. Keep this file private.
3. Select the **Honkshool** project and check **Signing & Capabilities** for the app and **HonkshoolAlarmWidget** targets. Automatic signing must resolve for your team. The repository uses `com.joshuawyadao.Honkshool` and `com.joshuawyadao.Honkshool.AlarmWidget`; those identifiers may not be available to another team. For a personal fork, use a unique app identifier and an extension identifier beneath it, such as `com.example.yourname.Honkshool` and `com.example.yourname.Honkshool.AlarmWidget`. Keep personal signing edits out of unrelated pull requests. Apple explains [App ID registration](https://developer.apple.com/help/account/identifiers/register-an-app-id/).
4. Connect and unlock the iPhone. Accept **Trust This Computer** if prompted. Select the phone as Xcode's run destination and press **Run**.
5. If requested, enable **Settings → Privacy & Security → Developer Mode** on the phone, complete its restart/confirmation, and run again. Follow Apple's [Developer Mode instructions](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device). Accept any developer-trust prompt on the phone.
6. When the app launches, dismiss the welcome screen if shown and use **Rest** to set a timer and sound on one screen. An alarm-enabled start requests iOS alarm permission if needed. Approve it only if you want Honkshool to schedule the selected wake alarm.

Signing failures are setup problems, not evidence that playback failed. Check Xcode's specific message and the [troubleshooting guide](Troubleshooting.md#build-and-installation). A development build is not a supported distribution channel; Xcode and your signing profile govern its continued availability.

## Before ordinary use

Make a short, deliberate check while awake: locate the audio controls, confirm the displayed alarm choice, and learn how to cancel a scheduled alarm. **Stop playback does not cancel the wake alarm.** Keep the app open until playback begins; for silence-only plans with no narration, wait for the visible rest-until-deadline state.

Use the [user guide](User-Guide.md) for a full walkthrough and the [feasibility guide](Feasibility-Spike.md#physical-device-test-matrix) for repeatable device checks. The [ten-nap trial](Ten-Nap-Trial.md) is a separate personal evaluation, with observations kept outside public Git history.
