# Development guide

This guide is for contributors working on Honkshool's source and repository documentation. For a first build and app tour, follow [Getting started](Getting-Started.md). For contribution expectations, see [CONTRIBUTING.md](../CONTRIBUTING.md). Honkshool is an experimental iPhone app, with no supported release.

## Requirements and setup

The portable repository gate needs a POSIX shell, Python 3, and Git; it has no third-party Python runtime dependencies. Building and running the iOS app requires a Mac with Xcode 26.6 or newer with compatible iOS platform support, an installed iOS 26-or-newer simulator, and the shared `Honkshool` scheme. See [Getting started](Getting-Started.md) for setup and simulator selection.

The repository includes [Config/Local.xcconfig.example](../Config/Local.xcconfig.example). Copy it to ignored `Config/Local.xcconfig` and supply your own Apple development team only when a signed physical-device build needs it. Never commit personal signing settings, certificates, provisioning profiles, or device diagnostics. The shared [signing configuration](../Config/Signing.xcconfig) has no team value.

## Source map

| Location | Responsibility |
| --- | --- |
| [`Honkshool/App/`](../Honkshool/App/) | SwiftUI entry point, feasibility console, Nap Plan review, Listening History, and Debug UI-test fixtures. |
| [`Honkshool/Domain/`](../Honkshool/Domain/) | Nap planning, playback, content, and spike state rules. |
| [`Honkshool/Services/`](../Honkshool/Services/) | Alarm, audio, ambience, run control, and local history adapters. |
| [`Honkshool/Content/`](../Honkshool/Content/) and [`Honkshool/Resources/`](../Honkshool/Resources/) | Prepared catalog definitions, bundled audio, and provenance. |
| [`Honkshool/Shared/`](../Honkshool/Shared/) and [`HonkshoolAlarmWidget/`](../HonkshoolAlarmWidget/) | Alarm metadata shared with the Lock Screen widget and the widget UI. |
| [`HonkshoolTests/`](../HonkshoolTests/) and [`HonkshoolUITests/`](../HonkshoolUITests/) | Swift unit, service, layout, and UI tests. |
| [`tests/`](../tests/) | Portable Python publication and audio-asset checks. |
| [`scripts/`](../scripts/) | Verification, simulator tests, and offline preparation tools. |

The [architecture guide](Architecture.md) explains the main boundaries; the [Nap Planning domain contract](Nap-Planning-Domain.md) covers planning rules. The [project overview](Project-Overview.md) and [decision log](Decision-Log.md) track current status and accepted choices.

## Verification

Run these commands from the repository root. The portable gate runs Python's `unittest` discovery under `tests/`, then checks whitespace in unstaged and staged Git diffs:

```sh
./scripts/verify-repository.sh
```

The publication tests inspect tracked files and nonignored untracked candidates. Ignored local configuration, generated output, and dependency environments are excluded; a tracked file is still inspected even if an ignore rule matches its name. Run this gate for documentation-only changes too.

On a Mac with Xcode and a compatible simulator, run the complete Swift unit and UI suite:

```sh
./scripts/test-ios.sh
```

The script uses the shared `Honkshool` scheme, disables parallel testing, writes a fresh `.xcresult` bundle under the system temporary directory, and prints failure details from that bundle. Its defaults and overrides are:

| Variable | Default | Use |
| --- | --- | --- |
| `HONKSHOOL_XCODE_PATH` | `/Applications/Xcode.app/Contents/Developer` | Select the Xcode developer directory. |
| `HONKSHOOL_TEST_DESTINATION` | `platform=iOS Simulator,name=iPhone 17 Pro,OS=latest` | Select an installed compatible simulator. |
| `HONKSHOOL_TEST_DERIVED_DATA` | `/tmp/HonkshoolAutomatedTests` | Choose where Xcode writes derived data. |
| `HONKSHOOL_TEST_DIAGNOSTICS` | `never` | Set Xcode's `-collect-test-diagnostics` mode; CI uses `on-failure`. |

For example, if the default simulator is unavailable:

```sh
HONKSHOOL_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' ./scripts/test-ios.sh
```

Replace the example OS version with one installed locally. The [feasibility spike guide](Feasibility-Spike.md) records the deeper device acceptance protocol and limitations of simulator evidence.

### Compile without running tests

