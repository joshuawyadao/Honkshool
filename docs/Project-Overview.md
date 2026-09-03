# Project overview

## Current state

Honkshool is in its foundation stage. The repository is intentionally public before application development begins so that decisions, safeguards, and contribution practices are visible from the start.

There is no runnable product yet. The repository must not be presented as production-ready software, and no platform, framework, storage system, or deployment model has been selected.

## Foundation already established

- MIT licensing and public contribution guidance.
- Separate private channels for security and conduct reports.
- Privacy-safe ignore rules for credentials, local configuration, personal data, logs, databases, and build output.
- Structured bug and feature request forms that discourage sensitive public attachments.
- A pull-request checklist covering behavior, tests, documentation, privacy, and security.
- A dependency-free local verification command mirrored by quota-aware GitHub Actions.

## Next definition milestone

Before application code is added, document:

1. The user problem and the smallest useful outcome.
2. Intended users and explicit non-users.
3. Data the product reads, creates, stores, transmits, or deletes.
4. Privacy, security, accessibility, and failure-mode requirements.
5. The initial supported platform and why it fits the problem.
6. One tracer-bullet flow that proves the riskiest assumption end to end.
7. Acceptance criteria and the appropriate test levels for that flow.

Those decisions should become a focused product brief or issue before they become code. Architecture should follow the defined problem rather than be chosen during repository scaffolding.

## Working agreement

- Keep `main` reviewable and use focused pull requests for implementation work.
- Update durable documentation whenever behavior, architecture, data handling, operations, or supported environments change.
- Add tests at the narrowest level that protects the behavior without duplicating equivalent coverage.
- Use synthetic fixtures and redact machine-specific paths in public discussions.
- Treat new permissions, network calls, data sources, and persistent storage as security and privacy changes requiring explicit review.
- Do not publish binaries or announce end-user readiness until installation, signing, support, and release expectations are documented.

## Deliberately undecided

- Product category and feature scope.
- Language, framework, and package manager.
- Client, server, web, mobile, or desktop delivery.
- Data model and persistence.
- Hosting and release distribution.

Leaving these decisions open is a constraint, not missing scaffolding. Repository checks should grow alongside the selected stack once the first implementation slice is approved.
