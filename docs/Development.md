# Development guide

This guide is for contributors working on Honkshool's source and repository documentation. For a first build and app tour, follow [Getting started](Getting-Started.md). For contribution expectations, see [CONTRIBUTING.md](../CONTRIBUTING.md). Honkshool is an experimental iPhone app, with no supported release.

## Requirements and setup

The portable repository gate needs a POSIX shell, Python 3, and Git; it has no third-party Python runtime dependencies. Building and running the iOS app requires a Mac with Xcode 26.6 or newer with compatible iOS platform support, an installed iOS 26-or-newer simulator, and the shared `Honkshool` scheme. See [Getting started](Getting-Started.md) for setup and simulator selection.

The repository includes [Config/Local.xcconfig.example](../Config/Local.xcconfig.example). Copy it to ignored `Config/Local.xcconfig` and supply your own Apple development team only when a signed physical-device build needs it. Never commit personal signing settings, certificates, provisioning profiles, or device diagnostics. The shared [signing configuration](../Config/Signing.xcconfig) has no team value.

## Source map

| Location | Responsibility |
| --- | --- |
| [`Honkshool/App/`](../Honkshool/App/) | SwiftUI Rest/History shell, Settings and Feasibility Lab, Nap Plan review, prepared-content pages, listening history, preview, and Debug UI-test fixtures. |
| [`Honkshool/Domain/`](../Honkshool/Domain/) | Nap planning, playback, content, and spike state rules. |
| [`Honkshool/Services/`](../Honkshool/Services/) | Alarm, audio, ambience, run control, and local history adapters. |
| [`Honkshool/Content/`](../Honkshool/Content/) and [`Honkshool/Resources/`](../Honkshool/Resources/) | Prepared catalog definitions, bundled audio, and provenance. |
| [`Honkshool/Shared/`](../Honkshool/Shared/) and [`HonkshoolAlarmWidget/`](../HonkshoolAlarmWidget/) | Alarm metadata shared with the Lock Screen widget and the widget UI. |
| [`HonkshoolTests/`](../HonkshoolTests/) and [`HonkshoolUITests/`](../HonkshoolUITests/) | Swift unit, service, layout, and UI tests. |
| [`tests/`](../tests/) | Portable Python publication and audio-asset checks. |
| [`scripts/`](../scripts/) | Verification, simulator tests, and offline preparation tools. |

The [architecture guide](Architecture.md) explains the main boundaries; the [Nap Planning domain contract](Nap-Planning-Domain.md) covers planning rules. The [Quiet curiosity design language](Design-Language.md) and [screen implementation map](Screen-Implementation-Map.md) cover current UI composition and capability limits. The [project overview](Project-Overview.md) and [decision log](Decision-Log.md) track current status and accepted choices.

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
| `HONKSHOOL_TEST_VERBOSE` | `0` | Set `1` for detailed build and test progress; CI enables it. Other values fail before Xcode or result creation. |
| `HONKSHOOL_TEST_SCOPE` | `all` | `all` runs host and UI targets; `unit` runs the host target; `ui` runs the UI target selected by `HONKSHOOL_UI_SHARD`. Other values fail before Xcode or result creation. |
| `HONKSHOOL_UI_SHARD` | `all` | With `HONKSHOOL_TEST_SCOPE=ui`, use `all` for every UI class, `plan-review` for `NapPlanReviewUITests`, or `other` for every other UI class. A non-`all` shard with another scope fails before Xcode or result creation. |

For a faster local domain, controller or persistence iteration:

```sh
HONKSHOOL_TEST_SCOPE=unit ./scripts/test-ios.sh
```

This mode retains host integration checks, including actual bundled resources and SwiftData. It does not replace the complete suite for app changes or hardware acceptance. CI runs the unit scope and two complementary UI shards in separate required macOS jobs. The local default remains the complete suite.

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
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/HonkshoolDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

