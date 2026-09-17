# Plan

Continue `codex/local-content-catalog` with a review of the saved catalog and a bounded audio-preparation pass. Render the full prepared session using audition F's natural voice/rate and conservative focused softening, prepare a reusable gentle-rain candidate with documented provenance, and record measured evidence without claiming target-iPhone equivalence.

## Scope

- In: read-only Brooks review of `cbfde27`, reproducible Mac narration rendering, local full-session and short listening samples, a lawful offline rain candidate, duration/asset metadata, focused verification, and updated audio/content/roadmap documentation.
- Out: PR creation or merge, production playback or DSP integration, feasibility-console redesign, persistence, voice downloads, new dependencies, paid services, automatic playback, physical-device installation, and unverified claims of listening approval. The original F file and timing remain unchanged; this full script needs its own listening review.

## Action items

- [x] Inspect current branch/status and freshly fetched remote state, product decisions, prepared content, tests, and the existing A–F rendering/processing artifacts; preserve unrelated changes.
- [x] Review the saved catalog with Brooks review and address any concrete findings before extending it. The scoped review found no actionable findings.
- [x] Add a small Mac-only rendering tool that selects the explicit reference voice/rate, requires complete speech callbacks, and produces paragraph audio plus exact script/revision and duration evidence. Never silently substitute a voice or publish an incomplete render.
- [x] Prepare the full narration and a brief comparison using the existing offline F processing recipe, preserving natural articulation, pause frames, and duration; retain local previews outside the repository. Calibrate the configurable estimate with clearly labelled Mac-only evidence.
- [x] Select a gentle-rain candidate with explicit redistribution terms; preserve provenance and the original/derived fingerprints, prepare its loop and level, and verify decoded audio, seam continuity, absence of clipping, and loudness consistency. Do not declare subjective acceptance from signal checks.
- [x] Add focused tests for new tooling/asset contracts and run the appropriate repository checks, affected simulator tests, and Release build; preserve existing assertions and document blocked checks honestly.
- [x] Update Content-Catalog, Content-Review, Narration-Reference, Decision-Log, README, Project-Overview, and the durable Project-Implementation-Plan with measurements, limitations, and next work. Add a focused audio-preparation/provenance document.
- [x] Review the final diff, then use `save-branch` to stage only this work, commit, and push; report samples, validation, review findings, and remaining device/listening work.

## Open questions

- None block offline preparation. F remains the accepted sound reference and direct speech remains the initial runtime decision. Mac renders provide development timing evidence only; target-iPhone voice availability, output, and timing still require a later device check. Gentle rain is the approved direction; this candidate's listening acceptance remains pending.

## Results and validation

- Brooks review of the saved catalog and a separate review of the audio-preparation diff found no actionable issues. These were scoped code/evidence reviews, not subjective listening assessments.
- The unchanged 13-paragraph revision-1 script rendered completely on the Mac at the explicit reference voice/rate. Full processed duration is 674.222 seconds; the configurable estimate is 675 seconds. The original F fingerprint is unchanged. A compact AAC listening copy decoded to the exact original 32,362,656 frames without clipping.
- The CC0 rain candidate is bundled with provenance. Deterministic preparation retains an unbroken loop, with no clipped samples and objective seam/level checks. These checks do not establish subjective calmness or accept the short repeating recording.
- Focused catalog/audio tests: 23 passed. Full simulator regression: 126 passed (112 unit and 14 UI), zero failures/skips, on iPhone 17 Pro / iOS 26.5. Optional Xcode diagnostic collection was disabled because the earlier branch-validation run stalled there; no tests or assertions were omitted. The full result retains one internal priority-inversion warning; focused tests have no runtime warnings.
- Portable repository suite: 26 passed, including 14 audio/measurement checks and 12 existing publication checks. Swift renderer typechecking with warnings as errors, strict formatting, help, and four invalid-input checks passed. The Release simulator build and byte-for-byte resource packaging checks passed.
- No physical-device installation or listening check was required to produce this candidate. iPhone voice compatibility/timing, full-session comfort/pronunciation, rain acceptance, and production playback integration remain open and are documented in the durable roadmap.
