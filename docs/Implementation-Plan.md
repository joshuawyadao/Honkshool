# Plan

Make PR #19's iOS CI prepare and boot an explicit compatible simulator, verify preparation failures with portable fixtures, and shepherd the pushed branch through review and passing checks.

## Scope
- In: CI-only simulator preparation, pinned existing runner toolchain/runtime, workflow wiring, portable setup regressions, scoped UI-test synchronization failures, Development/Troubleshooting documentation, commit/push checkpoints, and PR #19 review/check follow-through.
- Out: app behavior, shortened test coverage, paid runners/caches, branch-protection changes, device acceptance, and merging the PR.

## Action items
- [x] Inspect the failed job, documented runner image, test runner overrides, CI policy, portable test harness, and Development/Troubleshooting guidance.
- [x] Commit this resolved plan on `codex/ux-status-recovery-fixes` before implementation.
- [x] Add `scripts/prepare-ios-simulator.py` to initialize selected Xcode, check/install iOS 26.5 when absent, create a dedicated iPhone 17 Pro simulator, boot/wait for it, and publish its exact ID to the CI test step.
- [x] Wire preparation into the existing macOS job and retain the full unit/UI suite, diagnostic artifacts, fail-closed aggregate gate, and a bounded hosted-run time budget.
- [x] Add portable command-level regressions for installed/missing/unavailable runtime, explicit toolchain/ID propagation, preparation failure, and no published destination until boot succeeds; coordinate file-disjoint tests with a builder.
- [x] Update Development and Troubleshooting for CI setup, pinned versions, download behavior, and destination failures; preserve the completed UX cycle and pending device/accessibility checks.
- [x] Run focused portable tests, repository verification, Python/shell checks as applicable, and scoped correctness/Brooks review; commit and push the fix.
- [x] Extend the hosted job budget to 60 minutes after the first bootable run exhausted 40 minutes; enable verbose CI test output with portable coverage while retaining local quiet defaults and full test scope.
- [x] Run the focused AX5 sound-Apply baseline, inspect the recorded failing CI transition, and distinguish dismissal synchronization from a persistent layout or selection failure.
- [x] Correct only the supported cause, preserve existing accessibility assertions, verify applied sound and reachable Review after dismissal, document the synchronization rule, and run focused regression repetitions plus repository/format checks before the next push.
- [ ] Request fresh Codex review, inspect current-head GitHub Actions, fix any remaining scoped failures, and record final evidence before reporting PR #19 merge-ready without merging.

## Open questions
- None. The owner explicitly authorized fixing CI infrastructure and rerunning checks until merge-ready.

## Validation ledger
- Prior head `57b5627`: Repository Verify passed; iOS job failed before build/tests with unavailable destination and zero tests executed; CI Verify failed correctly. Existing workflow/runner script were unchanged in that PR head.
- Prior Codex and Brooks review found no actionable findings at `57b5627`; review must be refreshed after the CI changes.
- Runtime image reference: GitHub actions/runner-images macos-26-arm64 version 20261102.0473 documents Xcode 26.6 and iOS 26.5 with iPhone 17 Pro. Preserve existing local test defaults; CI prepares its own explicit destination.

- CI repair plan checkpoint: `8f850d7`. Eleven portable setup regressions pass, including exact-ID/toolchain handoff into the existing test runner. Workflow publication assertions enforce preparation before the full suite.
- Scoped Apple-platform/Brooks review found no actionable setup issue; command flags, conditional download, exact-ID boot and fail-closed publication reviewed. Python compilation passes.
- Repository verification: all 77 tests passed, including 11 new simulator-preparation/handoff cases; whitespace checks passed. Hosted CI and fresh Codex review are the remaining gates.

- Hosted run `43937374660` at `0514272`: simulator preparation passed, cold build/initial test launch took about nine minutes, and repeated app launches continued until job cancellation at 40 minutes. No completed result bundle was published; the final test outcome is unverified. Update the initial 40-minute-budget assumption to 60 minutes with detailed CI progress logging; do not skip tests or increase individual test timeouts.
- Timeout/logging follow-up: all 80 repository checks and shell syntax checks passed; scoped review found no actionable issue. Next hosted run must establish full-suite completion inside the new bound.
- Hosted run `43945191271` at `16c5283` completed within 60 minutes: 289 passed, one failed, six physical-device skips. All 233 simulator unit tests passed; the sole failure is the immediate `reviewNapPlan.isHittable` assertion after sound Apply in `AccessibilityRefreshUITests` line 41. Existing label/selection assertions passed. Inspect the result recording and focused local test before changing synchronization; do not alter app behavior or weaken accessibility expectations without evidence.
- Ranked diagnosis predictions: (1) a dismissal race clears with a bounded wait for sheet disappearance and Review hittability; (2) a persistent footer obstruction remains after that wait; (3) an unsuccessful Apply leaves the sheet present or loses the selected sound. The focused command selects only `HonkshoolUITests/AccessibilityRefreshUITests/testLargestTextDurationChoicesAndSoundDescriptions` on the iOS 26.5 review simulator; final hosted CI still runs the full suite.
- Focused baseline passed locally (one test, 58.445 seconds); the original CI failure is intermittent rather than reproduced locally. The CI recording's final frame shows Gentle rain applied and the Review footer visible after dismissal. Together with the immediate post-Done assertion and asynchronous SwiftUI dismissal, this supports test synchronization rather than a persistent layout/selection defect. Add one five-second predicate wait for sheet absence and Review hittability, retaining the original hittability assertion and adding applied-sound verification. No production code change is supported.
- Updated focused regression: three iterations passed with zero failures (55.809, 53.247, 52.717 seconds). All 80 repository checks and strict formatting for the changed Swift test passed; incremental Apple/Brooks review found no actionable concerns. Fresh hosted full-suite CI and exact-head Codex review remain required after pushing this follow-up.
