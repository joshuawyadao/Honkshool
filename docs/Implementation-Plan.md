# Plan

Integrate the scoped CI baseline with current reviewed main, preserve its recovery/timing/sound UX, and prepare a reviewed PR with complete passing native checks.

## Scope
- In: Normal merge of main `84f0b10`, CI/runner integration, bounded full unit/UI shards and unsigned Release, combined portable regressions, transition-test synchronization, documentation, review fixes and current-head validation.
- Out: Product behavior changes, unrelated active PRs, physical alarm/audio/device use, paid resources and merging the final PR.

## Action items
- [x] Inspect current-main PR19 and task branch intents; checkpoint this resolved integration plan before merging (`d1e9d78`).
- [x] Preserve main's product sources, stronger AX5 sheet-absence/applied-sound assertions and this branch's immediate timeout diagnostics; retain the picker transition checks.
- [x] Combine CI/toolchain/runtime preparation, full unit/plan-review/other shard execution, owned cleanup, diagnostics and both sets of portable regression intent.
- [x] Resolve all conflicts and inspect the actual main-relative diff; all 92 portable regressions and staged whitespace checks pass. Save the normal merge without rewriting published history.
- [ ] Complete coverage and Brooks review, open the scoped PR, request exact-head Codex review and handle actionable findings.
- [ ] Verify current-head build/unit/UI/Release CI and actual required CI Verify, clean mergeability and no unresolved blocking feedback; leave unmerged.

## Discovery notes
- Earlier task-only source `102bd85` passed full CI43972459300; this is baseline evidence, not validation of the integrated PR head.
- Main PR19 independently added pinned CI preparation, verbose logs, scoped AX5 transition synchronization and newer product behavior. Preserve those reviewed contracts while applying this branch's full-suite partition and unsigned Release requirement.
- Canonical docs: Development and Troubleshooting. Implementation-Plan is replaceable task tracking; preserve durable main documentation.
- Local fixture validation, broad unit/UI/Release checks and mock alarm/audio paths remain separate from physical acceptance in the manual checklist.

## Open questions
None.

Integration decision: keep main's Xcode 26.6/iOS 26.5 CI pins and verbose progress while using the bounded owned-simulator helper for all matrix entries. New pin regressions reject an empty pin, choose 26.5 over newer installed runtimes, and download only the exact pinned version when absent. The existing preparation utility and its independent command-level tests remain available; CI and Troubleshooting identify the active owned helper explicitly.

Integration validation: `./scripts/verify-repository.sh` passed all 92 tests on the resolved merge working tree; `git diff --cached --check` passed. Product source files match current main; the two UI-test changes preserve and strengthen transition outcomes. Current-head hosted native validation and Codex review remain pending.

## PR CI correction — cold CoreSimulator inventory

Observed run43982368000 at2c6c589: unit/other jobs stop before tests because the first `simctl list -j runtimes` exceeds the new 30-second deadline on hosted macOS. Keep the pinned toolchain and bounded orchestration; allow a finite 180-second cold inventory budget, add a synthetic slow-start regression plus timeout diagnostic assertion, rerun portable checks, push and obtain fresh review/current-head native CI. No app or UI expectations change.

- [ ] Demonstrate the cold-inventory regression before the fix, adjust only the inventory deadline, and verify eventual success and bounded timeout.
- [ ] Rerun portable checks and hosted native CI at the corrected head; classify all prior failed/cancelled results explicitly.
