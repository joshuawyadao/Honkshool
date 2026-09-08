# Decision log

This log preserves consequential Honkshool product and technical choices. The [product brief](Product-Brief.md) records the stable product boundary; the [project implementation plan](Project-Implementation-Plan.md) records sequence and status.

## How to use this log

- Give each consequential choice a stable ID.
- Record the decision, rationale, date, and evidence in a pull request.
- Do not silently rewrite an accepted decision. Add a superseding entry that links to the earlier one.
- Resolve a pending decision by moving it to the accepted table and updating the work it gates.
- Keep routine implementation details in code and pull requests rather than turning every choice into a formal entry.

## Accepted decisions

| ID | Decision | Rationale | Status |
| --- | --- | --- | --- |
| D-000 | Treat this document as an append-only decision history. | Future contributors and agents need to distinguish established constraints from current questions. | Accepted 2026-09-04 |
| D-010 | Optimize first for relaxation and uninterrupted rest; factual exposure is secondary. | This is the core product distinction and determines content, pacing, and interaction design. | Accepted 2026-09-04 |
| D-011 | Describe content as “played,” never as learned, retained, therapy, or medical treatment. | Playback completion cannot establish awareness, learning, or a health outcome. | Accepted 2026-09-04 |
| D-012 | Use finite, branching journeys and preserve every historical path. | Listeners need continuity without losing replay, restart, skipped-branch, or alternate-branch history. | Accepted 2026-09-04 |
| D-013 | Freeze the playback route when a Nap Plan starts. | A sleeping listener must not receive branch prompts or other attention demands. | Accepted 2026-09-04 |
| D-014 | Start with a tiny bundled automotive catalog at Enthusiast detail. | This proves the experience without live research, runtime generation, a backend, or premature catalog scale. | Accepted 2026-09-04 |
| D-015 | Keep first-version data local with no account, cloud sync, or analytics. | The personal prototype does not need network identity or behavioral data collection. | Accepted 2026-09-04 |
| D-016 | Target iPhone and iOS 26 using Swift, SwiftUI, SwiftData, AlarmKit, AVFoundation, and AVSpeechSynthesizer, subject to the feasibility spike. | Native frameworks fit the personal-device scope and avoid recurring services and third-party dependencies. | Accepted 2026-09-04 |
| D-017 | Validate the product with approximately ten real naps before expanding scope. | Actual habit replacement, calmness, and reliability matter more than feature count. | Accepted 2026-09-04 |
| D-018 | Use `com.joshuawyadao.Honkshool` as the bundle identifier and test first on an iPhone 14 Pro running iOS 26.6.1, then on the intended replacement iPhone. | A stable identifier and named physical baseline make signing and device evidence reproducible without publishing device identifiers. | Accepted 2026-09-04 |
| D-019 | Use “Turning Fuel Into Motion” as the first narration example. | It exercises calm engineering explanation and pronunciation without requiring detailed repair instructions. | Accepted 2026-09-04 |
| D-020 | Offer recommended 20, 30, 45, and 60-minute rest windows, exact custom timing, and one reusable saved default; initialize the personal spike at 35 minutes. | The owner typically allows a 35-minute window for a desired 20-minute nap, while the app must not claim how much actual sleep occurs. | Accepted 2026-09-04 |
| D-021 | Block an alarm-enabled run until AlarmKit is authorized and the requested alarm schedules successfully. | A plan that promises a wake alarm must never begin after silently losing that guarantee; the user may explicitly disable the alarm instead. | Accepted 2026-09-04 |
| D-022 | Activate an exclusive playback audio session when a Honkshool run begins. | Existing music or podcast audio should yield so Honkshool provides one controlled, uninterrupted route. | Accepted 2026-09-04 |

## Pending decisions

| ID | Question | What must be learned | Needed before |
| --- | --- | --- | --- |
| D-001 | Should narration stream directly from AVSpeechSynthesizer or use a locally rendered/buffered strategy? | Compare background reliability, pause/resume, timing precision, Lock Screen control, power, storage, and implementation complexity on the target device. | Playback architecture in Phase 1 |
| D-002 | What audio-session and interruption policy should the prototype use? | Define behavior for phone calls, Siri, headphones disconnecting, route changes, other audio, manual pause, and app termination. | First tracer-bullet implementation |
| D-003 | Does AlarmKit meet the required physical-device reliability and system interaction expectations? | The blocking authorization and scheduling policy is accepted in D-021; verify system prompts, firing after backgrounding or termination, cancellation, stop, snooze, and relaunch reconciliation. | Nap Plan review and alarm integration |
| D-004 | How should the planner absorb differences between estimated and actual narration duration? | Measure the selected voice and decide where slack, drift, ambience, or silence may adjust without changing narration speed or wake time. | Nap Plan domain rules |
| D-005 | Which Lock Screen controls and Now Playing metadata belong in the first release? | Balance familiar control with protection against accidental route changes or misleading progress. | Playback runtime |
| D-007 | Which Apple voice, locale, base rate, pause conventions, and pronunciation mechanism should be standardized? | Run short listening comparisons on the target iPhone and document repeatable narration settings. | Prepared content branch |
| D-008 | Which ambience asset can lawfully be distributed offline? | Confirm license/provenance, loop quality, file size, loudness, and interaction with narration and drift. | Prepared content branch |
| D-009 | How should a short rest window behave when no complete factual session fits? | D-020 resolves selection and saved-default behavior; decide whether insufficient windows use a shorter selection, ambience only, or prevent starting. | Nap Plan domain rules |

## Phase 0 evidence: first device run, 2026-09-08

The owner tested on iPhone 14 Pro / iOS 26.6.1 and designated unannotated steps in the chat checklist as passing. The detailed record is in [Feasibility-Spike.md](Feasibility-Spike.md).

- D-001/D-002: locked narration, audio takeover, natural ambience/silence transitions, Siri interruption, and headphone-disconnection behavior passed as reported. Stop incorrectly started ambience; the repair invalidates speech callbacks before cancellation. Playback strategy remains pending the corrected device run.
- D-003: basic alarm firing, cancellation, stop, and firing after app termination passed as reported. Snooze feedback failed; the owner cancelled before the nine-minute interval elapsed. Add system state reconciliation and the AlarmKit countdown Live Activity, then verify the full snooze cycle before accepting reliability.
- D-004: the owner accepted timing behavior but did not provide measured durations; planner timing decisions remain pending.
- D-005: disabled skip/seek controls are acceptable. Usable pause/resume remains required; the first build exposed Stop instead. The repaired build advertises ordinary audio and explicitly handles toggle commands. Confirm the actual Lock Screen layout on device.
- Blocked-start feedback and scrolling also require device retesting after repairs. These are usability defects, not changes to the standing product constraints.

## Deferred decisions

These are intentionally outside the first prototype and should not block the current roadmap:

- Additional voices and a user-facing voice selector.
- Relaxed Overview and Technical content variants.
- “Simpler next time” and “Go deeper next time” controls.
- Download management and automatic audio-file cleanup.
- Live research, runtime generation, or backend content delivery.
- Accounts, iCloud sync, analytics, monetization, and subscriptions.
- TestFlight, App Store distribution, brand identity, and broader device support.

## Decision template

When resolving a pending question, use this structure in the pull request or a short supporting document:

```text
ID and title:
Status and date:
Decision:
Context:
Options considered:
Evidence:
Consequences and follow-up:
Supersedes (if any):
```
