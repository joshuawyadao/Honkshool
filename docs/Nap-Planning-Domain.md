# Nap-planning domain

The Foundation-only types in `Honkshool/Domain/NapContent.swift`, `NapPlan.swift`, and `NapPlayback.swift` implement Phase 1. They have no SwiftUI, SwiftData, AVFoundation, or AlarmKit dependencies. The feasibility console still uses its existing spike services; it does not execute these plans.

## Inputs and identity

- `Session` has a catalog-supplied stable ID, content revision, title, and positive finite duration estimate in seconds. Estimates are configurable; 12–15 minutes is not a domain constant. Titles and estimates can change without changing identity. Change the revision when the script or its resume positions change.
- `Journey` orders session IDs and names the journey IDs available at its boundary. `NapCatalog` snapshots the available journeys and sessions and rejects duplicate IDs. References to unprepared content are allowed so planning can end with fallback.
- `NapRequest` selects a starting session, optional resume point, duration or exact wake time, settling/drift durations, ambience or silence, and alarm preference. The caller supplies `now`, planned start, plan ID, content availability, and available ambience IDs. The planner reads no clock, preferences, random source, or network.
- Starting a new journey or restarting selects its first session. Replaying selects the desired session with no resume point. Continuing uses history's next incomplete session or an explicitly chosen partial record. These choices never mutate history.

The prepared-content branch will add original scripts, citations, detail metadata, pronunciations, and lawful asset provenance. This branch defines only the content metadata needed for timing and listening identity.

## Planning and review

`NapPlanner.makePlan` returns an immutable `NapPlan` with the hard deadline, optional alarm at that exact deadline, selected session snapshots, actual journey transitions, explicit estimated segments, resolved fallback, and reason factual selection ended. Review UI must show this result before starting, including any shorter alternative and unavailable-ambience fallback.

Allocation is deterministic:

1. Reject nonfinite, zero/negative windows, past starts, past/equal wake deadlines, and negative/nonfinite settling or drift inputs.
2. Reserve settling first, capped by the window, then drift, capped by the remaining window. These periods use the resolved ambience or silence. Drift here describes a timing period; it does not generate a shorter factual script.
3. Fit whole estimated sessions, or the whole estimated remainder of an explicitly resumed session, into the remaining narration budget. Exact fits are accepted. Relative estimate accumulation tolerates only `Date` representation rounding and clamps segment ends to the fixed deadline.
4. Follow the current journey's order. Never skip an oversized or missing session to find a later one that fits. Continue to another journey only through an explicit preapproved transition that appears in the journey's available branches. Ambiguous transitions and cycles are rejected.
5. If the main selection fits no narration, try the caller's ordered, preapproved shorter alternatives. Only available, fitting content is used. An invalid starting identity is an input error; a known session whose content is unprepared yields fallback. No alternative is discovered automatically.
6. When content ends, is missing, or does not fit, use drift followed by the selected ambience or silence through the deadline. Unavailable ambience resolves to silence. Short windows remain valid even when narration is empty.

`route`, `transitions`, session metadata, and the nominal timeline are value snapshots. Later request, catalog, or history changes cannot alter them. The route freezes when the plan is created, which is stronger than freezing only after start. Changed pre-nap choices require a new plan for review.

## Actual playback and deadlines

`NapPlayback` is pure bookkeeping for one plan and a caller-supplied unique run ID. It has no scheduler or media behavior. `nextSession(at:)` exposes only the next approved session after settling and before the deadline. Only `recordSession(... outcome: .completed)` advances that index. Finishing early can start the next approved session early; it never discovers or appends content.

After all approved sessions complete, `remainingRestSegments()` gives drift and rest from the actual final completion time to the original deadline. Overruns may consume planned drift/rest or prevent later sessions from starting. `mustStop(at:)` is true at the deadline, with or without an alarm. It never changes speech speed or moves the deadline.

A production adapter must:

- schedule the cutoff and optional wake alarm for the original deadline; preserve D-021's alarm authorization/scheduling gate before starting;
- supply actual event timestamps and active played duration, excluding pauses;
- report `.completed` only when the session genuinely reaches its end, including an actual end exactly at the deadline;
- stop unfinished narration at the deadline and supply the real cutoff checkpoint with a partial outcome; and
- ignore cancelled/stale callbacks and avoid resuming speech automatically after interruption or termination.

The model rejects end timestamps after the deadline. It does not clamp a late callback's content position or invent how far playback had reached at the cutoff. A callback delivered later can report valid evidence captured at or before the deadline. Estimates and elapsed duration alone never prove completion.

## Partial playback and history

`ResumePoint` contains session ID, exact content revision, UTF-16 script offset, and an independently supplied remaining-duration estimate. The future script/speech adapter owns valid script boundaries and the estimate. A UTF-16 offset is not a number of seconds and cannot be derived from a percentage of the original estimate. The domain rejects mismatched revisions/IDs, negative offsets, invalid remaining estimates, and backward movement from a resumed position.

Partial outcomes record stopped, interrupted, or deadline-reached playback. A partial event at the deadline is classified as deadline-reached. A terminal partial record closes that run; its checkpoint can start a later reviewed plan. Pausing and resuming within an ongoing nap belongs to future runtime bookkeeping and must not append a terminal record prematurely. The adapter must validate offsets against the actual script because this branch contains no script catalog or playback engine.

`ListeningHistory` appends immutable records identified by run ID and route index. Duplicate record IDs are rejected. Records retain plan identity, journey/session identity and revision, starting checkpoint, event dates, played duration, and final outcome. Replay, restart, and alternate branches create new runs and append records; no reset or replacement operation exists. Each partial record stays resumable by its own ID even after later playback completes.

Journey progress consists of actually completed session IDs in that journey. `nextSessionID(in:)` returns its first incomplete session, so playing a later session does not skip an earlier gap. A partial replay cannot undo earlier completion. IDs remain catalog-owned; future persistence must preserve them and run identities across launches. Records describe what was **played** and **completed**, with no claim about awareness or retention.

## Verification and remaining work

`NapPlannerTests` covers timing, content availability, selection, transitions, snapshots, and invalid inputs. `NapPlaybackTests` covers actual completion, cutoff evidence, early and late narration, resume, route invariants, and history preservation. Both run through the existing Xcode test target and `scripts/test-ios.sh`; the three new source files also typecheck independently with Foundation on macOS.

Validation on 2026-09-15 used Xcode 27.0 and iPhone 17 Pro / iOS 26.5 Simulator: 45 focused domain tests passed, the full unit/UI suite passed 103 tests with no failures or skips, and all 12 repository checks passed. Foundation-only compilation, strict formatting lint for new Swift files, and the Release simulator build also passed. Xcode reported one internal thread-priority (QoS) warning during the full suite; this did not fail validation. CI runs on pull requests or manual dispatch, so pushing this branch alone does not trigger CI.

The remaining roadmap starts with one prepared, citation-backed session and a lawful offline ambience asset, then plan-review UI, production playback/deadline adapters, and SwiftData history. Domain success does not establish runtime cutoff or alarm reliability. This branch requires no phone installation or new physical-device acceptance because it does not change those adapters.
