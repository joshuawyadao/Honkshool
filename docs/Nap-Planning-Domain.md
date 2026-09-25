# Nap-planning domain

The Foundation-only types in `Honkshool/Domain/NapContent.swift`, `NapPlan.swift`, `NapPlanReview.swift`, and `NapPlayback.swift` implement planning, review, and playback evidence. They have no SwiftUI, SwiftData, AVFoundation, or AlarmKit dependencies. `NapRunController` executes alarm-free confirmed plans using prepared audio; the feasibility console keeps its separate spike services.

## Inputs and identity

- `Session` has a catalog-supplied stable ID, content revision, title, and positive finite duration estimate in seconds. Estimates are configurable; 12–15 minutes is not a domain constant. Titles and estimates can change without changing identity. Change the revision when the script or its resume positions change.
- `Journey` orders session IDs and names the journey IDs available at its boundary. `NapCatalog` snapshots the available journeys and sessions and rejects duplicate IDs. References to unprepared content are allowed so planning can end with fallback.
- `NapRequest` selects a starting session, optional resume point, duration or exact wake time, settling/drift durations, ambience or silence, and alarm preference. The caller supplies `now`, planned start, plan ID, content availability, and available ambience IDs. The planner reads no clock, preferences, random source, or network.
- Starting a new journey or restarting selects its first session. Replaying selects the desired session with no resume point. Continuing uses history's next incomplete session or an explicitly chosen partial record. These choices never mutate history.

The [prepared-content catalog](Content-Catalog.md) adds original scripts, citations, detail metadata, pronunciation guidance, and editorial estimate provenance around these domain types. Prepared narration is bundled and connected to the alarm-free run controller; rain acceptance remains open. `PreparedCatalog.planningCatalog` supplies the timing and listening identities to the planner.

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

`NapPlanReviewState.review` receives an explicit plan ID, request, start/now dates, catalog, and available ambience IDs. It stores the returned `NapPlan` plus the review time, selected inputs, requested sound, preapproved transitions, and journey-title snapshots for the full ordered route. The screen plans a rest start 60 seconds after review for duration mode. For an exact wake time less than two minutes away, the planned start falls halfway between review and wake; otherwise it is 60 seconds ahead. The screen shows the planned start and fixed wake deadline with seconds. Duration mode measures the entire selected window from that planned start; exact wake mode keeps the chosen absolute deadline. A failed review clears any stale unconfirmed review. `confirm(at:)` requires an injected confirmation time from review time through the planned start and before the deadline; it retains the exact reviewed value without replanning. If the clock moves backward or the start has passed, the SwiftUI screen generates a new review and requires the listener to inspect and confirm the updated deadline and route. A past exact wake time instead requires a new selection. Later review attempts cannot replace a confirmed value. Confirmation only approves the route; a separate Start resting action asks the runtime to execute it. The runtime refuses a start request after the approved planned start and never silently executes an outdated route.

The screen derives a review catalog from bundled sessions with a resolvable narration file. This keeps unavailable audio out of both the content picker and later sessions on the proposed route. The availability predicate is injected for deterministic tests; normal app use checks the app bundle.

## Actual playback and deadlines

`NapPlayback` is pure bookkeeping for one plan and a caller-supplied unique run ID. It has no scheduler or media behavior. `nextSession(at:)` exposes only the next approved session after settling and before the deadline. Only `recordSession(... outcome: .completed)` advances that index. Finishing early can start the next approved session early; it never discovers or appends content.

After all approved sessions complete, `remainingRestSegments()` gives drift and rest from the actual final completion time to the original deadline. Overruns may consume planned drift/rest or prevent later sessions from starting. `mustStop(at:)` is true at the deadline, with or without an alarm. It never changes speech speed or moves the deadline.

A production adapter must:

- schedule the cutoff and optional wake alarm for the original deadline; preserve D-021's alarm authorization/scheduling gate before starting;
- supply actual event timestamps and active played duration, excluding pauses;
- report `.completed` only when the session genuinely reaches its end, including an actual end exactly at the deadline;
- stop unfinished narration at the deadline and supply the real cutoff checkpoint with a partial outcome; and
- ignore cancelled/stale callbacks and avoid resuming speech automatically after interruption or termination.

