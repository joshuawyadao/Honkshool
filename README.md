# Honkshool

[![Repository Verify](https://github.com/joshuawyadao/Honkshool/actions/workflows/ci.yml/badge.svg)](https://github.com/joshuawyadao/Honkshool/actions/workflows/ci.yml)
[![Project status: foundation](https://img.shields.io/badge/status-foundation-6f42c1)](docs/Project-Overview.md)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Honkshool is an early-stage public project. This repository currently provides the project foundation: transparent planning, contribution and security policies, privacy-safe defaults, issue templates, and automated repository checks.

> **Project status:** Foundation. No application, package, hosted service, or supported release exists yet. The product brief and first runnable tracer bullet are the next milestones.

## Why this repository is public

- Keep product and engineering decisions reviewable from the beginning.
- Make privacy, security, and contribution expectations explicit before application code arrives.
- Give future work a consistent issue, pull-request, documentation, and verification workflow.
- Avoid implying that unfinished software is ready for end users.

Read the [project overview](docs/Project-Overview.md) for the current boundaries and the decisions that must be made before implementation begins.

## Repository map

```text
.github/                    Issue forms, pull-request template, and CI
docs/                       Project overview and implementation plans
scripts/                    Local repository verification entry point
tests/                      Publication and repository-safety checks
CODE_OF_CONDUCT.md          Community behavior and private reporting channel
CONTRIBUTING.md             Contribution workflow and quality expectations
SECURITY.md                 Private vulnerability-reporting policy
LICENSE                     MIT license
```

Application directories will be added only after the product brief establishes the platform and architectural boundaries.

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

1. Define the problem Honkshool solves, its intended users, and its privacy boundaries.
2. Choose the initial platform and architecture from those requirements.
3. Build one end-to-end tracer bullet with focused automated tests.
4. Document installation, supported environments, limitations, and release policy before inviting end users.

## Contributing

Issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before participating. Conduct concerns and security vulnerabilities have separate private reporting paths; do not include sensitive details in public issues.

## License

Released under the [MIT License](LICENSE).
