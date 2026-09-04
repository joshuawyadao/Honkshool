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

## Pending decisions

| ID | Question | What must be learned | Needed before |
| --- | --- | --- | --- |
| D-001 | Should narration stream directly from AVSpeechSynthesizer or use a locally rendered/buffered strategy? | Compare background reliability, pause/resume, timing precision, Lock Screen control, power, storage, and implementation complexity on the target device. | Playback architecture in Phase 1 |
| D-002 | What audio-session and interruption policy should the prototype use? | Define behavior for phone calls, Siri, headphones disconnecting, route changes, other audio, manual pause, and app termination. | First tracer-bullet implementation |
| D-003 | What AlarmKit authorization and failure experience is acceptable? | Verify target-device APIs and system UI; decide whether a plan can start without alarm permission and how clearly that state is shown before rest begins. | Nap Plan review and alarm integration |
| D-004 | How should the planner absorb differences between estimated and actual narration duration? | Measure the selected voice and decide where slack, drift, ambience, or silence may adjust without changing narration speed or wake time. | Nap Plan domain rules |
| D-005 | Which Lock Screen controls and Now Playing metadata belong in the first release? | Balance familiar control with protection against accidental route changes or misleading progress. | Playback runtime |
| D-006 | Which “How a Car Works” session is the first representative script? | Choose a topic that exercises pronunciation and mental-model writing without requiring visuals or alarming repair instructions. | Prepared content branch |
| D-007 | Which Apple voice, locale, base rate, pause conventions, and pronunciation mechanism should be standardized? | Run short listening comparisons on the target iPhone and document repeatable narration settings. | Prepared content branch |
| D-008 | Which ambience asset can lawfully be distributed offline? | Confirm license/provenance, loop quality, file size, loudness, and interaction with narration and drift. | Prepared content branch |
| D-009 | What are the minimum selectable nap durations and insufficient-time behavior? | Test whether the plan should offer a shortened content selection, ambience-only plan, or prevent plans too short for the first session. | Nap Plan domain rules |

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
