# Honkshool

[![Repository Verify](https://github.com/joshuawyadao/Honkshool/actions/workflows/ci.yml/badge.svg)](https://github.com/joshuawyadao/Honkshool/actions/workflows/ci.yml)
[![Project status: feasibility spike](https://img.shields.io/badge/status-feasibility%20spike-6f42c1)](docs/Project-Overview.md)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Honkshool is an early-stage iPhone app for calm, uninterrupted factual narration during naps and bedtime. Its primary purpose is helping the listener relax and fall asleep; exposure to interesting information is secondary.

> **Project status:** Feasibility spike plus an early Nap Plan playback flow; there is no supported release. The experimental console remains separate. The Nap Plan screen can choose and confirm a fixed route, schedule and verify a requested system wake alarm, then start bundled narration or accepted Gentle rain at its approved start and stop audio at its fixed deadline. Silence remains the default and fallback. Keep the app foregrounded until approved playback begins; then the phone can be locked. Stopping playback does not cancel the separately managed wake alarm. Runs save verified narration checkpoints and partial/completed attempts locally; rain creates no narration history. Listening History offers Continue, Resume, and Replay through a fresh Nap Plan review; reopening never starts audio automatically. Automated iPhone checks passed for rain looping and controls, narration-to-rain history, the real wake alarm and cutoff, and the app’s one-minute rain plan with background and relaunch. Locked controls, actual headphone disconnection, and longer listening comfort remain unverified for this production rain flow.

The intended flow is simple:

> Open app → choose content → choose nap duration → review the Nap Plan → start resting.

Honkshool describes sessions as **played**. It does not claim subconscious learning, guaranteed retention, therapy, or treatment of insomnia or another medical condition.

## Why this repository is public

- Keep product and engineering decisions reviewable from the beginning.
- Make privacy, security, and contribution expectations explicit before application code arrives.
- Give future work a consistent issue, pull-request, documentation, and verification workflow.
- Avoid implying that unfinished software is ready for end users.

Read the [product brief](docs/Product-Brief.md) for the product boundary, the [project implementation plan](docs/Project-Implementation-Plan.md) for the durable phased roadmap, the [decision log](docs/Decision-Log.md) for accepted and unresolved choices, and the [project overview](docs/Project-Overview.md) for a concise status summary.

`docs/Implementation-Plan.md` is intentionally reserved for the current task plan created by the `plan-implement-save` workflow and may be replaced on later implementation branches. Long-lived roadmap updates belong in `docs/Project-Implementation-Plan.md`.

## Repository map

```text
.github/                    Issue forms, pull-request template, and CI
Honkshool/                  Feasibility console, nap domain, and prepared content
HonkshoolTests/             Domain, spike-state, and layout tests
HonkshoolUITests/           Feasibility regressions and Nap Plan review flow
HonkshoolAlarmWidget/       Alarm snooze Live Activity
Honkshool.xcodeproj/        Shared Xcode project and scheme
docs/                       Product context, decisions, status, and roadmap
scripts/                    Verification, iOS tests, and offline audio preparation
tests/                      Publication and repository-safety checks
CODE_OF_CONDUCT.md          Community behavior and private reporting channel
CONTRIBUTING.md             Contribution workflow and quality expectations
SECURITY.md                 Private vulnerability-reporting policy
LICENSE                     MIT license
```

The app opens on the feasibility console, with a separate Nap Plan review entry. Follow the [device test guide](docs/Feasibility-Spike.md) before drawing conclusions from the spike. The review screen offers two ordered prepared automotive sessions—Turning Fuel Into Motion and Air, Fuel, and Spark—default Silence, and Gentle rain when the accepted bundled file and provenance validate. Rain can fill a short plan without narration or follow a completed session; an unavailable or failed rain loop visibly leaves rest in silence without asking the listener to act mid-nap.

## Automated validation

On a Mac with Xcode 26 and an installed iOS 26 simulator, run the complete unit and UI suite with one command:

```sh
./scripts/test-ios.sh
```

The script defaults to the latest iPhone 17 Pro simulator. Set `HONKSHOOL_TEST_DESTINATION` to any compatible Xcode destination when needed. Pull requests run the same suite on a read-only GitHub-hosted macOS 26 runner in addition to the portable repository checks.

Routine UI tests use debug-only simulated alarm states, deterministic speech, and isolated preferences that leave real alarm tracking and saved defaults untouched. They never request real AlarmKit permission or schedule a system alarm. An opt-in physical UI case uses real rain and clocks with isolated storage to check controls, background-state continuity, deadline completion, and relaunch. Separately gated physical-device tests use actual bundled audio and AlarmKit to check looping rain, narration completion and saved history, and alarm/cutoff timing; see the [unattended device test guide](docs/Feasibility-Spike.md#production-gentle-rain-acceptance-on-the-target-iphone).

## Start contributing

1. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md).
2. Check existing issues before proposing work.
3. Create a focused branch from `main`.
4. Keep behavior changes, tests, and documentation in the same pull request.
5. Run the repository gate before opening a pull request:

   ```sh
   ./scripts/verify-repository.sh
   ```

The verification gate has no third-party runtime dependencies; it uses the system shell, Python standard library, and Git.

## Privacy and security

- Do not commit credentials, tokens, certificates, private configuration, personal exports, local databases, logs, or generated reports.
- Local environment files and common secret-bearing formats are excluded by [.gitignore](.gitignore).
- Use synthetic data in tests and public issue reproductions.
- Report vulnerabilities through the private process in [SECURITY.md](SECURITY.md), not a public issue.

GitHub secret scanning, push protection, Dependabot security updates, and private vulnerability reporting are enabled for the public repository.

## Current roadmap

1. Completed feasibility validation on the target iPhone: narration, background audio, tested interruptions, Lock Screen controls, AlarmKit, and the larger-text snooze layout (2026-09-15). Squash-merged through PR #2 as `45dcc71`; this remains an experimental console.
2. Implemented and tested the framework-independent Nap Plan, journey, progress, and history rules, squash-merged through PR #3 as `c5025ad`; see the [domain contract](docs/Nap-Planning-Domain.md). Fixed deadlines and short-window fallback follow approved D-004/D-009.
3. Added a [bundled content catalog](docs/Content-Catalog.md) with an original citation-backed automotive session, source metadata, pronunciation guidance, and a complete prepared Kokoro George `0.86` narration. The lossless 727.625-second asset plays through the feasibility console; the planner uses a configurable 730-second estimate. [Audio preparation](docs/Audio-Preparation.md) records narration and CC0 rain provenance. The owner selected the prepared rain candidate for use on 2026-09-28; relative level against narration, longer comfort, and physical-device acceptance remain open.
4. The choose → review screen connects confirmed plans to prepared narration, selected rain or silence, manual controls, a fixed audio cutoff, and optional production AlarmKit scheduling before playback. Alarm identity is kept separately from the feasibility test alarm and can be reconciled or explicitly cancelled after playback stops. SwiftData history retains narration attempts and verified checkpoints across relaunch, with completion-only journey progress and explicit Resume/Replay. Real-iPhone rain, alarm, history, and background-state checks passed; locked-screen controls and listening comfort still need direct observation.
5. Added Air, Fuel, and Spark as the second prepared George session on `codex/two-session-journey`. Continue follows completion evidence to the next session or its saved partial position; a long plan can approve both sessions before playback. The next milestone is an approximately ten-nap personal validation trial, with the deferred manual audio observations recorded during use.

See the [living project implementation plan](docs/Project-Implementation-Plan.md) for acceptance criteria and branch sequence. Questions that gate a phase are recorded in the [decision log](docs/Decision-Log.md), not left implicit in code.

## Contributing

Issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before participating. Conduct concerns and security vulnerabilities have separate private reporting paths; do not include sensitive details in public issues.

## License

Code is released under the [MIT License](LICENSE). The bundled rain recording uses CC0 1.0; see its [source and preparation record](docs/Audio-Preparation.md#rain-candidate-and-provenance).
