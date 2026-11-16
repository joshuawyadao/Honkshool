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
- [ ] Run portable repository tests and safe build checks where supported; retain real alarm/audio checks as manual.
- [ ] Update canonical verification docs, save and push the isolated active-workstream branch.

## Discovery notes
- Baseline: `57b56272a81e8e3fd8d7c3665576a1c964f62c03` (`HEAD`), isolated from the original checkout.
- Existing in-progress changes in original project folders remain untouched.
- Missing hosting/account capabilities are reported as concrete limitations; they are not permission to weaken required checks.
- Portable gate: 67 tests passed. Local unsigned Release build was attempted with Xcode 27.2 and failed because this sandbox denied `sandbox-exec` to Swift macro plugins; hosted CI must establish build acceptance. No physical-device or signed release check was performed.
- Canonical `docs/Development.md` is updated; final save/push is owned by the parent task.
