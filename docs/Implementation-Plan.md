# Plan

Record Kokoro George at model speed `0.86` as Honkshool's preferred narration and cadence reference after the owner accepted its human, calm documentary delivery. Preserve the earlier Apple and tuning evidence while making the next engineering gate an on-device Kokoro feasibility check.

## Scope

- In: accepted listening direction, exact audition settings and fingerprints, superseding decision history, updated product and roadmap status, repository validation, and a saved documentation checkpoint on `codex/local-content-catalog`.
- Out: adding Kokoro or another dependency to the app, bundling generated narration, changing the configured 675-second estimate, implementing playback or persistence, accepting rain, adding a voice selector, creating a PR, or merging.

## Action items

- [x] Confirm the branch is clean and preserve the existing premium-voice and direct-speech decision history.
- [x] Record the accepted George voice and `0.86` cadence reference, including the short and 408-word listening evidence, exact hashes, and processing boundaries.
- [x] Update D-007 as resolved for narration direction and record that D-001 must be revisited before production integration because AVSpeechSynthesizer cannot reproduce the accepted Kokoro output.
- [x] Update the product brief, audio-preparation status, README, and durable roadmap so future work starts with a bounded on-device Kokoro feasibility slice.
- [x] Verify documentation consistency and run `./scripts/verify-repository.sh`; skip application tests and builds because no executable code, bundled asset, dependency, or project configuration changes.
- [x] Review the final diff, stage only the documentation changes, then commit and push the current feature branch with `save-branch`.

## Open questions

- No product clarification is needed. George at Kokoro speed `0.86` is the accepted direction; iPhone performance, background behavior, packaging, notices, full-session timing, and rain interaction remain validation work rather than assumptions.

## Results

- Accepted Kokoro `bm_george` at model speed `0.86` as the preferred calm-documentary narration reference and preserved the prior Apple voice auditions as historical evidence.
- Resolved D-007 through D-023 while keeping app integration conditional on a bounded target-iPhone feasibility check.
- Updated the durable roadmap and product documentation without adding an app dependency, generated audio asset, playback runtime, or new duration estimate.
- Passed all 26 repository checks in `./scripts/verify-repository.sh` and `git diff --check`. Application tests and builds were not run because this checkpoint changes documentation only.
