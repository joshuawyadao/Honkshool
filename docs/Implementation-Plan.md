# Plan

Make PR #19's iOS CI prepare and boot an explicit compatible simulator, verify preparation failures with portable fixtures, and shepherd the pushed branch through review and passing checks.

## Scope
- In: CI-only simulator preparation, pinned existing runner toolchain/runtime, workflow wiring, portable setup regressions, Development/Troubleshooting documentation, commit/push checkpoints, and PR #19 review/check follow-through.
- Out: app behavior, shortened test coverage, paid runners/caches, branch-protection changes, device acceptance, and merging the PR.

## Action items
- [x] Inspect the failed job, documented runner image, test runner overrides, CI policy, portable test harness, and Development/Troubleshooting guidance.
- [ ] Commit this resolved plan on `codex/ux-status-recovery-fixes` before implementation.
- [ ] Add `scripts/prepare-ios-simulator.py` to initialize selected Xcode, check/install iOS 26.5 when absent, create a dedicated iPhone 17 Pro simulator, boot/wait for it, and publish its exact ID to the CI test step.
- [ ] Wire preparation into the existing macOS job and retain the full unit/UI suite, diagnostic artifacts, fail-closed aggregate gate, and 40-minute bound.
- [ ] Add portable command-level regressions for installed/missing/unavailable runtime, explicit toolchain/ID propagation, preparation failure, and no published destination until boot succeeds; coordinate file-disjoint tests with a builder.
- [ ] Update Development and Troubleshooting for CI setup, pinned versions, download behavior, and destination failures; preserve the completed UX cycle and pending device/accessibility checks.
- [ ] Run focused portable tests, repository verification, Python/shell checks as applicable, and scoped correctness/Brooks review; commit and push the fix.
- [ ] Request fresh Codex review, inspect current-head GitHub Actions, fix any remaining scoped failures, and record final evidence before reporting PR #19 merge-ready without merging.

## Open questions
- None. The owner explicitly authorized fixing CI infrastructure and rerunning checks until merge-ready.

## Validation ledger
- Prior head `57b5627`: Repository Verify passed; iOS job failed before build/tests with unavailable destination and zero tests executed; CI Verify failed correctly. Existing workflow/runner script were unchanged in that PR head.
- Prior Codex and Brooks review found no actionable findings at `57b5627`; review must be refreshed after the CI changes.
- Runtime image reference: GitHub actions/runner-images macos-26-arm64 version 20261102.0473 documents Xcode 26.6 and iOS 26.5 with iPhone 17 Pro. Preserve existing local test defaults; CI prepares its own explicit destination.
