# Plan

Separate Honkshool’s durable product roadmap from the task-specific plan file used by the `plan-implement-save` workflow. Preserve the existing roadmap under a distinct name, reserve `docs/Implementation-Plan.md` for replaceable per-task plans, and update all references and verification coverage.

## Scope

- In: rename the durable roadmap, document the two-file convention, update repository links and publication tests, validate, commit, and push the change.
- Out: changes to product scope, roadmap sequencing, application code, Xcode scaffolding, or the `plan-implement-save` skill itself.

## Action items

- [x] Preserve the overall roadmap as `docs/Project-Implementation-Plan.md` and make its durable purpose explicit.
- [x] Reserve this file for the current task plan and document that it may be replaced by future `plan-implement-save` runs.
- [x] Update README, product brief, decision log, and project overview links to the durable roadmap.
- [x] Update publication tests to require and inspect the durable roadmap while continuing to require the task plan.
- [x] Search for stale links and run `./scripts/verify-repository.sh` plus `git diff --check`.
- [x] Review the scoped documentation and test changes and prepare the current branch for saving.

## Open questions

- None.
