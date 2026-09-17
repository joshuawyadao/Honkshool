# Plan

Use the owner's specific remaining problem words—first, distant, is, nothing, complete, settle, and space—to refine the preferred H audition. Keep its exact tempo, cadence, and surrounding speech, and use word-local evidence rather than increasing attenuation across the whole passage.

## Scope

- In: local word alignment and signal inspection, one bounded word-focused audition, independent PCM checks, and documented feedback/evidence on `codex/local-content-catalog`.
- Out: replacing the voice or full-session master, changing text/timing/pitch, production DSP or runtime integration, rain changes, new dependencies, PR creation, and merge. A diagnostic re-render may collect speech markers only if it can be aligned to the original; it will not replace the original playback samples.

## Action items

- [x] Inspect the clean saved branch, H/G recipes, original audio, current docs, and available local speech marker APIs.
- [x] Map the seven words to reproducible metadata anchors using a byte-identical diagnostic render. Signal inspection showed these are not acoustic word boundaries; record that limitation and use explicit local neighborhoods with conservative signal-selected edits.
- [x] Prepare one short candidate from H, limiting new edits to signal-selected bursts in the seven local neighborhoods. Use smooth direct gain on supported noisy bursts; retain complete unchanged because the conservative detector finds no qualifying event; preserve all prior auditions and every sample outside the new mask. Do not claim exact phoneme alignment or that neighboring coarticulation is excluded.
- [x] Verify exact frame count, original silence and timing, no clipping, unchanged samples outside the target intervals, and source fingerprints; obtain independent verification. If source speech remains the limitation, document it without asserting that lower level improves synthesis.
- [x] Record the owner's preference for H and the seven-word feedback in the narration reference, audio preparation status, decision log, and durable roadmap. Run repository checks; no new app tests/build are needed for a documentation-only commit with locally validated audio artifacts.
- [x] Use `save-branch` to commit/push the evidence and present the same short passage for listening feedback before applying the treatment more broadly.

## Open questions

- None block the targeted audition. The owner supplied the specific words and approved the direction. Artifact measurements can establish edit scope and timing, while listening must establish perceived naturalness and clarity.

## Results

- The diagnostic marker render exactly matches the original CAF; a matching suffix establishes the internal offset reset. Acoustic checks demonstrate that word metadata anchors are approximate, so no exact phoneme boundary claim is made.
- I applies 1 dB additional smooth reduction around first, distant, nothing, settle, and space, and 1.5 dB around is. Its 11 selected bursts occupy 0.699542 seconds; 97.154793% of paragraph frames lie outside the new mask and remain bit-identical to H. Complete is unchanged because no qualifying noise event was found.
- Independent detector recomputation and gain reconstruction match every event and exported sample. Dry duration is exactly 1,204,160 frames / 25.086667 seconds. Timing, silence, zeros, polarity, and rain are preserved, with no amplification or clipping. Original F and full-session fingerprints remain unchanged.
- All 26 repository checks passed. Only five documentation files changed in the repository; no new test files or simulator/build rerun is warranted. Local audition and diagnostic artifacts remain outside the repository.
- I is a short listening candidate. Its naturalness and clarity remain unverified by listening; complete's reported artifact is unresolved. No full-session or runtime adoption follows from this pass.
