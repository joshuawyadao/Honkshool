# Plan

Close the two concrete PR review gaps: apply the existing timer setup limit to failed rain setup before admitting silence, and make locally updated Lock Screen state explicitly historical. Preserve the fixed deadline, separately owned alarm, and current Rest flow.

## Scope
- In: Timer silent-fallback admission, deterministic failure regressions, Live Activity snapshot wording, affected layout/hosted checks, User-Guide/Architecture/Nap-Planning-Domain documentation, and PR verification.
- Out: Push infrastructure, alarm scheduling or cancellation changes, timer extension, device installation/testing, new automation, and PR merge.

## Action items
[x] Review the PR diff and diagnose the late rain-fallback and stale activity-label paths against the runtime and ActivityKit contracts.
[x] Add fake-clock regressions for failed/throwing rain setup and failed play after the start limit, plus successful fallback and already-admitted sound failure controls.
[x] Recheck timer admission before failed rain becomes silent rest, preserving alarm ownership and the original deadline.
[x] Qualify Lock Screen mode/alarm wording as previously reported state and update presentation, layout and hosted expectations.
[x] Update User-Guide, Architecture and Nap-Planning-Domain for snapshot limits and bounded silent fallback.
[x] Bound the Lock Screen timer row at all five accessibility sizes and verify width/height with the real hosted card.
[ ] Rename Rest sound defaults to explain immediate timer sound and the narrated-plan fallback; update existing UI expectations.
[ ] Run focused regressions, the complete affected unit target, hosted layout/UI verification, formatting and repository checks; record evidence locally.
[ ] Save the review fixes, push the branch, refresh Codex review, and wait for required GitHub checks and mergeability.

## Open questions
- None. Use the existing admission limit and historical wording; no new product behavior or remote update service is needed.

## Review evidence

Rain preparation failure/throw and failed play reach silent-rest admission without the successful rain path's start-limit check. A pending 60-second timer must reject fallback after its three-second allowance; a previously admitted rest can still fall back before its fixed deadline. Separately, the custom Rest Activity updates only when the app runs and becomes stale at the deadline, so alarm cancellation through the separate system card can leave older labels visible. Labels must describe the last reported event rather than prove current playback or alarm state.

Codex review at f08b538 also identifies the largest-text timer width and the misleading sound-default labels. Extend the same plan with bounded hosted layout and accurate default wording before implementation.

The first review slice passes 264 checks (full unit target plus hosted countdown and three focused timer UI cases), zero failures and five intentional skips. The pre-fix late-fallback regression failed and its exact-boundary/already-admitted controls passed. All 51 repository checks and strict Swift formatting pass. The additional Codex layout and default-label fixes remain next.

The layout slice first reproduced width and height overflow at larger accessibility settings. After bounding the timer width and compact card text, all six layout tests and the actual hosted screenshot test pass at the largest system text setting. The screenshot shows the countdown, ending time, and both status lines without clipping; the app countdown remains uncapped.
