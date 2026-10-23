# Plan

Implement the audit's confirmed repeated-work improvements on a feature branch from main, preserving durable playback evidence and complete iOS coverage for executable changes.

## Scope
- In: Incremental listening-history projection after successful saves; conservative documentation-only CI classification with a stable readiness gate; an explicit fast local unit-test mode; behavior-focused regression tests and canonical documentation.
- Out: Shipping lossy narration before listening/device acceptance, deleting local evidence, changing checkpoint cadence or alarm deadlines, speculative catalog/Lab refactors and unmeasured offline-renderer changes. These audit follow-ups remain documented for later validation.

## Action items
- [x] Inspect current main, architecture/development/domain docs, history transactions and existing portable/Swift tests; create `codex/efficiency-and-cost` from `origin/main`.
- [x] Checkpoint the resolved plan before implementation; keep commits local until validated.
- [x] Maintain the history projection incrementally after each committed write, retaining reopen validation, stale-evidence rejection, deterministic ordering and rollback/retry behavior; add representative large-history and recovery tests.
- [x] Classify only known documentation paths as eligible to omit macOS; handle renames/deletions and unknown paths conservatively, keep manual dispatch full, preserve stable reported gates and test classifier/workflow behavior.
- [x] Add an explicit unit-only mode to the existing iOS runner with default full coverage unchanged; test command selection and failure/result handling.
- [x] Update `docs/Development.md`, `docs/Architecture.md` and `docs/Nap-Planning-Domain.md`; record deferred resource recommendations and their evidence/acceptance requirements in a focused efficiency note.
- [ ] Run portable checks, focused history/host tests and complete iOS validation for the final executable changes; inspect the diff and obtain an independent Apple correctness review.
- [ ] Commit and push the completed branch; open a PR to main, attach it, request Codex review, run Brooks review, handle actionable findings and wait for required checks and mergeability. Leave merging to the owner.

## Open questions
- None. The branch excludes the separate, unmerged countdown feature and preserves the existing approved audio assets.

## Validation and review ledger
- Focused persistence suite: 11 passed, no failures/skips, iOS 26.5 simulator. Large-history cases cover 120-row ordering/reopen and 105-row failed replacement/rollback/retry.
- New unit-only runner mode: 227 passed, five hardware-only skips, no failures across 232 host tests. The default complete suite remains unchanged in scope.
- Independent Apple correctness review: no confirmed blocker; commits precede publication, rollback retains pending records, ordering is shared with reopen validation, and the app has one production store owner.
- Unrelated external writers are reconciled for the affected key or at reopen; no cross-process live-sync contract is introduced.
- Portable gate: 65 tests passed in 19.185 seconds after integration, plus whitespace checks. CLI fixtures cover documentation edits/deletes, code-to-doc renames, odd paths, mode changes, invalid references, manual full scope and final gate states.
- Integration review replaced the incidental exact runner spelling check with command-behavior assertions, and scoped timeout validation to the actual iOS job so another job's timeout cannot satisfy it.
- Complete final-head GitHub Actions checks and PR review will be recorded below when terminal.
- PR review follow-up: handle Git's valid type-change (`T`) status conservatively by running iOS for regular-file/symlink conversions, and add both-direction fixture coverage before the next push. No open product question is required.
