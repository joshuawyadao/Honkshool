# Project overview

## Current state

Honkshool is a pre-implementation, iPhone-first project for calm, uninterrupted factual narration during naps and bedtime. The public repository contains the product definition, delivery roadmap, decision history, contribution and security policies, and automated repository checks. It does not yet contain a runnable app or supported release.

The primary outcome is relaxation and rest. Interesting factual exposure is secondary, and the product must not claim subconscious learning, guaranteed retention, therapy, or treatment of insomnia or another medical condition.

## Sources of truth

- [Product brief](Product-Brief.md): purpose, language and safety boundaries, core experience, first content, technical constraints, and first-release scope.
- [Project implementation plan](Project-Implementation-Plan.md): durable phased delivery sequence, branch-sized milestones, acceptance criteria, test strategy, and validation goal.
- [Decision log](Decision-Log.md): accepted, pending, and deferred product and technical decisions.
- [Issue #1](https://github.com/joshuawyadao/Honkshool/issues/1): original public product-definition milestone.

When these documents disagree, correct them together in the same pull request. The product brief owns product intent, the decision log owns why a consequential choice changed, and the project implementation plan owns sequencing and current next steps.

## Planning-file convention

The durable roadmap lives in [Project-Implementation-Plan.md](Project-Implementation-Plan.md). The `plan-implement-save` workflow creates or replaces [Implementation-Plan.md](Implementation-Plan.md) for the current feature, fix, or documentation task. Task plans may be overwritten; durable product sequencing and status must never depend on their contents.

## First target outcome

The first tracer bullet should let the project owner select one bundled automotive session, choose a rest window, approve a fixed Nap Plan, lock the iPhone, hear calm narration transition to offline ambience or silence, receive a dependable AlarmKit wake alarm, and find the playback recorded locally as partial or complete.

This flow intentionally excludes backend services, accounts, analytics, cloud sync, subscriptions, ads, paid APIs, runtime AI generation, and distribution work.

## Next milestone

The next implementation branch is `spike/audio-and-alarm-feasibility`. It should validate the riskiest behavior on the target iPhone before the app architecture is committed:

1. On-device narration during locked-screen background playback.
2. Audio-session behavior during pauses, calls, route changes, and app lifecycle events.
3. A controlled transition to ambience or silence.
4. AlarmKit authorization, scheduling, cancellation, stop/snooze behavior, and reliability.
5. The relationship between estimated script duration and a fixed wake time.

Results belong in the decision log and should determine the playback interfaces used by later feature branches.

## Working agreement

- Use focused branches and keep `main` reviewable.
- Update product, decision, implementation, test, and user-facing documentation with the behavior they describe.
- Test domain rules at the narrowest useful level, but verify background audio and alarms on physical hardware.
- Use synthetic fixtures and redact machine-specific paths, identifiers, schedules, and personal listening history from public artifacts.
- Treat new permissions, network calls, data sources, persistence, and system integrations as privacy and security changes requiring explicit review.
- Do not announce end-user readiness until installation, signing, supported-device, troubleshooting, and release expectations are documented.

## Foundation already established

- MIT licensing and public contribution guidance.
- Separate private channels for security and conduct reports.
- Privacy-safe ignore rules for credentials, local configuration, personal data, logs, databases, and build output.
- Structured bug and feature request forms that discourage sensitive public attachments.
- A pull-request checklist covering behavior, tests, documentation, privacy, and security.
- A dependency-free local verification command mirrored by quota-aware GitHub Actions.