Use `build-for-testing` instead of `build` to compile test bundles without executing them. These commands still need the iOS SDK and do not establish test or physical-device acceptance. The [feasibility guide](Feasibility-Spike.md#local-setup) also shows a signed generic-device build.

### Debug fixtures and physical checks

Routine UI tests use launch-time fixtures compiled only for Debug builds. They simulate alarm states and deterministic speech, and keep test preferences and history isolated from normal app data. These checks exercise Honkshool logic and screens without requesting real AlarmKit permission or proving locked-screen delivery.

After applying a setup sheet, wait for its controls to disappear and the destination action to become hittable before asserting the resulting state. A button can exist behind a dismissing sheet; immediate hittability checks can race that transition on hosted simulators. Keep these waits bounded and preserve the accessibility and applied-selection assertions.

Physical-device cases are separately gated and skipped in ordinary simulator runs. The test files use `HONKSHOOL_REAL_RAIN_TEST`, `HONKSHOOL_REAL_NAP_PLAN_ALARM_TEST`, and `HONKSHOOL_REAL_ALARM_TEST` as opt-in environment flags; Xcode passes them to its test runner with a `TEST_RUNNER_` prefix. Run them only on a connected, signed iPhone with the required alarm authorization. Follow the exact commands and acceptance notes in [Feasibility Spike](Feasibility-Spike.md#minimal-physical-device-acceptance) and its [production rain section](Feasibility-Spike.md#production-gentle-rain-acceptance-on-the-target-iphone). A passing simulator run does not establish audible quality, headphone disconnection behavior, or Lock Screen control behavior on hardware.

### CI

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) defines three job groups for non-draft pull requests, pushes to `main`, and manual `workflow_dispatch` runs:

| Check | Work |
| --- | --- |
| **Repository Verify** | Ubuntu runs the portable gate, then `scripts/ci-policy.py` classifies the exact pull-request or push base/head commit diff. Only ordinary, non-executable Markdown or SVG under `docs/`, and the known root README/contribution/conduct/security Markdown files, qualify as documentation-only. |
| **iOS Tests (unit / plan-review / other)** | After repository verification, three independent macOS jobs each provision and remove their own iOS 26-or-newer iPhone 17 Pro simulator. The unit job runs all Swift host tests and builds an unsigned Release app. The UI jobs run `NapPlanReviewUITests` and the complete UI target excluding that class, respectively; new UI classes join the latter automatically. Every job is required for code, tests, resources, project/workflow settings or unknown paths. Manual dispatch always runs all three. Verified documentation-only PRs or pushes skip the matrix without allocating macOS. |
| **CI Verify** | A stable Ubuntu readiness check runs even when a dependency fails. It requires successful repository verification and full iOS success, or an explicit successful documentation-only classification with iOS skipped. Missing classification, failures and cancellations cannot pass this gate. |

The classifier inspects both sides of renames and deletions, handles NUL-delimited Git paths, and checks file modes; unknown or malformed input fails conservatively. No workflow-level path filter can leave a required check waiting. Draft PRs skip these checks; marking one ready for review starts them. The same aggregate **CI Verify** check runs after merges on `main`; it requires the Release build when the iOS job is selected. Physical-device opt-in tests are not CI acceptance evidence.

Each macOS job validates the pinned Xcode 26.6 developer directory and publishes it as both `DEVELOPER_DIR` and `HONKSHOOL_XCODE_PATH` before provisioning, so simulator tools, the test runner, and the Release build use the same Xcode. CI pins `HONKSHOOL_CI_IOS_VERSION=26.5`; it uses that installed runtime or downloads that exact platform version, then fails if it is still unavailable. Direct helper use without the CI pin selects the newest compatible installed runtime. It creates, boots, and waits for one CI-owned iPhone 17 Pro simulator before its test scope, and always shuts down and deletes that ID afterward. A hosted image listing installed simulator SDKs does not prove that a selectable simulator device is registered on a particular runner. A missing runtime or failed boot remains a failed CI run; tests are never skipped or replaced with a compile-only check.

Each macOS matrix entry has a 40-minute bound, emits detailed build and test progress, and does not cancel sibling entries when one fails. Local runs remain quiet by default. The retained results from run `43950692622` show 238 unit cases executed (5 skipped, no failures); the UI phase recorded 52 passes, one skip, one failure and one unfinished case before the former combined 50-minute job was cancelled. The failure followed a Change session action with no Sessions sheet visible. The separate jobs preserve the full unit/UI suite and allow the UI failure to be diagnosed without consuming the unit/Release job's time budget. The [resource-efficiency note](Efficiency.md) records later optimization ideas and their acceptance requirements. Do not shorten coverage or raise paid resource commitments solely to improve a timing number.

Failed or cancelled CI entries retain available simulator results as uniquely named Actions artifacts for seven days. Cancellation can leave an incomplete `.xcresult` bundle; it does not establish test acceptance. Download the artifact to inspect assertion locations, UI activity, and screenshots in Xcode. The test script publishes its fresh result directory through the standard `GITHUB_OUTPUT` file when available. Artifacts contain synthetic simulator test data; do not upload personal-device result bundles. Feasibility label failures report the expected and observed label at the original assertion call site; timeouts and behavioral expectations remain unchanged.

## Offline audio tools

These scripts are preparation and review tools, not app runtime dependencies. [Audio Preparation](Audio-Preparation.md) is the canonical guide for exact inputs, model/cache requirements, provenance, measurement, and publication decisions, including the isolated macOS arm64/Python 3.11 environment in [tools/audio/requirements-macos-arm64-py311.txt](../tools/audio/requirements-macos-arm64-py311.txt).

| Script | Purpose |
| --- | --- |
| [`prepare-kokoro-narration.py`](../scripts/prepare-kokoro-narration.py) | Render catalog narration from a pinned local Kokoro cache into a new WAV and provenance record. Requires a separate preparation environment; the cache and environment stay outside Git. |
| [`prepare-rain.py`](../scripts/prepare-rain.py) | Prepare a rain WAV from a supplied source recording. |
| [`make-george-review-reel.py`](../scripts/make-george-review-reel.py) | Assemble a short audition from the verified bundled George narration into a new local output file. |
| [`render-narration.swift`](../scripts/render-narration.swift) | Historical Apple speech rendering and measurement workflow described in Audio Preparation. |

Use fresh output paths, inspect provenance and measurements, and follow the content review process before changing bundled audio. Generated review output, model files, and local preparation environments do not belong in a pull request.

## Maintaining public documentation

Update the canonical document nearest a changed behavior: [Getting started](Getting-Started.md) for setup, [User guide](User-Guide.md) for app use, [Design Language](Design-Language.md) and [Screen Implementation Map](Screen-Implementation-Map.md) for the Rest-first interface, [Architecture](Architecture.md) for boundaries, [Audio Preparation](Audio-Preparation.md) for generated content, and [Feasibility Spike](Feasibility-Spike.md) for test evidence. The [documentation index](README.md) points readers to the rest. Keep the durable [project implementation plan](Project-Implementation-Plan.md) distinct from the replaceable [current task plan](Implementation-Plan.md).

Document only observed outcomes; label pending device or listening checks as pending. Use synthetic fixtures and redacted examples. Keep local usernames, absolute machine paths, device identifiers, personal listening logs, private exports, credentials, and generated reports out of public Markdown and screenshots. Check relative links from the file that contains them and run the repository gate before submitting a pull request.

The largest-text sound test waits up to the standard five seconds for Review to become hittable after Apply dismisses the sound sheet, then retains its original hittability assertion. Existing duration-height, label and selection assertions are unchanged. A transition timeout retains screenshot/hierarchy diagnostics; it is not treated as a passing accessibility check.

The complete portfolio baseline passes at `102bd85` in [run43972459300](https://github.com/joshuawyadao/Honkshool/actions/runs/43972459300): repository checks, unit/unsigned Release, both complementary UI shards, owned simulator cleanup and CI Verify. Every job finishes within its 40-minute bound. Later documentation-only completion records do not change executable/test inputs.
