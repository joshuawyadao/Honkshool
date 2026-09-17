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
| D-006 | Which “How a Car Works” session is the first representative script? Resolved by D-019: “Turning Fuel Into Motion.” | Preserve the original pending question's stable ID and link to its accepted outcome instead of deleting its history. | Resolved by D-019; cross-reference restored 2026-09-15 |
| D-020 | Offer recommended 20, 30, 45, and 60-minute rest windows, exact custom timing, and one reusable saved default; initialize the personal spike at 35 minutes. | The owner typically allows a 35-minute window for a desired 20-minute nap, while the app must not claim how much actual sleep occurs. | Accepted 2026-09-04 |
| D-021 | Block an alarm-enabled run until AlarmKit is authorized and the requested alarm schedules successfully. | A plan that promises a wake alarm must never begin after silently losing that guarantee; the user may explicitly disable the alarm instead. | Accepted 2026-09-04 |
| D-022 | Activate an exclusive playback audio session when a Honkshool run begins. | Existing music or podcast audio should yield so Honkshool provides one controlled, uninterrupted route. | Accepted 2026-09-04 |
| D-004 | Keep the planned wake deadline fixed. Stop narration at that deadline, retain partial progress for resumption, and mark a session complete only when playback actually reaches its end. Fill unused time with the selected ambience or silence; never accelerate speech or delay the alarm. | Duration estimates can differ from actual narration, but rest timing and honest completion history must remain dependable. | Accepted 2026-09-15; resolves the Phase 0 deferral below |
| D-009 | If no complete factual session fits, use the selected ambience or silence. An already available shorter factual session may be selected if it fits; never generate, compress, or truncate a session merely to fit. Show the resulting plan before starting. | Short rest windows must remain useful and predictable without rushing narration or hiding a changed plan. | Accepted 2026-09-15 |

## Pending decisions

Resolved on 2026-09-15 from the corrected device runs: D-001, D-002, D-003, and D-005. Their accepted decisions and evidence are recorded in the closeout section below. The owner subsequently resolved D-004 and D-009 for Phase 1; the dated timing resolution below preserves their earlier questions and Phase 0 deferral.

| ID | Question | What must be learned | Needed before |
| --- | --- | --- | --- |
| D-007 | Which Apple voice, locale, base rate, pause conventions, and pronunciation mechanism should be standardized? | Sound direction provisionally accepted 2026-09-16; full Mac audition prepared and measured 2026-09-17 below. Tempo and cadence approved in the sibilance follow-up below; robotic consonants remain unresolved. Still verify full-session pronunciation and comfort, headphone listening, target-iPhone voice availability, and equivalent intended playback. | Final narration settings and production playback integration |
| D-008 | Which ambience asset can lawfully be distributed offline? | Gentle-rain direction accepted 2026-09-16; alxl CC0 source, provenance, prepared loop, file size, and signal levels documented 2026-09-17 below. Still verify perceived loop quality, comfort, narration/drift interaction, user acceptance, and runtime integration. | Enabling the prepared ambience candidate in playback |

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

Phase 0 is complete. At its closeout, D-004 was explicitly deferred with the fallback above; the subsequent Phase 1 timing resolution below closes that product question. Renderer coverage extends through the first accessibility text size, not every accessibility size. Replacement-device checks and numerical narration-duration calibration remain future evidence.

## Phase 1 timing resolution, 2026-09-15

The owner approved the following product rules before implementation of the nap-planning domain. This approval resolves the pending choices; it does not supply numerical voice-duration measurements or runtime enforcement evidence.

- **D-004 — Estimated versus actual narration duration:** The original question was how the planner should absorb differences between estimated and actual narration duration. Phase 0 deferred the full rule while retaining a fixed wake deadline, no speech acceleration, and ambience or silence for unused time. The approved resolution keeps that deadline fixed even when narration overruns: stop narration at the deadline, keep partial progress available for later resumption, and do not mark an unfinished session complete. Never accelerate speech or delay the alarm. Early completion leaves the remaining time for the selected ambience or silence. Configurable duration estimates and later voice calibration support planning; neither changes the deadline or completion rule.
- **D-009 — Short rest windows:** The original question was whether a window too short for a complete factual session should select shorter content, use ambience only, or prevent starting; D-020 had already settled timing selection and saved-default behavior. The approved resolution uses the selected ambience or silence when no complete session fits. A shorter factual session may be used when it is already available and fits. Do not generate, compress, or truncate a session merely to fit. Show the resulting plan before starting so the listener approves the route and fallback before resting.

These rules complete the product decisions needed for Nap Plan domain work. Production playback integration must later enforce the fixed deadline and supply actual completion and resume information; voice measurement remains part of prepared-content validation.

## Narration and ambience direction, 2026-09-16

