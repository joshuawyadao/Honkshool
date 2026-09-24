# Project overview

## Current state

Honkshool is an iPhone-first project for calm, uninterrupted factual narration during naps and bedtime. The repository now contains an experimental iOS 26 feasibility console for audio and alarm testing and a separate Foundation-only nap-planning domain and validated bundled content catalog, in addition to the product definition, delivery roadmap, decision history, contribution and security policies, and automated repository checks. It does not contain a supported release or the intended product UI.

The primary outcome is relaxation and rest. Interesting factual exposure is secondary, and the product must not claim subconscious learning, guaranteed retention, therapy, or treatment of insomnia or another medical condition.

## Sources of truth

- [Product brief](Product-Brief.md): purpose, language and safety boundaries, core experience, first content, technical constraints, and first-release scope.
- [Project implementation plan](Project-Implementation-Plan.md): durable phased delivery sequence, branch-sized milestones, acceptance criteria, test strategy, and validation goal.
- [Decision log](Decision-Log.md): accepted, pending, and deferred product and technical decisions.
- [Nap-planning domain](Nap-Planning-Domain.md): immutable plans, timing, playback outcomes, resume/history rules, and the future adapter contract.
- [Content catalog](Content-Catalog.md): prepared session loading, citations, estimates, resume boundaries, and remaining audio work.
- [Narration reference](Narration-Reference.md): provisional F acceptance, reproducible audition details, and remaining listening checks.
- [Feasibility spike guide](Feasibility-Spike.md): Xcode setup, current implementation boundary, and the physical-device evidence checklist.
- [Issue #1](https://github.com/joshuawyadao/Honkshool/issues/1): original public product-definition milestone.

When these documents disagree, correct them together in the same pull request. The product brief owns product intent, the decision log owns why a consequential choice changed, and the project implementation plan owns sequencing and current next steps.

## Planning-file convention

The durable roadmap lives in [Project-Implementation-Plan.md](Project-Implementation-Plan.md). The `plan-implement-save` workflow creates or replaces [Implementation-Plan.md](Implementation-Plan.md) for the current feature, fix, or documentation task. Task plans may be overwritten; durable product sequencing and status must never depend on their contents.

## First target outcome

The first tracer bullet should let the project owner select one bundled automotive session, choose a rest window, approve a fixed Nap Plan, lock the iPhone, hear calm narration transition to offline ambience or silence, receive a dependable AlarmKit wake alarm, and find the playback recorded locally as partial or complete.

This flow intentionally excludes backend services, accounts, analytics, cloud sync, subscriptions, ads, paid APIs, runtime AI generation, and distribution work.

## Next milestone

Phase 0 feasibility is complete as of 2026-09-15, squash-merged through PR #2 as `45dcc71`. Physical audio/alarm checks passed, including Lock Screen controls, Siri interruption, headphone loss, relaunch reconciliation, and the full nine-minute snooze re-ring. The owner confirmed that the repaired snoozed card fits at the existing larger text setting. Automated layout coverage extends through the first accessibility text size, not every accessibility size.

Phase 1 was squash-merged through PR #3 as `c5025ad` after `codex/nap-plan-domain`: stable content identity, immutable routes, fixed deadlines, configurable settling/drift and fallback, completion-based progress, and partial/resumable listening history, with focused unit tests. D-004 and D-009 are accepted in the decision log. The console remains unchanged and the new core has no runtime or persistence connection.

The prepared-content catalog now contains one original citation-backed automotive session, immutable metadata, pronunciation guidance, and an exact prepared-narration reference. The loader connects it to the planner, validates revision-specific script resume positions, and resolves the bundled audio without introducing AVFoundation into the domain layer. Kokoro George at model speed `0.86` is the selected narration and cadence direction.

The complete 1,829-word George render measures 727.625 seconds, with a 730-second planning estimate and exact provenance. The feasibility console plays the 33 MB lossless asset locally, supports existing background/interruption controls, and stops narration or following ambience at the captured deadline. A softened CC0 window-rain candidate is also bundled with provenance and loop/level checks. See [Audio-Preparation.md](Audio-Preparation.md). Next is target-iPhone playback and complete-session listening acceptance. D-007's narration direction is resolved through D-023 and D-024; D-008 still needs rain acceptance. Silence remains available, and rain is not yet connected to the planner or runtime. Plan-review UI and SwiftData progress/history follow; the prepared adapter does not yet persist partial positions or completion.

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
- Dependency-free repository verification plus a one-command iOS unit/UI suite, both mirrored by read-only GitHub Actions.
