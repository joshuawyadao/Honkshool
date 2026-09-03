# Contributing

Thanks for helping shape Honkshool.

## Code of conduct

By participating, you agree to follow the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). Conduct reports and security reports use separate private channels; do not post sensitive details in a public issue.

## Before opening a change

1. Read the [project overview](docs/Project-Overview.md) and search existing issues and pull requests.
2. Open an issue before choosing a framework, adding a network service, introducing persistent storage, requesting new permissions, or changing privacy behavior.
3. Keep each pull request focused on one coherent outcome.

## Development workflow

1. Fork or clone the repository and create a descriptive branch from `main`.
2. Add or update focused tests when executable behavior changes.
3. Update the canonical documentation when behavior, architecture, data handling, operations, installation, or supported environments change.
4. Run the complete repository gate:

   ```sh
   ./scripts/verify-repository.sh
   ```

5. Describe the user-visible outcome, privacy and security implications, verification performed, and any known limitations in the pull request.

## Public-data rules

- Use synthetic fixtures and examples.
- Do not commit credentials, tokens, certificates, personal exports, private configuration, local databases, logs, or generated reports.
- Redact usernames and machine-specific paths from screenshots and command output.
- Never attach exploit details or sensitive personal information to a public issue.

Report vulnerabilities using [SECURITY.md](SECURITY.md).
