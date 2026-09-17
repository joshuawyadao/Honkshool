# Plan

Refine the local narration audition after the owner approved its tempo and cadence but reported robotic “s” syllables. Preserve every sample position and pause, compare the unprocessed paragraph with the spectral-softened result, and prepare a short alternative that softens only the level of narrowly selected consonant bursts.

## Scope

- In: signal inspection, a local short comparison, exact timing/waveform checks, and updated narration feedback/evidence on `codex/local-content-catalog`.
- Out: production DSP or playback changes, new voices, speech regeneration, stretching, pitch changes, rain changes, replacement of the full-session reference before listening acceptance, dependencies, PR creation, and merge.

## Action items

- [x] Inspect the clean saved branch, existing reference recipe, raw paragraph audio, full-session evidence, and validation configuration; refresh remote status without discarding work.
- [x] Compare existing raw and processed consonant regions and select a conservative alternative that avoids reconstructing their frequency components while retaining the approved timing.
- [x] Generate a short local audition from the original gain-adjusted PCM, with smooth attenuation confined inside a stricter subset of the existing detected regions and no edits to adjacent speech or pauses. Preserve previous artifacts.
- [x] Verify matching frame counts, bit-identical samples outside selected regions, intact silence, no clipping, unchanged timing, and a controlled level difference; obtain an independent check. No test-file changes or iOS rebuild are needed because this slice commits documentation only and changes no app resource or executable code.
- [x] Record the owner's positive cadence feedback and remaining sibilance issue in the narration reference, preparation record, decision log, and durable roadmap; run repository checks and inspect the final diff.
- [x] Use `save-branch` to commit and push the documented audition evidence, then present the short candidate without claiming subjective improvement or promoting it to the full session.

## Open questions

- None block the short audition. A word or timestamp was requested as optional guidance; absent that detail, use the complete closing paragraph from the most recent short preview. Listening feedback will determine whether to use this approach more broadly. If the synthetic character persists, further attenuation alone may not meet the intended voice quality.

## Results

- Candidate G uses 20 stricter noise-dominant regions within the prior windows, with smooth attenuation of up to 3 dB on original PCM. The paragraph remains 1,180,160 frames; the dry comparison remains 1,204,160 frames (25.086667 seconds).
- Independent recomputation matched the exported candidate exactly: 94.736307% of paragraph frames remain unchanged outside the mask, all zero samples and pauses are intact, waveform alignment has zero measured lag, and no clipping or amplitude increase occurs. The transition's rain and timing are byte-identical to the previous preview.
- Original F, the full-session master, catalog text/estimate, app/runtime code, and rain asset remain unchanged. G is local and unaccepted; no subjective improvement is claimed from signal checks.
- All 26 portable repository checks passed. No test files changed and no simulator/build rerun was warranted for this documentation-only repository change; the previous 126 simulator tests and Release build remain historical validation of unchanged app resources/code.
- Optional word/timestamp guidance was not available during preparation, so the complete closing paragraph was used as stated. The next step is listening comparison before applying this approach across the session.
