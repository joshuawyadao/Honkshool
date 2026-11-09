# Plan

Validate the smallest secure offline narration environment upgrade in isolation before recommending it for future audio preparation.

## Scope
- In: Python 3.11 dependency resolution, patched Transformers compatibility, preparation instructions and PR review.
- Out: app runtime, bundled audio/provenance replacement, Xcode upgrades and global environments.

## Action items
- [x] Inspect preparation docs, renderer and publication tests; create a feature branch.
- [x] Resolve a fresh temporary environment; use non-yanked Transformers 5.10.1 instead of withdrawn 5.10.0. Dependency consistency and hash-required resolution pass.
- [x] Run the complete original narration with downloaded, hash-verified pinned assets. WAV hash exactly matches the bundled master.
- [x] Record the validated recipe and platform boundary in Audio Preparation and Development; preserve historical provenance.
- [x] Run the repository gate: 66 tests pass. No test files need changes: only requirements and documentation change; existing asset/publication tests cover preserved behavior.
- [ ] Review, save, push and open a PR; inspect Codex review, CI and mergeability.

## Validation and review ledger
- Clean temporary CPython 3.11 environment: pip check passes; hash-required clean dependency resolution passes for all pinned requirements.
- Full offline first-session render: 727.625 seconds, no clipping, exact bundled WAV hash. Review output and downloaded model assets remain temporary.
- Brooks PR Review: complete four-file diff, generated requirements excluded from design scoring; no actionable decay risks. Score 100/100, stable at 100. No production code changes; quick test check not applicable.
- GitHub review and CI results pending publication.

## Open questions
- None. Preserve bundled audio as rollback boundary; claim compatibility only after successful validation.