The following records partial resolutions of D-007 and D-008 while preserving their original questions above. These choices permit continued development; they do not close the remaining device and asset checks.

- **D-007 — Provisional narration reference:** The owner accepted audition F, `F-Natural-syllables-focused-softening.wav`, after listening through MacBook speakers. Natural, human-sounding delivery is more important than slower syllables. A's delivery was preferred to slower B; C's additional sentence and paragraph pauses supplied the desired breathing room. E softened “s” sounds but made surrounding syllables robotic and distracting. F retains C's timing and original surrounding speech, applying E's softening only within narrow candidate bursts. Use F as the development and listening reference. Headphone/AirPods listening, target-iPhone voice availability and equivalent playback, technical pronunciation, and comfort over a full session remain unverified. The [narration reference](Narration-Reference.md) records the passage, settings, processing, fingerprint, measurements, and remaining checks.
- **D-001 — Runtime boundary unchanged:** Direct AVSpeechSynthesizer speech remains the accepted initial playback strategy. F is an offline processed Mac audition, not evidence that the exact result can be reproduced through that strategy on iPhone. The successful Mac audition used Siri Voice 1/Aaron through an interpreted Swift renderer. Do not infer availability of that exact voice in the compiled iPhone app or adopt buffered narration from this listening approval. A runtime change, if later needed to meet the accepted sound, requires its own explicit decision and supporting evidence.
- **D-008 — Ambience direction:** The owner selected gentle, steady rain for its consistent volume and texture. Avoid thunder, sudden surges, and sharp drips, and require a seamless loop. No final asset or distribution license has been accepted. Provenance, license, file size, loop quality, loudness, and interaction with narration and drift remain to be checked. Silence remains a valid selection and fallback.

## Audio preparation evidence, 2026-09-17

This preparation extends the earlier evidence without superseding the owner's acceptance of F or treating new audio as accepted. The [audio preparation record](Audio-Preparation.md), [narration measurements](Audio-Preparation-Measurements.json), and [rain provenance](../Honkshool/Resources/GentleRain-Provenance.json) contain the procedures and fingerprints.

- **D-007 — Full-session Mac audition:** All 13 unchanged paragraphs of *Turning Fuel Into Motion* were rendered at the reference's `0.45` base rate, one complete paragraph per utterance, with no pitch shift or time stretching. Local E/F processing restricts softening to narrow candidate bursts and preserves 92.67965% of gain-adjusted paragraph frames unchanged. Assembly adds one second between paragraphs and 0.25/0.50 seconds at the beginning/end; C's passage-specific sentence-gap insertions were not transferred. The result measures 674.222 seconds, supporting a configurable 675-second Mac-based planning estimate in place of the former unmeasured 765-second editorial estimate. F remains unchanged. Full narration and preview files stay outside the repository. The owner has not heard the new full session; pronunciation, perceived pacing, headphone comfort, and target-iPhone equivalence remain unverified.
- **D-008 — Prepared rain candidate:** The source is [*Rain on Window Loop* by alxl](https://opengameart.org/content/rain-on-window-loop). The page explicitly offers CC0 among alternative licenses; preparation selects [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/), records the original fingerprint and source, and packages a processed candidate. The mono 44.1 kHz 16-bit WAV is 870,248 bytes and 9.866259 seconds, with −33.000264 dBFS RMS, −18.320071 dBFS sample peak, no clipping, and 1.985587 dB variation across approximate half-second RMS windows. A tail/head crossfade and filtering prepare the boundary, but signal checks do not establish subjective seamlessness or the absence of distracting drips. User listening and the narration/drift combination remain pending. Packaging does not connect the candidate to the playback runtime or declare it accepted.
- **Runtime boundary:** D-001 remains unchanged. The committed preparation scripts use system frameworks and the Python standard library; local narration postprocessing used already available NumPy outside the app. No production speech processor, buffered narration engine, or new app dependency follows from this preparation. Direct-speech timing on iPhone must still be measured, and D-004's fixed deadline and actual completion rules remain authoritative.

## Narration sibilance follow-up, 2026-09-17

- **D-007 — Preserve tempo and cadence:** The owner approves the presented narration's tempo and cadence, while reporting robotic “s” syllables. Keep word timing and pauses unchanged. This feedback does not close voice quality, technical pronunciation, headphone/device checks, or rain acceptance.
- **Short comparison:** Candidate G restores the original closing paragraph and applies up to 3 dB of smooth level reduction in a stricter subset of noise-dominant regions. It avoids spectral signal reconstruction and preserves the full frame count and every sample outside its mask. The [reference record](Narration-Reference.md#sibilance-follow-up-2026-09-17) contains the settings, fingerprints, and verification. G remains unaccepted; the original F reference, full-session audition, estimate, and runtime decision are unchanged.

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
