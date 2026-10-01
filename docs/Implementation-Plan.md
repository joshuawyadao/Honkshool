# Plan

Resolve the largest-text simulator failure in the duration and sound accessibility flow. Use the existing failing UI case and recorded results to distinguish an automation defect from an app layout defect, preserve the accessibility requirements, and validate the correction on large and compact phones.

## Scope
- In: `AccessibilityRefreshUITests` diagnosis and the smallest demonstrated correction; production layout changes only if evidence requires them; updated accessibility and feasibility evidence; simulator validation and branch save.
- Out: physical-device testing, audio/alarm behavior, new product features, PR creation, and merge.

## Action items
- [x] Read the accessibility record, development test commands, Quiet curiosity guidance, and existing failure evidence; identify affected tests and production layout boundaries.
- [x] Checkpoint the resolved plan before implementation (`9a11814`).
- [x] Reproduce the focused AX5 duration/sound failure on iPhone 18 Pro Max / iOS 27, capture relevant control and gesture geometry, and test ranked hypotheses one at a time.
- [x] Repair the demonstrated cause while retaining preset label, one-line height, minimum target size, selection, applied-value, and complete sound-description assertions. Use the existing case as the regression; add unique-preset and actual 60-minute selection checks in Rest and Time.
- [ ] Run the focused regression and all `AccessibilityRefreshUITests` on the failing destination, then verify the duration/sound flow on the compact iPhone SE / iOS 26.5 baseline. Run the complete simulator suite if production code or shared test infrastructure changes.
- [ ] Remove diagnostic instrumentation and update `docs/Accessibility-Refresh.md` and `docs/Feasibility-Spike.md` with the cause, final evidence, and unchanged manual acceptance limits.
- [ ] Run strict formatting, all repository checks, and diff checks; review the scoped correction, commit completed work, and push `codex/device-acceptance-ui`.

## Open questions
- None. The prior full suite and unchanged focused rerun both failed at `napPlanPreset-60`; the existing physical app installation and owner observations are outside this simulator task.

## Diagnosis evidence
- The unchanged focused case failed again at the same preset. A minimized launch → first scroll → reachability probe also failed. Its accessibility tree contains only the first three presets while the recording shows the fourth on screen; further upward swipes cannot recover the missing element.
- Explicit accessibility containment failed the same minimized probe and was removed. Replacing the four-choice lazy grid with eager `Grid` rows restored the fourth button and passed that probe. `ViewThatFits` keeps the existing 4/3/2/1-column adaptation, minimum widths, spacing, actions, and traits. The final regression uses the original full flow with stronger selection and uniqueness assertions; temporary hierarchy instrumentation was removed.
- The full flow then passed both duration grids and reached a later sound-selection failure. The recording and synthesized event locate the tap below the pinned Done footer while Gentle rain remained offscreen. The scrolling helper must require the target center inside its usable content band, even when XCTest reports it hittable, and support returning to controls above the viewport. The remaining original flow is a 20-second reproduction with a specific missed tap; retain it as the regression for this helper correction.
- All three final accessibility UI cases passed on iPhone 18 Pro Max / iOS 27.0 after both corrections. Strict Swift formatting and 51 repository checks passed. The compact baseline and complete simulator suite remain pending at this implementation checkpoint.
- The compact run exposed full-band swipe overshoot: the helper repeatedly crossed the 45-minute preset in opposite directions. Limit each drag using target distance and viewport height, and hold at its end to stop momentum. Reposition earlier presets before subsequent taps. Rerun compact acceptance and the full iOS 27 suite after this test-only refinement.
- Both compact AX5 flows passed with controlled drags. The remaining standard-text session-actions case exposed the helper's fixed 140-point bottom exclusion: a visible last About button lay just below that artificial boundary at the scroll limit. Use actual visible tab-bar and pinned-action bounds, with a small screen-edge margin, so sheets without footers retain their usable area.
- All three compact cases now pass with the final helper. Duration grids were visually inspected on both large and compact captures. Independent Apple-contract review found no actionable issue; all original assertions remain, and diagnostic instrumentation is removed. The full iOS 27 simulator suite is running.
