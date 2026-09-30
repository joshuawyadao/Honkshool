# Plan

Make the public repository understandable to first-time readers and contributors. Audit documentation against the current implementation, add accessible README graphics and focused guides, and preserve the distinction between an experimental build and a supported release. Save incremental commits on `codex/public-documentation`, with a PR based on the existing `codex/project-checkup` branch so its pending fixes remain a separate review.

## Scope

- In: README, documentation navigation, installation and everyday use, troubleshooting, privacy/storage, developer verification, repository/script map, and corrections to current public guidance.
- Out: application behavior, audio assets, signing identifiers, personal trial data, release distribution, and new claims of device or listening acceptance.

## Action items

- [x] Inventory tracked source, tests, scripts, configuration, and existing product/domain/content/feasibility/trial documentation; inspect current Git and PR state.
- [ ] Commit this resolved plan before editing public guidance.
- [ ] Rewrite README around availability, a visual first-nap flow, bundled content, controls, and clear links; add original accessible SVG diagrams with text equivalents.
- [ ] Add a documentation index and focused getting-started, user, troubleshooting, and privacy guides, checked against the implemented screens and service contracts.
- [ ] Document developer setup, module/script ownership and validation; reconcile CONTRIBUTING, SECURITY, project overview, trial, and feasibility guidance without rewriting historical evidence.
- [ ] Validate relative links and anchors, SVG structure/rendering and legibility, command/config accuracy, and public-data boundaries; run `./scripts/verify-repository.sh`. No new tests or app test rerun is needed locally because executable behavior does not change; retain hosted full iOS checks.
- [ ] Complete independent Apple-contract and Brooks diff review, resolve confirmed documentation issues, and save coherent local checkpoints.
- [ ] Push all checkpoints, open the PR, request Codex review, observe hosted Repository Verify and iOS Unit and UI Tests to terminal results, and leave the PR unmerged.

## Open questions

- None. Source installation is for contributors and willing testers; this task improves public documentation without declaring a supported consumer release.

## Validation and review ledger

- Baseline: clean working tree at `25953f9`; existing project-checkup PR #12 remains open. Documentation PR will be stacked on that branch.
- Existing Python gate checks public links, privacy patterns, assets and repository contracts. Supplemental one-off checks will cover graphics and anchors without adding tests that merely mirror prose.
- Public content review excludes ignored personal notes, logs, generated reports and local signing configuration.
