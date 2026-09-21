# Plan

Use the owner's cross-device listening results to move from consonant attenuation to a small source-voice comparison. Prepare the same closing paragraph with two available Apple voices, preserve natural delivery, and record measurements and the remaining listening decision.

## Scope

- In: installed-voice inventory, local unprocessed auditions, objective audio verification, and current narration evidence/documentation on `codex/local-content-catalog`.
- Out: downloads, paid services, new dependencies, production speech changes, full-session replacement, estimate changes, rain changes, PR creation, and merge. New mobile transfers require authorization covering the new files and destination.

## Action items

- [x] Inspect the clean branch, earlier audio/render procedures, prepared text, relevant reference/product/decision/roadmap docs, and repository checks.
- [x] Enumerate installed voices and select two distinct candidates with explicit identifiers; record availability without inferring perceptual quality from API metadata.
- [x] Render the unchanged whole paragraph at a natural base rate near the preferred faster Aaron sample; measure actual durations and preserve each voice's native timing. Apply only constant level matching, PCM conversion, and equal end padding.
- [x] Independently verify text hashes, completed renders, formats, frames, level matching, clipping, and preservation of the earlier samples/master. Keep audio and scratch tools outside Git.
- [x] Record the unresolved I feedback and cross-player/cross-device comparison in `docs/Narration-Reference.md`, `docs/Audio-Preparation.md`, `docs/Decision-Log.md`, `docs/Product-Brief.md`, and the durable `docs/Project-Implementation-Plan.md`. Preserve earlier approvals and distinguish mobile WAV playback from iPhone synthesis evidence.
- [x] Run `./scripts/verify-repository.sh` and review the documentation diff. No test files or app builds are needed because repository executable behavior and bundled assets are unchanged; local audio receives direct artifact checks.
- [x] Complete this plan and use `save-branch` to commit/push the documentation checkpoint. Present the prepared comparison and its remaining listening/delivery step without claiming a voice-quality fix.

## Open questions

- None block local preparation and the documentation checkpoint. Perceived naturalness requires the owner's listening; a short Mac render does not establish voice availability or equivalent direct speech on iPhone.

## Results

- The cross-device Aaron comparison remains unsatisfactory, with rate 0.50 only slightly preferred. This supports investigating the source voice without claiming the exact cause.
- Installed Samantha and Daniel rendered the unchanged paragraph successfully. Their previews are 23.742041 and 24.864490 seconds respectively, with native timing and constant overall level matching only. They are default-quality diagnostic alternatives, not approved replacements.
- Independent CAF/WAV parsing and PCM reconstruction pass: both exports exactly match their source plus the recorded constant gain and padding; no clipping. RMS differs from the Aaron control by less than 0.000001 dB. F and the full-session master retain their original hashes.
- All 26 repository checks passed. Only six documentation files changed; no application tests or build were rerun because executable behavior and bundled resources did not change. Local audio and scratch tools remain outside Git.
- New mobile-file delivery is awaiting authorization covering these files; listening acceptance, target-iPhone synthesis, and any full-session voice replacement remain future work.
