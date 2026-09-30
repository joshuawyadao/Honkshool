# Plan

Turn the approved Quiet curiosity atlas into connected, functional native pages. Replace the compressed menu-based setup with the illustrated session, timing, and sound flows; complete useful library and settings pages against the actual bundled catalog; give rest and recovery states their own clear presentations while preserving playback and alarm contracts.

## Scope
- In: compact Rest home; session chooser and actionable detail; time/sound sheets; full review and alarm-access explanation; ready, active, finished, stopped, existing-alarm and recovery pages; journey/detail/notes and bundled-audio inventory; an explicit, bounded George voice preview; persistent rest defaults; current-detail information; screen-to-capability documentation; meaningful UI/controller/preference tests; simulator visual verification; commit/push on `codex/app-icon`.
- Out: inventing unavailable journeys, alternate detail scripts or voices; download/delete controls for immutable bundled audio; changing verified timing, alarm ownership, history evidence, or automatic replay rules; public release, PR or merge. Branch-selection UI is driven only by actual catalog destinations; future assets remain explicitly unavailable.

## Action items
[x] Add functional session chooser/detail, journey library/detail, and source-linked session notes with valid Resume/Replay selections from current catalog and history.
[x] Add persistent rest defaults, current detail and bundled-audio pages, and a user-initiated bounded narration preview that stops on exit/background/interruption and cannot compete with a rest or Lab run.
[x] Rebuild Rest setup to match the approved compact hierarchy, with dedicated time and sound sheets that apply only explicit choices and preserve cancellation.
[x] Complete the review, alarm-access, ready, active/quiet, ended, existing-alarm and failed-start presentations; connect return/history actions without reusing consumed plans.
[x] Wire new pages into Settings and Rest, preserve root ownership of playback/alarm/history, and add shared components only where they improve consistency.
[x] Add/update tests for selection and preference persistence, preview lifecycle, modal cancellation, immutable review and recovery; preserve the existing safety assertions and test isolation.
[x] Verify builds, repository checks, focused and broader iOS tests, plus native screenshots against the atlas in daylight, evening, and larger text; repair contract-review findings.
[x] Update the design guide, product/status/usage docs and a durable screen implementation map; record validation, commit reviewable checkpoints and push the completed branch.

## Validation
- Debug build-for-testing and final Release simulator build passed. Strict Swift formatting and all 40 repository checks passed.
- The full iPhone 17 Pro / iOS 26.5 simulator suite produced 255 passes, one outdated ready-page copy assertion, and six intentional physical-only skips. The assertion now checks the revised copy while preserving fixed-deadline, explicit-Start, and no-autoplay checks; its targeted rerun passed.
- All seven final layout regressions passed after keeping the home alarm toggle above the review footer and pinning Start resting. These include cancellation, first alarm access, the Rest/History/Lab shell, larger-text defaults and Start, and the corrected confirmation case. Together the runs provide passing evidence for all 256 simulator cases.
- Added RestPreferencesTests, NarrationPreviewTests, and FunctionalPagesUITests; updated NapPlanReviewUITests, RestShellUITests, and FeasibilityUITests for connected routes and meaningful accessibility selectors.
- Inspected native daylight/evening screens and larger accessibility text against the atlas. UI tests check accessible labels and reachable controls; this is not a full spoken VoiceOver audit or new physical-device acceptance.
- Apple contract review findings about blocked library actions and history-error resume paths were repaired and rechecked. The final pinned Start and latest-entry recovery also passed the narrow contract review.
- Updated the design guide, README, project overview, durable roadmap, device verification notes, and screen implementation map. Local screenshots/result bundles remain outside Git.

## Open questions
- None. Build the illustrated pages against available content; expanded catalog and alternate narration assets require their own preparation work and must not appear playable here.
