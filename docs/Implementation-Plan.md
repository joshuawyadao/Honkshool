# Plan

Require CI and validate an unsigned Release build in addition to simulator tests.

## Scope
- In: Scoped CI enforcement, automated validation, meaningful orchestration regressions, and canonical verification documentation for Honkshool.
- Out: Product feature changes, deployment, paid services or account changes, personal data, physical-device operation, and release signing/publishing.

## Action items
- [ ] Read Development, CI policy, runner tests, and current physical-acceptance records.
- [ ] Require the existing aggregate CI Verify status before main merges.
- [ ] Add bounded unsigned Release build validation and main push handling without changing app behavior.
- [ ] Extend CI-policy and orchestration tests to cover relevant failure/skip/classification cases.
- [ ] Run portable repository tests and safe build checks where supported; retain real alarm/audio checks as manual.
- [ ] Update canonical verification docs, save and push the isolated active-workstream branch.

## Discovery notes
- Baseline: `57b56272a81e8e3fd8d7c3665576a1c964f62c03` (`HEAD`), isolated from the original checkout.
- Existing in-progress changes in original project folders remain untouched.
- Missing hosting/account capabilities are reported as concrete limitations; they are not permission to weaken required checks.
