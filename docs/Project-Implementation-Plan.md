# Honkshool project implementation plan

Build Honkshool as a sequence of small, reviewable vertical slices, beginning with the riskiest real-device behavior: calm background narration followed by ambience or silence and a dependable AlarmKit wake alarm. Keep this document as the roadmap, use the [product brief](Product-Brief.md) as the product source of truth, and record resolved questions in the [decision log](Decision-Log.md).

## Scope

- In: an iPhone-first iOS 26 app using Swift, SwiftUI, SwiftData, AlarmKit, and AVFoundation; prepared local Kokoro narration for the curated catalog; deterministic Nap Plans; background playback; a system alarm; local journey progress and history; and a ten-nap personal validation trial.
- Out: backend services, accounts, analytics, cloud sync, subscriptions, ads, paid speech APIs, runtime factual-content generation, arbitrary internet research, multiple production voices, App Store/TestFlight distribution, and the complete future content catalog.

## Action items

- [x] Resolve or explicitly defer the Phase 0 decision gates and run `spike/audio-and-alarm-feasibility` to establish narration, background audio, interruptions, Lock Screen controls, and AlarmKit feasibility on the target iPhone.
- [x] Implement `codex/nap-plan-domain` with framework-independent journey, session, route, timing, completion, and history rules plus focused unit tests. Runtime execution and persistence remain in later branches.
- [x] Build `codex/local-content-catalog` with a validated bundled catalog, one original citation-backed Enthusiast session from “How a Car Works,” source metadata, pronunciation guidance, configurable editorial estimates, and script-bound resume validation. Record F as the provisional narration reference.
- [x] Prepare a full Mac narration audition and measure its duration; bundle a CC0 gentle-rain candidate with provenance and objective loop/level checks.
- [ ] Complete Phase 2 by validating the bundled Kokoro George `0.86` playback path on the target iPhone and accepting the complete 727.625-second session. Preparation, provenance, catalog timing, app playback, and automated deadline coverage are complete. On iPhone 18 Pro Max / iOS 27.0, the signed app launched, two focused fixture UI tests passed, and the owner reported locked playback and Lock Screen play/pause working. The remaining [manual device checks](Feasibility-Spike.md#manual-checks-to-do-later-on-iphone-18-pro-max--ios-270) are pending. Connect accepted rain during runtime work; silence remains the available fallback until that integration.
- [ ] Build `feature/nap-plan-review` so a listener can continue or select local content, choose a duration or wake time, inspect the fixed route, select ambience or silence, and confirm the final alarm.
- [ ] Build `feature/nap-playback-runtime` to execute the approved plan without mid-nap prompts, support background playback and appropriate media controls, transition after narration, and recover safely from expected audio interruptions.
- [ ] Build `feature/alarm-and-history` to schedule and manage only Honkshool alarms, persist partial and completed playback locally with SwiftData, advance sessions only on completion, and expose resume and history views.
- [ ] Build `feature/journey-branches` to finish the initial journey flow, preselect any recommended cross-journey route before playback, and preserve replay, restart, and alternate-branch history.
- [ ] Run `validation/ten-nap-trial`, record reliability and preference outcomes without analytics, fix launch-blocking defects, and decide whether the prototype merits further investment.

## Open questions

- None block creation of this roadmap. Product and technical questions that gate individual phases are tracked with owners and deadlines in the [decision log](Decision-Log.md).

## Delivery principles

- Treat each branch as a reviewable vertical slice with behavior, tests, documentation, and manual verification notes together.
- Keep `main` honest: do not claim a feature exists until its acceptance criteria pass on the supported device.
- Prefer native frameworks and small, explicit interfaces around speech, audio, alarms, persistence, and bundled content.
- Keep session duration configurable. The initial 12–15 minute target is an experiment, not a hard-coded invariant.
- Describe listening as content being “played.” Never infer learning, retention, sleep state, therapy, or treatment.
- Fix the playback route when the nap starts. No branch question, vibration, regenerated content, or other attention demand may be introduced mid-nap.
- Keep source citations with each session and visible in the app, but never read them aloud.

## Phase 0: feasibility and decisions

### Goal

Remove the largest technical risks before designing the full app around unverified assumptions.

### Current status

Complete as of 2026-09-15; squash-merged through PR #2 as `45dcc71`. Corrected-device checks passed for background narration, natural transitions, audio takeover, Lock Screen controls, Siri interruption, headphone disconnection, alarm delivery, cancellation, app relaunch, and the full nine-minute snooze re-ring. The owner confirmed the compact snoozed Live Activity fits at the existing larger text setting with standard Display Zoom. D-001, D-002, D-003, and D-005 are accepted. D-004 was deferred at Phase 0 closeout and subsequently resolved with D-009 for Phase 1; the dated decision history remains in the decision log.

### Work

- Create the smallest installable iOS 26 spike necessary to exercise AVSpeechSynthesizer, AVAudioSession, optional ambience, Lock Screen media controls, and AlarmKit.
- Evaluate direct speech and consider a locally buffered alternative. Direct speech passed the required device behaviors and is accepted for the prototype; comparative power/storage benchmarks and quantitative duration calibration are deferred, not claimed complete.
- Verify alarm authorization, scheduling, cancellation, stop/snooze behavior, background reliability, and recovery after app relaunch on the personal target iPhone.
- Defer detailed narration-estimate variance rules to Phase 1 while preserving a fixed wake deadline, unchanged speech speed, and ambience/silence for unused time.
- Record device model, iOS build, test cases, results, and decisions without checking in personal identifiers or diagnostic exports.

### Exit criteria

- A target-device run can lock the screen, play a short factual script without unrelated audio, transition predictably, and produce the intended system alarm.
- Expected behavior is documented for interruption, route change, phone call, manual pause, app termination, and alarm-permission denial.
- Pending decisions D-001 through D-005 in the [decision log](Decision-Log.md) are resolved or explicitly deferred with a safe fallback.

## Phase 1: nap-planning core

### Goal

Represent content and assemble a deterministic Nap Plan without coupling the rules to SwiftUI, SwiftData, speech, or AlarmKit.

### Current status

Implemented on `codex/nap-plan-domain` on 2026-09-15 and squash-merged through PR #3 as `c5025ad`. The Foundation-only core snapshots deterministic plans, explicit approved routes and shorter alternatives, timing/fallback segments, and optional alarm deadlines. Pure playback outcomes retain partial checkpoints and advance progress only on actual completion; append-only history preserves replay, restart, and alternate paths. See [Nap-Planning-Domain.md](Nap-Planning-Domain.md) for allocation policy and the future adapter contract. This branch does not connect the domain to the feasibility console or provide persistence. Prepared local content follows below.

### Core concepts

- `Journey`: a finite ordered set of sessions and the branches available at completion.
- `Session`: stable identity, content revision, title, and configurable duration estimate now; original script, source references, summary, detail level, and pronunciation guidance in Phase 2.
- `NapRequest`: selected duration or wake time, starting point, post-journey behavior, ambience, and alarm preference.
- `NapPlan`: immutable approved route containing settling, factual sessions, drift, ambience or silence, and optional alarm timing.
- `PlaybackRecord`: in-memory evidence of what was played, for how long, and whether it completed, including revision-specific resume information; local persistence follows in Phase 3.

### Exit criteria

- Unit tests cover exact fit, unused time, short naps, long naps that cross a journey boundary, no available next session, silence fallback, and estimated-duration variance policy.
- Journey advancement occurs only after the current session plays to completion.
- Replaying, restarting, and selecting a different branch never erase prior history.
- The route cannot change after the plan is approved and playback begins.

## Phase 2: prepared content

### Current status

The catalog slice is implemented on `codex/local-content-catalog` (2026-09-16): bundled original prose, paragraph-linked sources, summary, pronunciation guidance, validated stable identities/references, configurable estimates, planner integration, and script-aware resume checks. The feasibility console continues to use its separate spike script. See [Content-Catalog.md](Content-Catalog.md) and [Content-Review.md](Content-Review.md).

The first full Mac audition measured 674.222 seconds on 2026-09-17 and remains historical Apple-voice evidence. A CC0 rain candidate is bundled with provenance and objective checks. F, the Aaron full-session master, and the Apple voice comparisons remain preserved evidence. The Apple Premium voices improved pronunciation but retained automated cadence. On 2026-09-21 the owner found both evaluated Kokoro voices much more human and natural, preferred George's calm documentary quality, and selected George at model speed `0.86` after a 408-word factual comparison. See [Audio-Preparation.md](Audio-Preparation.md) and the [accepted Kokoro evidence](Narration-Reference.md#accepted-kokoro-george-direction-2026-09-21).

George `0.86` is now the preferred narration reference; a curated selector is deferred. D-023 supersedes direct AVSpeechSynthesizer as the production sound direction while retaining the Phase 0 device evidence. D-024 selects preparation-time generation for the curated prototype: the app bundles a verified 34,926,044-byte PCM session rather than the 327,212,226-byte model and a live inference runtime. The asset measures 727.625 seconds, the current estimate is 730 seconds, and the feasibility console plays it with fixed-deadline stopping and no Apple fallback. The prepared-audio app installed and launched on iPhone 18 Pro Max / iOS 27.0 on 2026-09-22. Two focused fixture UI tests passed on that phone, and the owner reported locked playback and Lock Screen play/pause working. The full iOS 27.0 simulator suite passes 135 tests with one intentionally skipped device-only test, including checks that read every George PCM frame through AVFoundation and observe real AVAudioPlayer tail completion into ambience and fixed-deadline stopping without a 15-minute wait. An opt-in real-device XCTest passed on iPhone 18 Pro Max / iOS 27.0: AlarmKit reported alerting within five seconds of a shared 75-second wake deadline, and George narration stopped within three seconds with the wake-deadline status. Brief target-iPhone interruption/route checks, representative listening, rain acceptance, and production Nap Plan/history connection remain pending. Complete-session subjective comfort, audible alarm quality, and locked-screen alarm presentation remain unverified, so Phase 2 exit criteria are not yet complete.

### Goal

Create enough lawful, reliable local content to evaluate the experience without a backend or runtime generation.

### Work

- Choose one representative “How a Car Works” session for the tracer bullet.
- Research it from multiple reputable sources, cross-check factual claims, write an original calm script, and retain source citations.
- Tune punctuation, paragraphs, pauses, vocabulary, and pronunciation against the selected Kokoro George `0.86` reference at Enthusiast detail.
- Prepare and validate exact local narration assets before adding them to the app; keep live inference outside the curated prototype unless catalog scale justifies it.
- Add one offline ambience option with documented provenance and silence as an always-available alternative.
- Keep the catalog format capable of adding the remaining journey sessions and future per-journey detail levels without changing the playback contract.

### Exit criteria

- The session is fact-checked, citation-backed, original, understandable without visuals, and free of alarming repair/failure framing.
- Measured narration duration and configured estimate are recorded.
- The ambience asset can lawfully ship in a public repository and personal build.

## Phase 3: first end-to-end tracer bullet

### Goal

Prove the exact habit Honkshool is intended to replace:

> Open app → choose content → choose nap duration → review the Nap Plan → start resting.

### Minimum user flow

1. Continue or choose the bundled automotive session.
2. Select a nap duration or wake time using native iOS patterns.
3. Review the fixed Nap Plan, including narration, post-narration behavior, ambience, and alarm.
4. Start the plan, lock the phone, and listen without in-app attention prompts.
5. Transition to offline ambience or silence.
6. Receive the scheduled AlarmKit alarm when enabled.
7. See the session recorded as partially played or completed in local history.

### Exit criteria

- The flow works on the target iPhone with the screen locked and the app backgrounded.
- Pause, resume, stop, and system interruptions do not incorrectly mark a session complete.
- Alarm denial and unavailable ambience degrade to clear pre-nap messaging and safe behavior.
- Accessibility labels, Dynamic Type, reduced-motion behavior, and VoiceOver order are checked for the core flow.

## Phase 4: journey continuity

### Goal

Extend the tracer bullet into the smallest coherent journey experience while preserving the listener’s path.

### Work

- Add the remaining prepared “How a Car Works” sessions as content is researched and reviewed.
- Support continue, explore, random topic, replay, restart, skipped branches, and alternate branches.
- Show a selected cross-journey recommendation in the Nap Plan before a long nap starts.
- Preserve chronological listening history and the personal knowledge-tree path without claiming mastery or retention.

### Exit criteria

- Journey and session identity remain stable across content updates.
- Branch changes append to history rather than rewriting it.
- Local data migration tests protect saved progress as the schema evolves.
- No accounts, sync, or network availability are required.

## Phase 5: ten-nap validation

### Goal

Determine whether the narrow product actually replaces browsing YouTube for nap audio.

### Measures

- Choice: Honkshool is naturally selected for most of approximately ten real naps.
- Calmness: narration and transitions feel uninterrupted and non-stimulating.
- Reliability: playback and alarms behave dependably on the personal target iPhone.
- Fit: the assembled plan matches the selected rest window closely enough without changing narration speed.
- Recovery: missed or partial sessions are easy to find and replay.

Record a lightweight manual trial log locally. Do not add analytics or transmit listening behavior.

### Exit criteria

- Results, defects, and qualitative notes are summarized in a public-safe validation report.
- A deliberate continue/pivot/stop decision is recorded.
- Future work is prioritized from observed use rather than automatically expanding the initial scope.

## Test strategy

- Domain unit tests: Nap Plan assembly, timing edges, immutable routes, progress, completion, branching, replay, and fallback rules.
- Persistence integration tests: SwiftData round trips, migrations, partial playback, history preservation, and stable content identifiers.
- Adapter tests: deterministic fakes for speech timing, audio state, alarm scheduling, and permission failures.
- UI tests: only the critical choose → review → start → history path and permission-state presentation.
- Physical-device acceptance: background playback, Lock Screen controls, route changes, interruptions, app relaunch, and AlarmKit behavior. Simulator results are not sufficient for these risks.
- Content checks: required citations, unique stable identifiers, valid branch targets, non-empty scripts, configurable durations, and language-claim guardrails.

## Documentation upkeep

- Update [Product-Brief.md](Product-Brief.md) only when the product boundary changes.
- Add or amend entries in [Decision-Log.md](Decision-Log.md) when a consequential choice is made; do not silently rewrite decision history.
- Update this plan at the end of each feature branch: mark completed work, record the next branch, and revise later phases using evidence learned.
- Keep [Project-Overview.md](Project-Overview.md) and the root [README](../README.md) aligned with what is actually available.
- Add setup, signing, supported-device, and troubleshooting instructions when the first Xcode project is created.
