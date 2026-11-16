# Plan

Require CI, preserve full simulator coverage in bounded independent jobs, and validate an unsigned Release build. Diagnose and correct the observed session-picker UI regression without weakening its Notes assertions.

## Scope
- In: Scoped CI enforcement, automated validation, meaningful orchestration regressions, and canonical verification documentation for Honkshool.
- Out: Unrelated product feature changes, deployment, paid services or account changes, personal data, physical-device operation, and release signing/publishing.

## Action items
- [x] Read Development, CI policy, runner tests, and current physical-acceptance records.
- [x] Require the existing aggregate CI Verify status before main merges.
- [x] Add bounded unsigned Release build validation and main push handling without changing app behavior.
- [x] Extend CI-policy and orchestration tests to cover relevant failure/skip/classification cases.
- [x] Set a bounded 50-minute native job budget using observed 35–38-minute successful full jobs plus the new simulator/Release steps; preserve the complete suite and existing 60-minute policy ceiling.
- [x] Retain available test diagnostics after cancellation as well as failure; the 40-minute run confirmed cleanup worked but its failure-only artifact condition skipped the results.
- [x] Extend the runner with `ui` scope and complementary `plan-review` / `other` UI shards; keep local default full and unit scope unchanged, reject invalid combinations before Xcode/results.
- [x] Run all unit tests and both complementary UI shards as required independent macOS matrix jobs (40 minutes each, fail-fast false), with Release on the unit entry, unique artifacts, and unchanged fail-closed aggregate.
- [x] Reproduce `FunctionalPagesUITests.testSessionDetailCanChooseBeginningAndOpenActualNotes`; both original and strengthened case pass locally. Assert Sessions presentation before scrolling, preserve all navigation/Notes assertions and retain immediate failure diagnostics. No product defect is established.
- [ ] Test selector validity, the complete UI union, new-class inclusion, Release conditioning and aggregate failure behavior; revalidate native UI and the full hosted matrix.
- [x] Run portable repository tests and safe build checks where supported; retain real alarm/audio checks as manual.
- [ ] Synchronize AX5 sound-sheet dismissal before the existing Review hittability assertion; retain every preset/layout/selection check and the standard five-second transition bound.
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

- The retained artifact from `43950692622` proves 238 unit cases executed (5 skipped, zero failures). UI recorded 52 passes, one skip, one failure and one unfinished case at the 50-minute job cutoff. The failure follows Change session with no Sessions sheet. Full CI acceptance is pending; raising the combined budget again would not resolve this regression. Separate complementary jobs preserve every test target and give useful independent evidence. Hosted cancellation also prevented confirmed simulator deletion; the replacement jobs retain bounded owned-only cleanup.

- The original picker test passed alone on a fresh iPhone 17 Pro / iOS 26.5 simulator with Xcode 27.2 (one pass, zero failures/skips). No app defect is established. Preserve its History round trip and all recovery/detail/Notes/beginning assertions; synchronize explicitly on Sessions presentation and detail-link existence before the scroll helper can swipe, and attach immediate hierarchy/screenshot if presentation fails. Revalidate this strengthened case and the full hosted shards.

- Current slice: 77 portable tests pass; original and strengthened picker case each pass (one test, zero skips/failures). Read-only Apple contract review confirms complete target partition, fail-closed aggregate and required unit/Release. Full hosted matrix remains the acceptance check; no native full-suite pass is claimed yet.

- Hosted matrix `43964621902` completes within budgets: unit/unsigned Release and plan-review pass; the other UI shard records 35 passes and one failure, with successful cleanup. Failure is AccessibilityRefreshUITests.swift:41, immediate Review-button hittability after Apply sound. Every preceding AX5 layout/label/selection assertion passes. Add a bounded explicit return-to-Rest/hittability wait while retaining all original accessibility assertions; reproduce the original case first, validate the synchronized case, then run current-source hosted CI. No app behavior defect is established.
