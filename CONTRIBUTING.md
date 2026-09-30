# Contributing

Thanks for helping shape Honkshool. Read the [Code of Conduct](CODE_OF_CONDUCT.md) before participating. Report vulnerabilities through [SECURITY.md](SECURITY.md), using its private channel rather than a public issue.

Honkshool is an experimental iPhone app with no supported release. Start with the [project overview](docs/Project-Overview.md), the [getting started guide](docs/Getting-Started.md), and the [development guide](docs/Development.md). The development guide is the source of truth for repository layout, tests, simulator settings, physical-device checks, CI, and audio preparation.

## Proposing a change

1. Search existing issues and pull requests. Open an issue before choosing a framework, adding a network service or persistent storage, requesting a new permission, or changing privacy behavior.
2. Create a descriptive branch from `main` and keep the pull request focused on one outcome.
3. Add or update focused tests when executable behavior changes. Update the relevant [documentation](docs/README.md) when behavior, architecture, installation, data handling, verification, or supported environments change.
4. Run the [repository gate and applicable iOS tests](docs/Development.md#verification) before opening the pull request. Explain any check you could not run.
5. Describe the user-visible outcome, privacy and security implications, verification performed, and known limitations in the pull request.

## Public-data rules

Use synthetic examples and fixtures. Do not commit credentials, tokens, certificates, personal exports, private configuration, local databases, logs, generated reports, or audio preparation caches. Redact local usernames, device identifiers, and machine-specific paths from screenshots and command output. The [development guide](docs/Development.md#maintaining-public-documentation) explains how to keep documentation safe for this public repository.
