# Plan

Close the two concrete PR review gaps: apply the existing timer setup limit to failed rain setup before admitting silence, and make locally updated Lock Screen state explicitly historical. Preserve the fixed deadline, separately owned alarm, and current Rest flow.

## Scope
- In: Timer silent-fallback admission, deterministic failure regressions, Live Activity snapshot wording, affected layout/hosted checks, User-Guide/Architecture/Nap-Planning-Domain documentation, and PR verification.
- Out: Push infrastructure, alarm scheduling or cancellation changes, timer extension, device installation/testing, new automation, and PR merge.

## Action items
[x] Review the PR diff and diagnose the late rain-fallback and stale activity-label paths against the runtime and ActivityKit contracts.
[ ] Add fake-clock regressions for failed/throwing rain setup and failed play after the start limit, plus successful fallback and already-admitted sound failure controls.
[ ] Recheck timer admission before failed rain becomes silent rest, preserving alarm ownership and the original deadline.
[ ] Qualify Lock Screen mode/alarm wording as previously reported state and update presentation, layout and hosted expectations.
[ ] Update User-Guide, Architecture and Nap-Planning-Domain for snapshot limits and bounded silent fallback.
[ ] Run focused regressions, the complete affected unit target, hosted layout/UI verification, formatting and repository checks; record evidence locally.
[ ] Save the review fixes, push the branch, refresh Codex review, and wait for required GitHub checks and mergeability.

## Open questions
- None. Use the existing admission limit and historical wording; no new product behavior or remote update service is needed.

## Review evidence

Rain preparation failure/throw and failed play reach silent-rest admission without the successful rain path's start-limit check. A pending 60-second timer must reject fallback after its three-second allowance; a previously admitted rest can still fall back before its fixed deadline. Separately, the custom Rest Activity updates only when the app runs and becomes stale at the deadline, so alarm cancellation through the separate system card can leave older labels visible. Labels must describe the last reported event rather than prove current playback or alarm state.
