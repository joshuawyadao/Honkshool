# UX review acceptance and cycle closure

**Review cycle: Complete — November 16, 2026, at the owner's request.**

**Reviewed application baseline:** `b15484a` on `codex/ux-status-recovery-fixes`. This closure covers the November 10 review and follow-up remediation. Later documentation-only commits do not change that application baseline.

**Readiness for an unsupervised TestFlight trial: Incomplete.** Device operation, manual VoiceOver, and accessibility audit triage remain pending as listed below. Closing the review work does not mark those checks passed or approve distribution.

> UX review and remediation completed for the reviewed build. Reported product defects are fixed with regression coverage. Physical-device operation, manual VoiceOver, and remaining accessibility audit candidates require separate validation.

## Acceptance criteria for completing a review cycle

These criteria define when the review-and-remediation work can stop. They do not replace the required evidence for a named testing or release stage.

| Criterion | Acceptance evidence | Disposition for this baseline |
| --- | --- | --- |
| Core journeys covered | Record the build, environment, starting state, steps, visible feedback and outcomes for setup, review, confirm/start, stop, History, and recovery. Label partial or untested operation explicitly. | Met in the simulator/captured-transition scope; physical operation is pending. |
| Reported defects addressed | Fix and retest each confirmed defect, or explicitly defer it with a reason. Keep no unresolved blocker in the reviewed scope; record any deferred material issue in the readiness assessment. | Met: UX-001–003 and UX-005–007 are fixed and verified within the recorded test scope. No confirmed blocker remains from this cycle. |
| Regression protection | Preserve meaningful assertions for the corrected failures. Explain test/environment failures and verify the affected checks after correction. | Met: six new follow-up UI regressions, existing regression coverage, and successful final validation. The initial full-suite automation failure and its correction remain recorded. |
| Representative layouts checked | Inspect core feedback and controls on the agreed phone sizes, light/dark appearances, and largest text. Preserve full timing values and reachable actions. | Met within inspected configurations; this is not comprehensive device or accessibility conformance. |
| Findings and limitations recorded | Give every remaining item a status and a concrete next action. Keep unperformed checks unverified, with their readiness implications visible. | Met: the pending register below retains J12, A05, and A04/UX-004. Human learnability is also unverified. |

The first-use cognitive walkthrough inspected captured transitions and their visible cues. It did not measure participant comprehension, frustration, task time, or learnability. Human testing can remain deferred without requiring the review workflow to repeat.

## Product findings closed

All six confirmed product findings are **Fixed and verified** within the simulator/service evidence scope. UX-004 is a validation item and remains separate.

| Finding | Verified result | Permanent regression reference |
| --- | --- | --- |
| UX-001 — uncertain retained-alarm assurance | Unreadable alarm state does not claim the alarm is verified; retry/cancel and the prior-alarm gate remain. | `testUnverifiedRetainedAlarmDoesNotClaimItIsSet` in [NapPlanReviewUITests](../HonkshoolUITests/NapPlanReviewUITests.swift), plus [alarm-service tests](../HonkshoolTests/NapPlanAlarmServiceTests.swift). |
| UX-002 — stale Ready state | An expired approved start replaces Start with renewed review, including lifecycle/permission recovery. | `testReadyExpiresWithoutTapAndRequiresFreshReview` and `testAlarmPrimerExpiresWhileBackgroundedAndReturnsToReviewAtLargestText` in [NapPlanReviewUITests](../HonkshoolUITests/NapPlanReviewUITests.swift). |
| UX-003 — silence-only playback wording | Quiet-rest waiting, ending, and End rest describe the actual state without inventing narration history. | `testShortWindowReviewsSilenceOnlyAndNoAlarm` in [NapPlanReviewUITests](../HonkshoolUITests/NapPlanReviewUITests.swift), plus [run-controller tests](../HonkshoolTests/NapRunControllerTests.swift). |
| UX-005 — sound-only setup wording | Sound-only review, Ready, permission, and sound-choice wording describe rest and its actual sound. | `testRainOnlyPlanDescribesRestSoundWithoutNarrationPromises`, extended silence-only assertions, and [Settings summary tests](../HonkshoolUITests/FunctionalPagesUITests.swift). |
| UX-006 — stale selection after Back to Rest | Return selects Rest and current saved progress; older records remain deliberately selectable, retained alarms stay separate, and acknowledged recovery stays dismissed after a waiting-only run. | `testReturnFromHistoryRunUsesLatestCheckpointButOlderRecordRemainsSelectable`, `testReplayReturnKeepsScheduledAlarmSeparateFromRest`, and `testWaitingOnlyReturnPreservesAcknowledgedCheckpoint` in [ListeningHistoryUITests](../HonkshoolUITests/ListeningHistoryUITests.swift). |
| UX-007 — obscured exact-wake error | Invalid exact-time recovery opens Time with the explanation and editable time visible; Cancel preserves the original value. Native date/time fields stack at accessibility sizes. | `testExpiredExactWakeRecoveryExposesErrorAndTimeControls` and its `AtLargestText` variant in [NapPlanReviewUITests](../HonkshoolUITests/NapPlanReviewUITests.swift). |

