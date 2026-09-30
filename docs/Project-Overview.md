# Project overview

## Current state

Honkshool is an iPhone-first project for calm, uninterrupted factual narration during naps and bedtime. The repository contains an experimental iOS 26 feasibility console for audio and alarm testing, a separate Nap Plan chooser/review and optional-alarm playback flow, a Foundation-only planning domain, and a validated bundled content catalog. The choose → review → play → alarm → local history flow is implemented, but complete target-device acceptance and a supported release remain pending.

The primary outcome is relaxation and rest. Interesting factual exposure is secondary, and the product must not claim subconscious learning, guaranteed retention, therapy, or treatment of insomnia or another medical condition. The owner approved [Quiet curiosity](Design-Language.md) on 2026-09-30 as the default design language for all current and future UI. Its Rest-first shell and calmer Nap Plan and History presentation are being implemented on the design branch. Several atlas browsing concepts now have bounded current-content pages; the [screen implementation map](Screen-Implementation-Map.md) records their routes and limits.

## Sources of truth

- [App icon](App-Icon.md): approved sleeping-goose thought-bubble artwork, generation provenance, asset-catalog integration, and editing checks.
- [Design language](Design-Language.md): approved Rest-first visual and interaction rules, semantic tokens, reusable patterns, and the capability boundary of the [33-screen atlas](../design/quiet-curiosity/screen-atlas.html).
- [Screen implementation map](Screen-Implementation-Map.md): every atlas ID, its current route or runtime state, implementation view, and unsupported illustrative controls.
- [Product brief](Product-Brief.md): purpose, language and safety boundaries, core experience, first content, technical constraints, and first-release scope.
- [Project implementation plan](Project-Implementation-Plan.md): durable phased delivery sequence, branch-sized milestones, acceptance criteria, test strategy, and validation goal.
- [Decision log](Decision-Log.md): accepted, pending, and deferred product and technical decisions.
- [Nap-planning domain](Nap-Planning-Domain.md): immutable plans, timing, playback outcomes, resume/history rules, and local persistence contracts.
- [Content catalog](Content-Catalog.md): prepared session loading, citations, estimates, resume boundaries, and remaining audio work.
- [Narration reference](Narration-Reference.md): provisional F acceptance, reproducible audition details, and remaining listening checks.
- [Feasibility spike guide](Feasibility-Spike.md): Xcode setup, current implementation boundary, and the physical-device evidence checklist.
- [Ten-nap trial guide](Ten-Nap-Trial.md): ordinary-use setup, a blank private-log template, and decision criteria; no personal results are recorded in the repository.
- [Issue #1](https://github.com/joshuawyadao/Honkshool/issues/1): original public product-definition milestone.

When these documents disagree, correct them together in the same pull request. The product brief owns product intent, the decision log owns why a consequential choice changed, and the project implementation plan owns sequencing and current next steps.

## Planning-file convention

The durable roadmap lives in [Project-Implementation-Plan.md](Project-Implementation-Plan.md). The `plan-implement-save` workflow creates or replaces [Implementation-Plan.md](Implementation-Plan.md) for the current feature, fix, or documentation task. Task plans may be overwritten; durable product sequencing and status must never depend on their contents.

## First target outcome

The first tracer bullet should let the project owner select one bundled automotive session, choose a rest window, approve a fixed Nap Plan, lock the iPhone, hear calm narration transition to offline ambience or silence, receive a dependable AlarmKit wake alarm, and find the playback recorded locally as partial or complete.

This flow intentionally excludes backend services, accounts, analytics, cloud sync, subscriptions, ads, paid APIs, runtime AI generation, and distribution work.

## Next milestone

Phase 0 feasibility is complete as of 2026-09-15, squash-merged through PR #2 as `45dcc71`. Physical audio/alarm checks passed, including Lock Screen controls, Siri interruption, headphone loss, relaunch reconciliation, and the full nine-minute snooze re-ring. The owner confirmed that the repaired snoozed card fits at the existing larger text setting. Automated layout coverage extends through the first accessibility text size, not every accessibility size.

Phase 1 was squash-merged through PR #3 as `c5025ad` after `codex/nap-plan-domain`: stable content identity, immutable routes, fixed deadlines, configurable settling/drift and fallback, completion-based progress, and partial/resumable listening history, with focused unit tests. D-004 and D-009 are accepted in the decision log. That domain branch left the console unchanged; the later runtime and local-history slices now connect the core to playback and persistence.

The prepared-content catalog now contains two original citation-backed automotive sessions in order: Turning Fuel Into Motion, then Air, Fuel, and Spark. Both include immutable identity, pronunciation guidance, source metadata, and exact prepared-narration references. The loader connects it to the planner, validates revision-specific script resume positions, and resolves the bundled audio without introducing AVFoundation into the domain layer. Kokoro George at model speed `0.86` is the selected narration and cadence direction.

The complete 1,829-word Turning Fuel Into Motion George render measures 727.625 seconds, with a 730-second planning estimate and exact provenance. The feasibility console plays the 33 MB lossless asset locally, supports existing background/interruption controls, and stops narration or following ambience at the captured deadline. The owner selected the prepared CC0 window-rain candidate for use on 2026-09-28 after an unchanged four-loop audition; its provenance, hash, and decoding are checked before it is offered. See [Audio-Preparation.md](Audio-Preparation.md). The Nap Plan screen chooses bundled content and a rest window, then displays and confirms the planner's fixed deadline, complete route, rest sound, and optional alarm. Silence stays the default. A confirmed plan plays its exact approved narration route, uses looping rain during planned rest when selected, accepts manual pause/resume/Stop, and stops audio at the fixed deadline. Unavailable or failed rain visibly falls back to silence without a mid-nap prompt. When an alarm is requested, production AlarmKit authorization, scheduling, and exact-deadline verification must succeed before playback begins. Its separately tracked alarm survives playback Stop and can be cancelled explicitly; a prior tracked alarm blocks another plan until cancellation. The app must remain foregrounded until approved playback begins, whether narration or rain; leaving early ends the pending run and requires a new review. For a silence-only plan with no narration, wait instead for the visible rest-until-deadline state at the approved start; the phone may then be locked. It saves narration attempts and verified in-flight checkpoints in local SwiftData storage; rain does not create narration progress. Listening History offers explicit Continue, Resume, and Replay into a new review; content revision and prepared-render identity protect resume positions. Reopening never restarts audio. Load/save errors remain visible without stopping an active nap or cancelling an alarm. Opt-in tests on the target iPhone passed the bundled rain loops and controls, resumed narration into rain with persisted history, real AlarmKit alerting and rain cutoff, and the app’s timed rain-only UI flow through backgrounding and relaunch. Locked-screen controls, physical headphone disconnection, relative listening level, and full-session comfort still need direct observation.

The two-session journey reuses the existing ordered-route and history model. Continue names the next incomplete session and resumes its latest valid partial attempt; completion of the first session exposes the second. Longer plans can approve both before starting, while a 20-minute plan keeps the first and reports that the second does not fit. Replay preserves earlier attempts and completed progress. The two-session journey was merged through PR #10 as `19f4339`. The [ten-nap trial guide](Ten-Nap-Trial.md) now prepares the next milestone; actual naps, deferred direct observations, and a public-safe closeout report remain pending.

The current UI slice adds a session picker and detail with real notes/source links; transactionally applied time and sound sheets; and Settings routes to Rest defaults, the one real journey and its two sessions, the packaged-audio inventory, current Enthusiast detail information, and a 12-second George preview. The inventory rechecks bundled assets but cannot download or delete them. Preview is explicitly started, does not write history or schedule alarms, and is blocked during an active rest or Feasibility Lab audio. Saved defaults affect only a new unreviewed plan, never an approved route. There are no next-journey IDs in the current catalog, so the branch-choice concept has no current route. Additional sessions, alternate detail recordings or voices, random/restart controls, and download management remain later work. These UI additions do not close the pending physical-device acceptance checks described above.

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
