# Plan

Make the public repository understandable to first-time readers and contributors. Audit documentation against the current implementation, add accessible README graphics and focused guides, and preserve the distinction between an experimental build and a supported release. Save incremental commits on `codex/public-documentation`, with a PR based on the existing `codex/project-checkup` branch so its pending fixes remain a separate review.

## Scope

- In: README, documentation navigation, installation and everyday use, troubleshooting, privacy/storage, developer verification, repository/script map, and corrections to current public guidance.
- Out: application behavior, audio assets, signing identifiers, personal trial data, release distribution, and new claims of device or listening acceptance.

## Action items

- [x] Inventory tracked source, tests, scripts, configuration, and existing product/domain/content/feasibility/trial documentation; inspect current Git and PR state.
- [x] Commit this resolved plan before editing public guidance.
- [x] Rewrite README around availability, a visual first-nap flow, bundled content, controls, and clear links; add original accessible SVG diagrams with text equivalents.
- [x] Add a documentation index and focused getting-started, user, troubleshooting, and privacy guides, checked against the implemented screens and service contracts.
- [x] Document developer setup, module/script ownership and validation; reconcile CONTRIBUTING, SECURITY, project overview, trial, and feasibility guidance without rewriting historical evidence.
- [x] Validate relative links and anchors, SVG structure/rendering and legibility, command/config accuracy, and public-data boundaries; run `./scripts/verify-repository.sh`. No new tests or app test rerun is needed locally because executable behavior does not change; retain hosted full iOS checks.
- [ ] Complete independent Apple-contract and Brooks diff review, resolve confirmed documentation issues, and save coherent local checkpoints.
- [ ] Push all checkpoints, open the PR, request Codex review, observe hosted Repository Verify and iOS Unit and UI Tests to terminal results, and leave the PR unmerged.

## Open questions

- None. Source installation is for contributors and willing testers; this task improves public documentation without declaring a supported consumer release.

## Validation and review ledger

- Baseline: clean working tree at `25953f9`; existing project-checkup PR #12 remains open. Documentation PR will be stacked on that branch.
- Existing Python gate checks public links, privacy patterns, assets and repository contracts. Supplemental one-off checks will cover graphics and anchors without adding tests that merely mirror prose.
- Public content review excludes ignored personal notes, logs, generated reports and local signing configuration.

- First documentation slice: README and two original SVGs now introduce the actual Nap Plan flow and separate audio/alarm controls. Added installation, use, troubleshooting, privacy, and contributor guides plus an audience-based index. Rendered SVGs at native and 390-pixel widths: no clipping; adjacent README text carries the same instructions at narrow widths.
- Local verification: all 48 repository tests passed; 229 public local links/anchors and both self-contained SVG title/description structures passed supplemental checks. No application, test, or bundled audio changes.

- Canonical guidance slice: CONTRIBUTING and SECURITY now describe the implemented experimental app; feasibility setup delegates to the new setup/development guides while dated evidence remains unchanged. Project overview, trial, catalog, and narration reference link current guidance and distinguish automated device evidence from pending listening observations.

- Independent Apple-contract review identified six documentation corrections to finish: History entry/action labels and location, zero-default chooser allowances, unavailable-resume guidance, the test-alarm stored fields, and the SVG cutoff description. A reported broken physical-device-matrix anchor is non-actionable: the heading exists and the link/anchor checker passes. These are documentation-only fixes within this plan.

- Applied all six confirmed Apple-contract corrections. Final local gate: 48 tests passed in 6.59 seconds. Fourteen shell examples parse without execution; public links/anchors and SVG structure pass. No test files were added because this change alters documentation only.
