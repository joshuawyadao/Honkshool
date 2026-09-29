# Plan

Prepare the ten-nap personal trial with a concise setup guide, a blank local-only log template, and evidence-based decision criteria. Keep the preparation separate from performing the trial: no device session, personal observations, or physical acceptance is claimed by this PR.

## Scope
- In: `docs/Ten-Nap-Trial.md`, `docs/Ten-Nap-Trial-Log.template.md`, links and current status in README, Project-Overview, Project-Implementation-Plan, and Feasibility-Spike; safe private-copy instructions using the existing ignored `local-data/` directory; documentation verification; a reviewed, green PR on `codex/ten-nap-trial-preparation`.
- Out: app or test behavior changes, new analytics/storage/schema/permissions, device installation or testing now, collecting personal results, performing the ten naps, new content, distribution, and changing deferred observations to passes.

## Action items
- [x] Inspect the Phase 5 roadmap, product goal, device evidence, production UI labels, ignore rules, and existing publication checks. Start from merged two-session main (`19f4339`).
- [x] Checkpoint this resolved plan before writing the trial material.
- [x] Add one short guide covering a normal signed build, the production Nap Plan entry, foreground-until-playback requirement, alarm ownership, private log setup, natural use, and observation limits. Link to the existing signing/device guide rather than duplicate it.
- [x] Add a blank ten-entry log template with build context, choices including alternatives, comfort, playback/alarm and history outcomes, optional deferred observations, and a closeout summary. Keep unknown, not applicable, and directly observed outcomes distinct; never overwrite an existing private log.
- [x] Define practical continue/pivot/stop and insufficient-evidence criteria; prioritize observed defects and preserve the owner's final decision. Update the README, overview, roadmap, and device-guide links without changing historical evidence or marking the trial complete.
- [x] Verify relative links and public-data rules with `./scripts/verify-repository.sh`, check private-copy ignore behavior and non-overwrite behavior, and inspect the diff. No new automated tests or local iOS rerun are needed for documentation-only changes; existing CI still runs its required jobs.
- [x] Review the bounded documentation and instructions for product/privacy/Apple contract accuracy and prepare the PR handoff. Complete Codex review, address actionable feedback, and wait for required CI and mergeability before final handoff; track those live gates in the PR body and an ignored local ledger. Leave the PR unmerged.

## Open questions
- None block preparation. Actual use and deferred physical observations stay pending until the owner is ready; a public-safe aggregate report is future work after the private trial.

## Verification and review evidence

- All 40 existing portable repository checks pass, including relative Markdown links and public-data guards. No test files, app source, resources, project configuration, or CI behavior changed; no local iOS or physical-device repetition is needed for this documentation-only slice. Hosted required CI will still run before PR handoff.
- The documented private-copy commands were exercised with a fresh copy and a synthetic existing log. The first draft exposed macOS `cp -n` returning a nonzero status when preserving an existing file; an existence check now makes repeat setup succeed while keeping no-clobber copying. Exact snippet reruns preserve the existing bytes. The local blank copy is ignored by `/local-data/` and is not tracked; no observations were added.
- Independent Brooks and Apple/product documentation review found no actionable issue (100/100). The review covered UI labels, ordinary launch versus fixtures, foreground playback rules, separate alarm ownership, observation limits, private log handling, and counting alternative choices. The production-test review was skipped because this change affects documentation only.
- Final Codex feedback, hosted CI, mergeability, and any subsequent fixes remain live PR gates; this plan does not claim they passed before the PR exists. Actual trial participation, direct physical observations, and the eventual public-safe report remain pending.

## Codex follow-up plan

The first completed Codex pass found four documentation gaps. Address each separately with a saved/pushed commit and comment acknowledgement; no product decision or app/test change is needed.

- [x] Explain the silence-only exception using the controller's visible non-settling rest state; retain the foreground rule for silence before future narration (comment 4136306376).
- [ ] Capture a concise per-opportunity rest-window fit outcome so the closeout has contemporaneous evidence (comment 4136306387).
- [ ] Separate directly heard alarm delivery from observed audio cutoff, including unknown/not-applicable outcomes (comment 4136306396).
- [ ] Require a clean checkout before building and recording its commit, preserving unrelated work instead of discarding it (comment 4136306404).

Check each changed document against its underlying behavior, run the portable publication checks, and review the final table structure and private-copy preservation. Request a fresh Codex review after all four fixes and wait for final CI. Actual trial results and physical acceptance remain unverified.
