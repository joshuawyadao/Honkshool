# Honkshool

[![Repository Verify](https://github.com/joshuawyadao/Honkshool/actions/workflows/ci.yml/badge.svg)](https://github.com/joshuawyadao/Honkshool/actions/workflows/ci.yml)
[![Project status: feasibility spike](https://img.shields.io/badge/status-feasibility%20spike-6f42c1)](docs/Project-Overview.md)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Honkshool is an early-stage iPhone app for calm, uninterrupted factual narration during naps and bedtime. Its primary purpose is helping the listener relax and fall asleep; exposure to interesting information is secondary.

> **Project status:** Feasibility spike. An experimental iOS test app now exists, but there is no supported release. It is intentionally designed to measure physical-device narration, background audio, and AlarmKit behavior before production architecture begins.

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
Honkshool/                  Experimental iOS spike source
HonkshoolTests/             Focused spike-state tests
HonkshoolUITests/           Blocked-start and scrolling regressions
HonkshoolAlarmWidget/       Alarm snooze Live Activity
Honkshool.xcodeproj/        Shared Xcode project and scheme
docs/                       Product context, decisions, status, and roadmap
scripts/                    Local repository verification entry point
tests/                      Publication and repository-safety checks
CODE_OF_CONDUCT.md          Community behavior and private reporting channel
CONTRIBUTING.md             Contribution workflow and quality expectations
SECURITY.md                 Private vulnerability-reporting policy
LICENSE                     MIT license
```

The current application surface is a feasibility console, not the first product UI. Follow the [device test guide](docs/Feasibility-Spike.md) before drawing conclusions from the spike.

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

1. Complete `spike/audio-and-alarm-feasibility` on the target iPhone to validate narration, background audio, interruptions, Lock Screen controls, and AlarmKit.
2. Define and test the framework-independent Nap Plan, journey, progress, and history rules.
3. Prepare one original, citation-backed automotive session and one lawful offline ambience option.
4. Build the choose → review → play → alarm → history tracer bullet.
5. Extend the local journey experience only as needed for an approximately ten-nap personal validation trial.

See the [living project implementation plan](docs/Project-Implementation-Plan.md) for acceptance criteria and branch sequence. Questions that gate a phase are recorded in the [decision log](docs/Decision-Log.md), not left implicit in code.

## Contributing

Issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before participating. Conduct concerns and security vulnerabilities have separate private reporting paths; do not include sensitive details in public issues.

## License

Released under the [MIT License](LICENSE).
