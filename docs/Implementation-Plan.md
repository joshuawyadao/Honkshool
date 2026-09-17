# Plan

Continue the owner-preferred direction of candidate G after feedback that its “s” sounds are less robotic and remain clear, but still too noticeable. Make one controlled increase in local attenuation while preserving G's exact timing, detector regions, and smooth fades.

## Scope

- In: a short H audition, independent PCM comparison, and documented feedback/results on `codex/local-content-catalog`.
- Out: changing tempo, cadence, pauses, region boundaries, voice, text, pitch, full-session master, rain, app code, runtime DSP, dependencies, or opening/merging a PR.

## Action items

- [x] Inspect the clean branch, G's generation recipe, reference evidence, and current validation scope.
- [x] Generate H from the original gain-adjusted paragraph, increasing the maximum direct sample attenuation from 3 to 4.5 dB inside the same 20 regions. Preserve G and earlier files.
- [x] Verify exact frame counts, original silence, unchanged samples outside G's mask, no clipping/polarity changes/amplitude increases, and unchanged rain/timeline; have an independent reviewer recompute the output.
- [x] Record that the owner prefers G's clearer, less robotic consonants while further improvement is still requested. Update the narration reference, audio preparation status, decision history, and durable roadmap without declaring H accepted.
- [x] Run repository checks, inspect the documentation-only diff, then use `save-branch` to commit/push the checkpoint. App/test code and resources are unchanged, so no new test files or iOS build are needed; artifact checks validate this local audio revision.
- [x] Present the short H comparison at the same playback level and timing, leaving adoption across the session dependent on listening feedback.

## Open questions

- None block this controlled increment. The owner confirmed G's improvement and clarity; H tests whether a further 1.5 dB reduction makes those sounds less noticeable without losing clarity. Signal measurements cannot establish that listening outcome.

## Results

- H changes only maximum attenuation: 4.5 dB instead of G's 3 dB, retaining all 20 event boundaries and fades. The dry preview is exactly 1,204,160 frames / 25.086667 seconds. 94.736307% of paragraph frames remain bit-identical to G and the original outside the mask.
- Independent standard-library reconstruction matched every exported sample. No clipping, polarity flips, amplitude increases, altered zero samples, or edits outside G's mask were found. Rain and transition timing remain unchanged. Perceived naturalness and clarity still require listening.
- All 26 repository checks passed. Documentation is the only repository change; no test files or app resources/code changed, so no simulator/build rerun was warranted. Previous full-session and voice-reference artifacts remain preserved.
- The owner's preference for G is recorded as relative improvement with remaining work, not final acceptance. H remains a local short comparison pending listening feedback.
