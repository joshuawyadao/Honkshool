# Plan

Run the full project checkup against merged `main` (`ac026fd`), then repair the confirmed bounded findings with focused regressions. Preserve the production Nap Plan, audio assets, alarm/history contracts, and installed personal-trial build; save the work on `codex/project-checkup` and prepare an unmerged, reviewed PR.

## Scope

- In: full R1–R6/T1–T6 diagnosis, architecture and test maps, reports outside the repository, safe publication of review reels, public Git scope for repository checks, normalized saved-duration presentation in the feasibility console, and durable architecture/verification documentation.
- Out: home-screen redesign, new runtime interfaces, broader catalog or product work, live synthesis/dependency upgrades, device installation, private trial notes, and claims of manual listening or hardware acceptance.

## Action items

- [x] Inspect all significant app/domain/content/runtime/widget modules, the Swift and Python suites, offline scripts, CI/project configuration, and canonical product/domain/decision documents; deduplicate findings and record source-coverage exceptions.
- [x] Reproduce TOOL-1 (review reel overwrites its source) and TOOL-2 (ignored private Markdown breaks public verification) using temporary synthetic files. Confirm UI-001 (raw saved duration disagrees with the bounded deadline) through its view/policy path.
- [x] Finish the unchanged baseline simulator suite; record measured duration, expected device skips, and verification limits in the external Markdown and HTML reports. The Python baseline already passed all 40 checks.
- [x] Protect `scripts/make-george-review-reel.py` destinations with exclusive creation and prepublication source validation; add regression coverage for existing files, source aliases, and unchanged extracted PCM in `tests/test_audio_assets.py`; update `docs/Audio-Preparation.md`.
- [x] Scope publication checks in `tests/test_publication.py` to tracked and nonignored untracked Git files; add isolated temporary-repository regressions proving private/generated exclusions and detection of new public errors and tracked ignored-name artifacts. Preserve existing privacy enforcement.
- [ ] Normalize a restored feasibility saved duration before it is displayed or selected; use the existing Debug-only, isolated UI fixtures and add a UI regression for values outside both bounds. Keep ordinary defaults and production Nap Plan behavior intact.
- [ ] Add `docs/Architecture.md` for current module ownership, test seams, verification choices, and why broad refactoring remains deferred; link it from `docs/Project-Overview.md` and clarify public verification scope in `CONTRIBUTING.md`.
- [ ] Run focused regression checks, the portable gate, the complete simulator suite after the Swift change, and a Release simulator build for fixture exclusion. Reassess changed modules and consumers; update external report scores, fix log, residuals, and stopping reason.
- [ ] Save coherent local checkpoints and push; open a PR, complete Codex/Brooks review and CI, address actionable feedback in separate validated commits, and leave the PR unmerged.

## Open questions

- None block these bounded fixes. The ordinary-entry architecture candidate is speculative and remains deferred under the existing roadmap. Goal-tool bookkeeping is independent of this implementation scope.

## Diagnosis and validation notes

- TOOL-1: Warning, R3/T5; review-reel publication differs from the other offline renderers and lacks destructive-output regression coverage. Extended-Safe: three implementation/test/doc files, existing Python baseline passes, no public signature change.
- TOOL-2: Warning, T2 (with T1 evidence); recursive checks depend on ignored private/generated files. Extended-Safe: the test gate and its regressions/docs, no app contract change.
- UI-001: Suggestion, R6; the feasibility console normalizes its initial selection but displays and later reselects the raw saved preference. Extended-Safe once the iOS baseline passes: one view, the existing fixture module, and one UI test file; no new test infrastructure or public interface change.
- Baseline `./scripts/verify-repository.sh`: 40 passed, 0 failed; 7.88 seconds wall time. Baseline iOS command passed on iPhone 18 Pro Max / iOS 27.0 Simulator in 617.23 seconds wall time, using isolated derived data and no physical opt-ins.
- Reports and raw logs remain outside Git. Public documentation will contain only durable architecture and verified, sanitized outcomes. No personal trial data is read or modified as part of the review.
- Sweep authorization comes from the user's explicit check-and-fix request. `plan-implement-save` owns checkpoints/push; sweep owns bounded edits, verification, and changed-module rescans. Three retry attempts per finding and three noncritical rescan rounds are the maximum; no speculative product/architecture redesign is applied.

- TOOL-1 regression evidence: the old command failed preservation/format tests on temporary synthetic assets. All three new tests now pass, including byte-exact selected PCM and existing/source-alias preservation; the full portable gate passes 43 tests. Real bundled audio is unchanged.

- TOOL-2 regression evidence: the original link gate failed on synthetic ignored notes while the four public-enforcement controls passed. All five scope tests now pass, including nonignored untracked documents and force-tracked ignored-name artifacts. The full portable gate passes 48 tests in 7.04 seconds.