## Validation evidence retained

The application changes were saved in `4f02277`, `b72950e`, and `b15484a`. The final baseline includes the acknowledgement-preserving Rest refresh and strengthened scrolling helpers.

| Recorded run | Result | What it establishes |
| --- | --- | --- |
| Final compact/dark iPhone 17e simulator, iOS 26.5 | 251 passed, zero failed, five opt-in physical-device skips | All 233 unit tests and 18 relevant UI tests after the final navigation change, including all three accessibility UI tests and the five History tests. |
| Broader larger/light iPhone 17 Pro simulator, iOS 26.5, at `b72950e` | 288 passed, one failed, six opt-in physical-device skips | Broad regression evidence before the final navigation refinement. The largest-text sound test tapped Review instead of Sound; the corrected helper and all three accessibility tests subsequently passed in final validation. This full run was not clean. |
| Targeted normal/AX5 recovery and sound-only runs | Affected regressions passed; screenshots inspected | Visible exact-time correction, retained choice on Cancel, truthful sound-only copy, and latest-checkpoint return. These complement the final navigation run. |
| Repository verification and formatting after application fixes | 66 repository checks passed; Swift formatting and whitespace checks passed | Repository/publication checks and source formatting, not physical operation or human comprehension. |

The full simulator suite was not repeated after the final navigation refinement; the final focused run covered the changed navigation and all unit tests. Existing internal QoS warnings were retained without treating them as a demonstrated user-facing performance defect. Detailed captures, logs and result bundles remain local ignored review artifacts; portable regression references are linked above. See [Development](Development.md#verification) for maintained verification commands.

## Pending validation register

These items remain open after cycle closure. If equipment or time is unavailable, keep the status and reason recorded; do not substitute another automated review for missing evidence. Historical device successes in the [feasibility record](Feasibility-Spike.md) do not close current-baseline checks automatically.

| ID / item | Status at closure | Evidence needed to close it |
| --- | --- | --- |
| J12 — physical rest/audio/alarm operation | **Pending — Not tested** for this baseline | On a signed physical iPhone, exercise narration into rain and silence, lock/background, interruption and explicit return, fixed-deadline cutoff, real alarm authorization/scheduling/firing, Stop, cancellation, and saved progress without autoplay. Record build, device/OS, steps and observed outcomes; follow the [physical-device protocol](Feasibility-Spike.md#minimal-physical-device-acceptance). |
| A05 — manual VoiceOver journey | **Pending — Not tested** | Complete setup, sheet change/Cancel, review/confirm/start, expired-start and invalid-time recovery, quiet Stop, retained/uncertain alarm management, and History return. Record spoken order, heading navigation, focus, announcements, selections, and activation. Labels and XCTest taps alone do not close this item. |
| A04 / UX-004 — accessibility audit triage | **Pending — Needs review; Open** | Resolve the remaining native Cancel/Dynamic Type, text-discovery, More options hit-target, and contrast/AX5 overlay candidates. Inspect controls fully on-screen, measure rendered contrast and tappable bounds, and check assistive discovery. For each candidate, record a confirmed defect or an evidence-supported explanation. Raw scanner warnings are not unique confirmed defects. See [Accessibility refresh](Accessibility-Refresh.md#remaining-acceptance). |
| Human learnability / ordinary use | **Deferred — Not tested** | When available, observe a newcomer preparing a rest, explaining Confirm versus Start and Stop versus alarm cancellation, recovering from a delayed start, and resuming from History. Record actual observations. The [personal trial](Ten-Nap-Trial.md) remains a separate milestone. |

The first three items retain the original requirements for an **unsupervised TestFlight trial**. Its assessment stays **Incomplete** until those gates close and readiness is reassessed. Human testing is deliberately deferred rather than claimed complete. None of this establishes public-release approval or guaranteed waking.

## Stop and reopening rules

The current review cycle is complete. Missing manual evidence, elapsed time, or the possibility of more cosmetic refinements does not automatically reopen it.

- For a small fix, rerun the affected regression and layout checks and update its evidence; do not repeat the entire audit by default.
- For a reproducible usability report or a concrete device/accessibility failure, investigate the affected journey and record a new or reopened finding. Use a broader review only if the issue crosses journeys.
- For a substantial UI change, a new core journey, or a newly targeted platform/device context that invalidates existing coverage, declare the changed scope and perform the appropriate new review.
- When a pending check becomes feasible, execute that check and update this register. A new defect triggers scoped remediation; a pass updates the relevant gate without erasing historical results.

This record owns the closure criteria and current cycle disposition. The [design language](Design-Language.md), [user guide](User-Guide.md), and [screen implementation map](Screen-Implementation-Map.md) continue to own product behavior. Dated reviews retain their historical observations; this closeout supersedes their open statuses for the six corrected product findings, while preserving their unverified validation gates.