For an unsigned simulator build, including when a simulator runtime is not yet installed:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Honkshool.xcodeproj -scheme Honkshool \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/HonkshoolDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

Use `build-for-testing` instead of `build` to compile test bundles without executing them. These commands still need the iOS SDK and do not establish test or physical-device acceptance. The [feasibility guide](Feasibility-Spike.md#local-setup) also shows a signed generic-device build.

### Debug fixtures and physical checks

Routine UI tests use launch-time fixtures compiled only for Debug builds. They simulate alarm states and deterministic speech, and keep test preferences and history isolated from normal app data. These checks exercise Honkshool logic and screens without requesting real AlarmKit permission or proving locked-screen delivery.

Physical-device cases are separately gated and skipped in ordinary simulator runs. The test files use `HONKSHOOL_REAL_RAIN_TEST`, `HONKSHOOL_REAL_NAP_PLAN_ALARM_TEST`, and `HONKSHOOL_REAL_ALARM_TEST` as opt-in environment flags; Xcode passes them to its test runner with a `TEST_RUNNER_` prefix. Run them only on a connected, signed iPhone with the required alarm authorization. Follow the exact commands and acceptance notes in [Feasibility Spike](Feasibility-Spike.md#minimal-physical-device-acceptance) and its [production rain section](Feasibility-Spike.md#production-gentle-rain-acceptance-on-the-target-iphone). A passing simulator run does not establish audible quality, headphone disconnection behavior, or Lock Screen control behavior on hardware.

### CI

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) defines the **Repository Verify** workflow with two jobs: **Repository Verify** on Ubuntu runs `./scripts/verify-repository.sh`, and **iOS Unit and UI Tests** on macOS runs `./scripts/test-ios.sh` with failure diagnostics enabled. Both jobs run for non-draft pull requests and manual `workflow_dispatch` runs. Draft pull requests skip both jobs; marking one ready for review starts them. Physical-device opt-in tests are not CI acceptance evidence.

Failed CI runs retain the simulator `.xcresult` bundle as an Actions artifact for seven days. Download it from the failed run to inspect assertion locations, UI activity, and screenshots in Xcode. The test script publishes its fresh result directory through the standard `GITHUB_OUTPUT` file when available. Artifacts contain synthetic simulator test data; do not upload personal-device result bundles. Feasibility label failures report the expected and observed label at the original assertion call site; timeouts and behavioral expectations remain unchanged.

## Offline audio tools

These scripts are preparation and review tools, not app runtime dependencies. [Audio Preparation](Audio-Preparation.md) is the canonical guide for exact inputs, model/cache requirements, provenance, measurement, and publication decisions.

| Script | Purpose |
| --- | --- |
| [`prepare-kokoro-narration.py`](../scripts/prepare-kokoro-narration.py) | Render catalog narration from a pinned local Kokoro cache into a new WAV and provenance record. Requires a separate preparation environment; the cache and environment stay outside Git. |
| [`prepare-rain.py`](../scripts/prepare-rain.py) | Prepare a rain WAV from a supplied source recording. |
| [`make-george-review-reel.py`](../scripts/make-george-review-reel.py) | Assemble a short audition from the verified bundled George narration into a new local output file. |
| [`render-narration.swift`](../scripts/render-narration.swift) | Historical Apple speech rendering and measurement workflow described in Audio Preparation. |

Use fresh output paths, inspect provenance and measurements, and follow the content review process before changing bundled audio. Generated review output, model files, and local preparation environments do not belong in a pull request.

## Maintaining public documentation

Update the canonical document nearest a changed behavior: [Getting started](Getting-Started.md) for setup, [User guide](User-Guide.md) for app use, [Architecture](Architecture.md) for boundaries, [Audio Preparation](Audio-Preparation.md) for generated content, and [Feasibility Spike](Feasibility-Spike.md) for test evidence. The [documentation index](README.md) points readers to the rest. Keep the durable [project implementation plan](Project-Implementation-Plan.md) distinct from the replaceable [current task plan](Implementation-Plan.md).

Document only observed outcomes; label pending device or listening checks as pending. Use synthetic fixtures and redacted examples. Keep local usernames, absolute machine paths, device identifiers, personal listening logs, private exports, credentials, and generated reports out of public Markdown and screenshots. Check relative links from the file that contains them and run the repository gate before submitting a pull request.
