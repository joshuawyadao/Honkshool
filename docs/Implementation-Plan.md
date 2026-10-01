# Plan

Resolve the largest-text simulator failure in the duration and sound accessibility flow. Use the existing failing UI case and recorded results to distinguish an automation defect from an app layout defect, preserve the accessibility requirements, and validate the correction on large and compact phones.

## Scope
- In: `AccessibilityRefreshUITests` diagnosis and the smallest demonstrated correction; production layout changes only if evidence requires them; updated accessibility and feasibility evidence; simulator validation and branch save.
- Out: physical-device testing, audio/alarm behavior, new product features, PR creation, and merge.

## Action items
- [x] Read the accessibility record, development test commands, Quiet curiosity guidance, and existing failure evidence; identify affected tests and production layout boundaries.
- [ ] Checkpoint the resolved plan before implementation.
- [ ] Reproduce the focused AX5 duration/sound failure on iPhone 18 Pro Max / iOS 27, capture relevant control and gesture geometry, and test ranked hypotheses one at a time.
- [ ] Repair the demonstrated cause while retaining preset label, one-line height, minimum target size, selection, applied-value, and complete sound-description assertions. Use the existing case as the regression; extend it only where needed to cover the failed interaction.
- [ ] Run the focused regression and all `AccessibilityRefreshUITests` on the failing destination, then verify the duration/sound flow on the compact iPhone SE / iOS 26.5 baseline. Run broader tests if production code or shared test infrastructure changes.
- [ ] Remove diagnostic instrumentation and update `docs/Accessibility-Refresh.md` and `docs/Feasibility-Spike.md` with the cause, final evidence, and unchanged manual acceptance limits.
- [ ] Run strict formatting, all repository checks, and diff checks; review the scoped correction, commit completed work, and push `codex/device-acceptance-ui`.

## Open questions
- None. The prior full suite and unchanged focused rerun both failed at `napPlanPreset-60`; the existing physical app installation and owner observations are outside this simulator task.
