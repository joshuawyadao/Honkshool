# Honkshool

[![Repository Verify](https://github.com/joshuawyadao/Honkshool/actions/workflows/ci.yml/badge.svg)](https://github.com/joshuawyadao/Honkshool/actions/workflows/ci.yml)
[![Project status: feasibility spike](https://img.shields.io/badge/status-feasibility%20spike-6f42c1)](docs/Project-Overview.md)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Honkshool is an early-stage iPhone app for calm, uninterrupted factual narration during naps and bedtime. Its primary purpose is helping the listener relax and fall asleep; exposure to interesting information is secondary.

> **Project status:** Feasibility spike plus a pre-play Nap Plan review screen; there is no supported release. The experimental console plays the bundled prepared session to measure narration, background audio, and AlarmKit behavior. A separate screen uses the planning domain and prepared catalog to choose, review, and confirm a fixed plan. Confirmation does not start playback, schedule an alarm, or save history.

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
HonkshoolUITests/           Blocked-start and scrolling regressions
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

The app opens on the feasibility console, with a separate Nap Plan review entry. Follow the [device test guide](docs/Feasibility-Spike.md) before drawing conclusions from the spike. The review screen currently offers one prepared automotive session and silence; the bundled rain candidate is still awaiting acceptance.

## Automated validation

On a Mac with Xcode 26 and an installed iOS 26 simulator, run the complete unit and UI suite with one command:

```sh
./scripts/test-ios.sh
```

The script defaults to the latest iPhone 17 Pro simulator. Set `HONKSHOOL_TEST_DESTINATION` to any compatible Xcode destination when needed. Pull requests run the same suite on a read-only GitHub-hosted macOS 26 runner in addition to the portable repository checks.

UI tests use debug-only simulated alarm states, deterministic speech, and isolated preferences that leave real alarm tracking and saved defaults untouched. They never request real AlarmKit permission or schedule a system alarm. A separately gated physical-device test checks actual AlarmKit alerting and narration cutoff; see the feasibility guide.

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
3. Added a [bundled content catalog](docs/Content-Catalog.md) with an original citation-backed automotive session, source metadata, pronunciation guidance, and a complete prepared Kokoro George `0.86` narration. The lossless 727.625-second asset now plays through the feasibility console with pause/resume, interruption handling, Lock Screen metadata, and fixed-deadline stopping; the planner uses a configurable 730-second estimate. [Audio preparation](docs/Audio-Preparation.md) records exact provenance. Automated full-file decoding, natural-end playback, and a real iPhone AlarmKit/cutoff check have passed. Brief route/control checks, full-session subjective listening acceptance, rain acceptance, and production plan/history integration remain open.
4. The pre-play choose → review slice is implemented. Connect the approved snapshot to production playback, alarm scheduling, and history in later branches.
5. Extend the local journey experience only as needed for an approximately ten-nap personal validation trial.

See the [living project implementation plan](docs/Project-Implementation-Plan.md) for acceptance criteria and branch sequence. Questions that gate a phase are recorded in the [decision log](docs/Decision-Log.md), not left implicit in code.

## Contributing

Issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before participating. Conduct concerns and security vulnerabilities have separate private reporting paths; do not include sensitive details in public issues.

## License

Code is released under the [MIT License](LICENSE). The bundled rain recording uses CC0 1.0; see its [source and preparation record](docs/Audio-Preparation.md#rain-candidate-and-provenance).
