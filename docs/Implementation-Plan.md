# Plan

Require CI, preserve full simulator coverage in bounded independent jobs, and validate an unsigned Release build. Synchronize UI transitions without weakening behavior or accessibility assertions.

## Scope
- In: CI enforcement, owned simulator lifecycle, complete native test/build checks, orchestration regressions and verification documentation.
- Out: Unrelated features, deployment, paid resources, personal data, physical alarms/audio/devices and release signing/publishing.

## Action items
- [x] Read Development, CI policy, runner tests and physical acceptance records.
- [x] Require strict GitHub Actions CI Verify for main merges, with pull requests and no bypass.
- [x] Verify main pushes and conservative PR changes; keep documentation-only classification and aggregate results fail-closed.
- [x] Select one Xcode for provisioning/tests/Release, create a job-owned iOS simulator with finite deadlines, and always remove its exact ID.
- [x] Preserve full local default/unit scope and add complementary UI shards with invalid selector refusal before side effects.
- [x] Require all unit tests/unsigned Release plus plan-review and remaining UI jobs, with independent 40-minute limits and fail-fast false.
- [x] Retain failed/cancelled diagnostics with distinct artifact names and seven-day retention.
- [x] Wait for Sessions and its detail link before scrolling; preserve recovery, History, Notes and beginning assertions.
- [x] Wait up to five seconds for Review hittability after Apply sound; retain all original AX5 layout/label/selection/hittability assertions and add timeout diagnostics.
- [x] Run all 77 portable checks, local unsigned Release and original/synchronized isolated UI cases.
- [x] Complete current-source hosted CI, update canonical docs, save and push the isolated branch.

## Discovery notes
- Base: `57b56272a81e8e3fd8d7c3665576a1c964f62c03`, isolated from the original checkout. Existing project work remains untouched.
- Combined 40/50-minute jobs timed out. Retained results justified complementary jobs; no tests were dropped to meet a budget.
- Earlier hosted UI failures exposed missing transition synchronization. Both original and strengthened isolated picker/AX5 cases pass locally; no product behavior defect was established or app behavior changed.
- Complete hosted run https://github.com/joshuawyadao/Honkshool/actions/runs/43972459300 at `102bd85` passes repository checks, unit/unsigned Release, both UI shards, owned simulator cleanup and CI Verify. Every matrix entry finishes within its 40-minute bound.
- Every UI class is covered: plan-review selects NapPlanReviewUITests; the other shard selects the entire UI target minus that class, so future classes enter automatically. Any shard/build failure or cancellation fails the aggregate.
- Canonical documentation: `docs/Development.md`. Real alarm audibility, routes, lock-screen controls and recipient/device acceptance remain manual; simulator evidence does not complete them.

## Open questions
None.

## PR review cycle — current target integration

- [ ] Merge current main `84f0b10` while preserving its reviewed recovery/timing/sound UX and this branch's CI and transition-test changes.
- [ ] Resolve any conflicts after reviewing both intents, inspect the final main-relative scope, and repeat affected portable/native checks.
- [ ] Open the scoped PR, obtain current-head Brooks/Codex review, address actionable findings and require terminal passing current-head CI. Leave the PR unmerged.

No open questions; this is integration of the requested CI work with the latest reviewed main.
