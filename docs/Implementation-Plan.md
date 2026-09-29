# Plan

Prepare the ten-nap personal trial with a concise setup guide, a blank local-only log template, and evidence-based decision criteria. Keep the preparation separate from performing the trial: no device session, personal observations, or physical acceptance is claimed by this PR.

## Scope
- In: `docs/Ten-Nap-Trial.md`, `docs/Ten-Nap-Trial-Log.template.md`, links and current status in README, Project-Overview, Project-Implementation-Plan, and Feasibility-Spike; safe private-copy instructions using the existing ignored `local-data/` directory; documentation verification; a reviewed, green PR on `codex/ten-nap-trial-preparation`.
- Out: app or test behavior changes, new analytics/storage/schema/permissions, device installation or testing now, collecting personal results, performing the ten naps, new content, distribution, and changing deferred observations to passes.

## Action items
- [x] Inspect the Phase 5 roadmap, product goal, device evidence, production UI labels, ignore rules, and existing publication checks. Start from merged two-session main (`19f4339`).
- [ ] Checkpoint this resolved plan before writing the trial material.
- [ ] Add one short guide covering a normal signed build, the production Nap Plan entry, foreground-until-playback requirement, alarm ownership, private log setup, natural use, and observation limits. Link to the existing signing/device guide rather than duplicate it.
- [ ] Add a blank ten-entry log template with build context, choices including alternatives, comfort, playback/alarm and history outcomes, optional deferred observations, and a closeout summary. Keep unknown, not applicable, and directly observed outcomes distinct; never overwrite an existing private log.
- [ ] Define practical continue/pivot/stop and insufficient-evidence criteria; prioritize observed defects and preserve the owner's final decision. Update the README, overview, roadmap, and device-guide links without changing historical evidence or marking the trial complete.
- [ ] Verify relative links and public-data rules with `./scripts/verify-repository.sh`, check private-copy ignore behavior and non-overwrite behavior, and inspect the diff. No new automated tests or local iOS rerun are needed for documentation-only changes; existing CI still runs its required jobs.
- [ ] Review the bounded documentation and instructions for product/privacy/Apple contract accuracy, then complete Brooks/Codex review, address actionable feedback, commit/push, and wait for required CI and mergeability. Track live PR status in its body and an ignored local ledger; leave the PR unmerged.

## Open questions
- None block preparation. Actual use and deferred physical observations stay pending until the owner is ready; a public-safe aggregate report is future work after the private trial.
