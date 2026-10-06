# Plan

Close the concrete PR review gaps in timer admission, last-reported activity state, countdown sizing and sound default labels. The refreshed review adds compact Dynamic Island duration readability and player-free timers surviving media-service resets. Preserve the fixed deadline, separately owned alarm, system-updated ticking and current Rest flow.

## Scope
- In: Timer silent-fallback admission and media-reset behavior, deterministic failure regressions, Live Activity snapshot wording and compact countdown sizing, affected layout/hosted checks, shared Rest sound default labels and UI expectations, canonical User-Guide/Architecture/Nap-Planning-Domain/Development/Design-Language/Screen-Implementation-Map documentation, and PR verification.
- Out: Push infrastructure, alarm scheduling or cancellation changes, timer extension, device installation/testing, new automation, and PR merge.

## Action items
[x] Review the PR diff and diagnose the late rain-fallback and stale activity-label paths against the runtime and ActivityKit contracts.
[x] Add fake-clock regressions for failed/throwing rain setup and failed play after the start limit, plus successful fallback and already-admitted sound failure controls.
[x] Recheck timer admission before failed rain becomes silent rest, preserving alarm ownership and the original deadline.
[x] Qualify Lock Screen mode/alarm wording as previously reported state and update presentation, layout and hosted expectations.
[x] Update User-Guide, Architecture and Nap-Planning-Domain for snapshot limits and bounded silent fallback.
[x] Bound the Lock Screen timer row at all five accessibility sizes and verify width/height with the real hosted card.
[x] Rename Rest sound defaults to explain sound as timer rest begins and during narrated quiet time; update existing UI expectations.
[x] Run focused regressions, the complete affected unit target, hosted layout/UI verification, formatting and repository checks; record evidence locally.
[x] Prepare the verified review fixes for the branch save and refreshed PR review. Record subsequent GitHub review, checks and mergeability in the local PR ledger and on PR #15.
[x] Reproduce an admitted silent timer ending on an audio-service reset; preserve player-free rest while retaining explicit failure for affected narration/rain and its original deadline.
[x] Bound compact Dynamic Island typography/width for hour-long and exact-time countdowns while retaining native ticking; verify actual hosted compact pixels and appropriate layout constraints.
[x] Update User-Guide, Nap-Planning-Domain and Development for reset and compact presentation contracts; run focused regressions and affected controller/layout tests.
[x] Prepare validated follow-up fixes for separate saves and post-push acknowledgments; continue refreshed review and final required CI in the PR ledger.
[ ] Name the quick timer stop action Stop rest, including silence, and describe its independent wake alarm; preserve narrated Stop playback and the existing control identifier.
[ ] Extend the existing silent countdown and rain/alarm UI cases with truthful stop-label expectations; update User-Guide, run those cases and fast checks, then save and acknowledge the review item.

## Open questions
- None. Use the existing admission limit and historical wording; no new product behavior or remote update service is needed.

## Review evidence

Rain preparation failure/throw and failed play reach silent-rest admission without the successful rain path's start-limit check. A pending 60-second timer must reject fallback after its three-second allowance; a previously admitted rest can still fall back before its fixed deadline. Separately, the custom Rest Activity updates only when the app runs and becomes stale at the deadline, so alarm cancellation through the separate system card can leave older labels visible. Labels must describe the last reported event rather than prove current playback or alarm state.

Codex review at f08b538 also identifies the largest-text timer width and the misleading sound-default labels. Extend the same plan with bounded hosted layout and accurate default wording before implementation.

The first review slice passes 264 checks (full unit target plus hosted countdown and three focused timer UI cases), zero failures and five intentional skips. The pre-fix late-fallback regression failed and its exact-boundary/already-admitted controls passed. All 51 repository checks and strict Swift formatting pass. The additional Codex layout and default-label fixes remain next.

The layout slice first reproduced width and height overflow at larger accessibility settings. After bounding the timer width and compact card text, all six layout tests and the actual hosted screenshot test pass at the largest system text setting. The screenshot shows the countdown, ending time, and both status lines without clipping; the app countdown remains uncapped.

Both saved-sound default UI cases pass, covering persistence, quick-timer selection, narrated review and unavailable-rain normalization. The copy describes conditional narrated quiet time, since a plan need not have time before or after narration. Strict formatting, all 51 repository checks and whitespace validation pass on the final implementation.

Refreshed Codex review at 3195550 reports compact countdown width for hours (4198906968) and unconditional media-reset failure for silent timers (4198906982). Both are bounded correctness/presentation concerns; no product decision or new background mechanism is needed. Check no-player silence, failed-rain fallback, active/paused audio and long countdowns before saving.

The silent media-reset scenario failed before repair while both active-audio controls passed. After ignoring resets without initialized players, all 47 controller tests pass, including silent fallback with an independent alarm, active/paused rain and verified partial narration. User-Guide and Nap-Planning-Domain describe this boundary. Compact Island verification remains next.

All seven layout cases pass, including OCR of complete compact minute/hour/ended values at AX5. The actual hosted three-hour case passes for both Lock Screen and compact Island pixels after a bounded wait for Home's dismissal animation. The first hosted attempt captured that transition and failed; the full painted-digit contract is retained. Final repository checks, strict formatting and whitespace validation pass. The independent Apple re-review found no remaining blocker in either follow-up fix.

Codex review at 0faef18 identifies Stop playback on a player-free silent timer (4199100401). The action ends the timer, so quick timers should consistently say Stop rest and explain that the wake alarm remains separate. This changes wording only; existing silent and rain timer UI cases verify the action and independent alarm behavior.
