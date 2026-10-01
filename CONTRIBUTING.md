# Contributing

Thanks for helping shape Honkshool. Read the [Code of Conduct](CODE_OF_CONDUCT.md) before participating. Report vulnerabilities through [SECURITY.md](SECURITY.md), using its private channel rather than a public issue.

Honkshool is an experimental iPhone app with no supported release. Start with the [project overview](docs/Project-Overview.md), the [getting started guide](docs/Getting-Started.md), and the [development guide](docs/Development.md). The development guide is the source of truth for repository layout, tests, simulator settings, physical-device checks, CI, and audio preparation.

## Proposing a change

1. Read the [project overview](docs/Project-Overview.md) and search existing issues and pull requests.
   For UI changes, also read the approved [Quiet curiosity design language](docs/Design-Language.md) and [screen atlas](design/quiet-curiosity/screen-atlas.html). It is the default for current and future screens unless the owner explicitly changes it; the atlas's future examples do not imply shipped features.
2. Open an issue before choosing a framework, adding a network service, introducing persistent storage, requesting new permissions, or changing privacy behavior.
3. Keep each pull request focused on one coherent outcome.

## Development workflow

1. Fork or clone the repository and create a descriptive branch from `main`.
2. Add or update focused tests when executable behavior changes.
3. Update the relevant [documentation](docs/README.md) when behavior, architecture, data handling, operations, installation, or supported environments change.
4. Run the complete repository gate:

   ```sh
   ./scripts/verify-repository.sh
   ```

   Changes to the experimental iOS target should also pass the complete automated simulator suite:

   ```sh
   ./scripts/test-ios.sh
   ```

   The [feasibility spike guide](docs/Feasibility-Spike.md) documents destination overrides, completed physical acceptance, and when to repeat affected locked-screen audio, hardware-routing, or AlarmKit checks. Simulator success is not physical-device acceptance evidence.

5. Describe the user-visible outcome, privacy and security implications, verification performed, any check you could not run, and known limitations in the pull request.


## Public-data rules

Use synthetic examples and fixtures. Do not commit credentials, tokens, certificates, personal exports, private configuration, local databases, logs, generated reports, or audio preparation caches. Redact local usernames, device identifiers, and machine-specific paths from screenshots and command output. The [development guide](docs/Development.md#maintaining-public-documentation) explains how to keep documentation safe for this public repository.
