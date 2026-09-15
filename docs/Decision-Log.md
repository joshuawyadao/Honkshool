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

Resolved on 2026-09-15 from the corrected device runs: D-001, D-002, D-003, and D-005. Their accepted decisions and evidence are recorded in the closeout section below. D-004 is explicitly deferred from Phase 0 to Phase 1.

| ID | Question | What must be learned | Needed before |
| --- | --- | --- | --- |
| D-004 | How should the planner absorb differences between estimated and actual narration duration? | Deferred from Phase 0 on 2026-09-15: preserve a fixed wake deadline, never accelerate speech, and fill unused time with ambience or silence. Measure the selected voice and specify overrun/partial-playback handling in Phase 1; the spike does not execute a timed Nap Plan. | Nap Plan domain rules |
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

## Phase 0 evidence: repaired device run, 2026-09-14

The owner completed the two focused checks on the repaired iPhone 14 Pro build. No personal alarm time, device identifier, or private diagnostic output is recorded.

- D-001/D-002: competing audio yielded; narration continued while locked; Lock Screen pause/resume/Stop, Siri interruption, and headphone disconnection behaved as specified. This supplies the missing corrected-device evidence for the direct-speech and interruption-policy decisions.
- D-003: a real locked alarm fired, snoozed to the same deadline shown in Honkshool, survived scrolling and force-quit/relaunch without resetting, fired again after the complete nine-minute interval, and stopped successfully. This supplies the missing AlarmKit reliability evidence.
- D-004: no numerical narration-duration measurements were supplied. Retain the safe fallback of a fixed wake alarm with unused plan time filled by ambience or silence, and resolve estimator variance during Nap Plan domain work.
- D-005: Lock Screen pause/resume/Stop passed and disabled skip/seek affordances remained acceptable. The snoozed AlarmKit Live Activity exposed one separate larger-text clipping defect; a compact, uncapped Dynamic Type layout and renderer regression address it, pending one visual confirmation on the system-hosted Lock Screen.
- Blocked-start feedback and active-alarm scrolling passed after repair.

## Phase 0 closeout: accepted decisions, 2026-09-15

- **D-001 — Direct speech:** Use AVSpeechSynthesizer directly for the initial prototype. Corrected-device background playback and controls passed. Buffered audio remains an alternative if measured reliability or timing requires it; comparative power/storage benchmarks were not performed.
- **D-002 — Interruption policy:** Pause for system interruptions and headphone loss, requiring explicit resume. Stop ends narration and ambience while leaving the separately managed wake alarm intact. Termination ends playback; relaunch does not automatically restart it. Siri and headphone checks passed; calls follow the same interruption policy but a separate real-call check was not performed.
- **D-003 — AlarmKit:** Proceed with Honkshool-owned alarms, retaining D-021's authorization/scheduling gate and the tested nine-minute snooze. Reconcile alarm state and snooze deadlines from the system. Locked delivery, cancellation, stop, termination/relaunch, and the full snooze re-ring passed. This establishes personal-prototype feasibility, not a reliability guarantee across all devices or OS versions.
- **D-005 — Lock Screen controls:** Offer play/pause and Stop through supported system media controls, ordinary audio metadata, and disabled skip/seek. Show snooze state and cancellation in the Live Activity. Visible but disabled skip/seek is acceptable; iOS controls the exact system layout.

The compact-layout repair was installed and launched on the iPhone 14 Pro. Nine deterministic UI tests passed on the connected device (reported iOS 26.6.2), separately from real alarm tests. The owner then confirmed that the snoozed Lock Screen card fits correctly with larger text and standard Display Zoom. This closes the final reported visual defect; the earlier failure record remains above.

Phase 0 is complete with D-004 explicitly deferred with the fallback above. Renderer coverage extends through the first accessibility text size, not every accessibility size. Replacement-device checks and numerical narration-duration calibration remain future evidence.

## Deferred beyond the first prototype

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
