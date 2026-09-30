# Honkshool

[![Repository Verify](https://github.com/joshuawyadao/Honkshool/actions/workflows/ci.yml/badge.svg)](https://github.com/joshuawyadao/Honkshool/actions/workflows/ci.yml)
[![Project status: experimental prototype](https://img.shields.io/badge/status-experimental%20prototype-5b4d8a)](docs/Project-Overview.md)
[![Code license: MIT](https://img.shields.io/badge/code%20license-MIT-blue.svg)](LICENSE)

**Calm stories about how things work, with time left to rest.**

Honkshool is an early-stage iPhone app for calm, uninterrupted factual narration during naps and bedtime. Choose a topic and a rest window, approve what will play, then listen as narration gives way to rain or silence. Relaxation comes first; interesting information is secondary.

> **Project status:** Feasibility spike plus an early Nap Plan playback flow; there is no supported release. This repository provides source code for contributors and willing testers. Installation currently requires a Mac and Xcode; there is no public App Store or TestFlight installation path documented here.

[Set up the prototype](docs/Getting-Started.md) · [Use the app](docs/User-Guide.md) · [Troubleshooting](docs/Troubleshooting.md) · [All documentation](docs/README.md)

## What can I listen to?

The bundled **How a Car Works** journey has two original, citation-backed sessions, spoken by the prepared Kokoro George voice:

| Session | Narration length | Topic |
| --- | --- | --- |
| **1. Turning Fuel Into Motion** | About 12 minutes | How an engine turns fuel into movement |
| **2. Air, Fuel, and Spark** | About 13 minutes | How air, fuel, and ignition work together |

A longer plan can include both sessions. A short window may contain only rain or silence; the review tells you exactly what fits. Narration plays at its prepared pace. **The rest window is the whole plan, not a promise of time asleep.**

- **Offline playback:** narration and Gentle rain are bundled with the app. No account or streaming service is needed.
- **Your rest sound:** Silence is the default. Gentle rain appears when its bundled file validates; unavailable rain falls back visibly to silence.
- **Optional wake alarm:** request an iOS system alarm for the plan's fixed deadline. Alarm-enabled playback is blocked if permission or scheduling fails.
- **Local listening history:** Continue, Resume, or Replay by reviewing a new plan. Reopening the app never starts audio automatically.

Honkshool describes sessions as **played**. It does not claim subconscious learning, guaranteed retention, therapy, or treatment of insomnia or another medical condition.

## Your first Nap Plan

![Four steps: open the Nap Plan from Feasibility Lab, choose content and rest options, review and confirm, then start resting and keep the app open until playback begins.](docs/assets/first-nap.svg)

1. Open Honkshool. On **Feasibility Lab**, scroll to **Nap Plan** and tap **Choose and review a Nap Plan**.
2. Choose a session, rest duration or exact wake time, **Silence** or **Gentle rain**, and whether to **Request a wake alarm**.
3. Tap **Review Nap Plan**. Check the planned start, fixed wake deadline, complete narration route, sound, and alarm choice; tap **Confirm reviewed plan**.
4. Tap **Start resting** before the approved start passes. Keep Honkshool on screen until narration or rain begins, then you can lock the phone. For a silence-only plan with no narration, wait for the visible rest-until-deadline state instead.

The app still opens on an experimental test console. Its **Background audio** and test-alarm controls are separate from Nap Plans. The [user guide](docs/User-Guide.md) walks through controls, history, and interrupted runs.

## Audio and the wake alarm are separate

![Audio and alarm have separate controls: Stop playback ends audio, while the optional scheduled wake alarm remains active until explicitly cancelled. Both use the reviewed fixed deadline.](docs/assets/audio-and-alarm.svg)

| I want to… | Use… | What happens |
| --- | --- | --- |
| Pause or continue listening | **Pause playback** / **Resume playback** | The fixed deadline stays the same. |
| End listening early | **Stop playback** | Audio stops; a scheduled wake alarm stays active. |
| Remove the wake alarm | **Cancel wake alarm** after playback stops, or **Cancel Nap Plan wake alarm** on Feasibility Lab | Cancels the separately tracked alarm. Check the displayed result. |
| Listen again later | **Listening History** → **Continue**, **Resume**, or **Replay** | Opens a fresh plan for review; nothing starts by itself. |

Audio is intended to end at the fixed deadline even when no alarm is requested. App execution and system scheduling can affect timing; automated passes are not a guarantee of waking. See [current evidence and limitations](docs/Project-Overview.md#current-state).

## Try it or contribute

You need **Xcode 26.6 or newer with compatible iOS platform support**. The app targets **iOS 26 or newer**. A simulator is enough to explore the UI; a signed build on an iPhone is needed for real audio and alarm evaluation.

```sh
git clone https://github.com/joshuawyadao/Honkshool.git
cd Honkshool
open Honkshool.xcodeproj
```

Follow [Getting started](docs/Getting-Started.md) to select a simulator or configure private device signing. Bundled audio is already included; you do not need to generate narration or install an AI model.

For repository checks and the complete simulator suite:

```sh
./scripts/verify-repository.sh
./scripts/test-ios.sh
```

The first command uses shell, Python's standard library, and Git. The second needs full Xcode and an installed simulator. See [Development](docs/Development.md) for destination overrides, the source map, test boundaries, and offline preparation tools. Read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a change.

## What is still experimental?

The reviewed playback, optional alarm, two-session journey, and local history are implemented. Automated target-iPhone checks cover rain looping, controls, narration-to-rain history, alarm/cutoff timing, and background/relaunch state. Direct observation of current production rain Lock Screen controls, physical headphone disconnection, relative volume, and longer listening comfort remains pending.

The next milestone is the [approximately ten-nap personal trial](docs/Ten-Nap-Trial.md). More content, branching navigation, and a redesigned home screen remain later work. See the [project overview](docs/Project-Overview.md) and [durable roadmap](docs/Project-Implementation-Plan.md) for details. The replaceable task plan lives in [docs/Implementation-Plan.md](docs/Implementation-Plan.md).

## Privacy, help, and reuse

The app has no backend, account, analytics, or app-managed cloud sync. Listening history and preferences are stored locally; alarm scheduling uses iOS. There is currently no in-app history delete/export control. Read [Privacy and local data](docs/Privacy.md) for storage, backups, and reset limits.

Use [Troubleshooting](docs/Troubleshooting.md) for setup or playback problems. Report ordinary bugs through [GitHub issues](https://github.com/joshuawyadao/Honkshool/issues), using synthetic examples and redacted details. Report vulnerabilities privately through [SECURITY.md](SECURITY.md). Community expectations are in the [Code of Conduct](CODE_OF_CONDUCT.md).

Code and the original documentation diagrams use the [MIT License](LICENSE). The rain recording uses CC0 1.0. The two generated George recordings have separate model/source and preparation records; see [audio provenance](docs/Audio-Preparation.md) and [content sources](docs/Content-Catalog.md) before reusing assets. The code-license badge does not describe third-party source material.