The model rejects completed outcomes and ordinary partial outcomes with end timestamps after the deadline. A delayed cutoff may record `.deadlineMissed` with the actual late stop time only when the audio position, active played duration, and checkpoint time were verified at or before the deadline. It does not clamp a late callback's position or invent how far playback had reached at the cutoff. Estimates and elapsed duration alone never prove completion.

## Partial playback and history

`ResumePoint` contains session ID, exact content revision, UTF-16 script offset, and an independently supplied remaining-duration estimate. The future script/speech adapter owns valid script boundaries and the estimate. A UTF-16 offset is not a number of seconds and cannot be derived from a percentage of the original estimate. The domain rejects mismatched revisions/IDs, negative offsets, invalid remaining estimates, and backward movement from a resumed position.

Partial outcomes record stopped, interrupted, deadline-reached, or missed-deadline playback. A partial event at the deadline is classified as deadline-reached. A terminal partial record closes that run; its checkpoint can start a later reviewed plan. Pausing and resuming within an ongoing nap does not append a terminal record. `ResumePoint` represents either a UTF-16 script boundary or a prepared-audio time in seconds, always bound to the exact session revision; neither position is inferred from the other. `PreparedSession.narration(resumingAt:)` accepts only script positions at intact Swift Character boundaries. `PreparedSession.validateAudioResumePoint(_:)` checks that an audio position lies before the exact bundled render's end. The run controller uses the player's audio position and measured remaining file duration for partial evidence. Resume selection and durable history UI remain future work.

`ListeningHistory` appends immutable records identified by run ID and route index. Duplicate record IDs are rejected. Records retain plan identity, journey/session identity and revision, starting checkpoint, event dates, played duration, and final outcome. Replay, restart, and alternate branches create new runs and append records; no reset or replacement operation exists. Each partial record stays resumable by its own ID even after later playback completes.

Journey progress consists of actually completed session IDs in that journey. `nextSessionID(in:)` returns its first incomplete session, so playing a later session does not skip an earlier gap. A partial replay cannot undo earlier completion. IDs remain catalog-owned; future persistence must preserve them and run identities across launches. Records describe what was **played** and **completed**, with no claim about awareness or retention.

## Verification and remaining work

`NapPlannerTests` covers timing, content availability, selection, transitions, snapshots, and invalid inputs. `NapPlaybackTests` covers actual completion, cutoff evidence, early and late narration, resume, route invariants, and history preservation. Both run through the existing Xcode test target and `scripts/test-ios.sh`; the three new source files also typecheck independently with Foundation on macOS.

Validation on 2026-09-15 used Xcode 27.0 and iPhone 17 Pro / iOS 26.5 Simulator: 45 focused domain tests passed, the full unit/UI suite passed 103 tests with no failures or skips, and all 12 repository checks passed. Foundation-only compilation, strict formatting lint for new Swift files, and the Release simulator build also passed. Xcode reported one internal thread-priority (QoS) warning during the full suite; this did not fail validation. CI runs on pull requests or manual dispatch, so pushing this branch alone does not trigger CI.

The 2026-09-22 review slice adds five `NapPlanReviewTests` and three `NapPlanReviewUITests`. On the 2026-09-23 main-based branch, availability filtering adds one test at each level. The focused iOS 26.5 review run passed all ten tests; the full suite passed 151 tests with one intentionally skipped device-only test, and 31 repository checks passed. These tests verify the approval snapshot, displayed route, and exclusion of unavailable narration; they do not establish real playback or AlarmKit behavior for confirmed plans.

The prepared-content catalog supplies the citation-backed session, and the Nap Plan UI can choose, review, and start an alarm-free run. `NapRunController` resolves the exact approved assets before start, requires the app to stay foregrounded until narration begins, keeps the fixed cutoff even through pause or interruption, records successful natural endings and verified partial checkpoints in memory, and rests in silence after narration. Leaving the app before narration starts ends the pending run and requires a new review; once narration is playing, the app's audio background mode supports locking the screen. It refuses alarm-requested plans until the promised alarm can be scheduled. If the cutoff callback is late, the controller records the actual late stop and the last verified pre-deadline audio checkpoint without claiming an on-time stop. Remaining work includes target-iPhone runtime and full-session listening acceptance, rain acceptance, production AlarmKit scheduling, and SwiftData history. Simulator evidence does not establish locked-device reliability.
