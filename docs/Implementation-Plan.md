# Plan

Require CI and validate an unsigned Release build in addition to simulator tests.

## Scope
- In: Scoped CI enforcement, automated validation, meaningful orchestration regressions, and canonical verification documentation for Honkshool.
- Out: Product feature changes, deployment, paid services or account changes, personal data, physical-device operation, and release signing/publishing.

## Action items
- [x] Read Development, CI policy, runner tests, and current physical-acceptance records.
- [x] Require the existing aggregate CI Verify status before main merges.
- [x] Add bounded unsigned Release build validation and main push handling without changing app behavior.
- [x] Extend CI-policy and orchestration tests to cover relevant failure/skip/classification cases.
- [x] Set a bounded 50-minute native job budget using observed 35–38-minute successful full jobs plus the new simulator/Release steps; preserve the complete suite and existing 60-minute policy ceiling.
- [x] Retain available test diagnostics after cancellation as well as failure; the 40-minute run confirmed cleanup worked but its failure-only artifact condition skipped the results.
- [ ] Run portable repository tests and safe build checks where supported; retain real alarm/audio checks as manual.
- [ ] Update canonical verification docs, save and push the isolated active-workstream branch.

## Discovery notes
- Baseline: `57b56272a81e8e3fd8d7c3665576a1c964f62c03` (`HEAD`), isolated from the original checkout.
- Existing in-progress changes in original project folders remain untouched.
- Missing hosting/account capabilities are reported as concrete limitations; they are not permission to weaken required checks.
- Portable gate: 74 tests passed. The unsigned Release build passed locally with Xcode 27.2 outside the restricted sandbox; hosted CI must still establish simulator and build acceptance. No physical-device or signed release check was performed.
- Canonical `docs/Development.md` is updated; final save/push is owned by the parent task.
- Hosted run `43938715961` on macOS image `20261102.0473.1` failed before tests because Xcode exposed only generic simulator placeholders. The CI job now provisions and later removes an owned simulator, with a conditional iOS runtime download. Its hosted test/build result is pending.
- CI selects one validated Xcode developer directory before provisioning and passes it to simulator tools, `test-ios.sh`, and the unsigned Release build; this prevents a mismatch between the runner's active Xcode and the test script's local default path.
- Hosted run `43941851333` reached the full simulator suite but was cancelled at the previous 40-minute job cap. No passing full-suite/Release result is claimed from that run. The 50-minute version retains identical test/build commands and will be revalidated.
