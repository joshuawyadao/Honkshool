# Plan

Compare premium English accents now that the owner finds Lee and Karen substantially more human throughout the passage. Preserve the current relaxed delivery, record the improved source-voice direction, and describe how a future voice selector would respect fixed Nap Plans.

## Scope

- In: a small same-passage premium accent audition, exact voice/quality and timing verification, updated listening evidence and roadmap, and a saved documentation checkpoint on `codex/local-content-catalog`.
- Out: implementing a selector in the feasibility console, changing the production runtime or full-session master, recalibrating the full catalog from a short sample, paid services, new dependencies, public audio distribution, iCloud transfer, PR creation, and merge.

## Action items

- [x] Inspect branch state, relevant product/reference/decision/roadmap docs, current direct-speech selection, and repository/audio validation procedures.
- [x] Obtain a small set of premium voices with different English accents through Apple's voice controls; verify exact installed identifiers and quality before rendering. Preserve the original system voice setting and stop unreliable UI operations rather than substitute a basic voice.
- [x] Render the unchanged whole closing paragraph near the current rate; match overall level only, retain native timing, and present a limited set of comparisons alongside the existing Australian reference.
- [x] Verify text identity, completion guards, source/export hashes, native formats, frame counts, exact PCM conversion, duration, no clipping, and preserved prior references. A successful download or premium label does not establish naturalness or iPhone synthesis equivalence.
- [x] Record rejection of compact Samantha/Daniel and positive Lee/Karen Premium feedback in `docs/Narration-Reference.md`, `docs/Audio-Preparation.md`, `docs/Decision-Log.md`, `docs/Product-Brief.md`, `docs/Project-Implementation-Plan.md`, and the README status. Record selector prerequisites as a proposal, preserving historical decisions.
- [x] Run `./scripts/verify-repository.sh` and review the diff. No application tests/build or new test files are needed for docs plus local audition artifacts; executable behavior and bundled assets stay unchanged.
- [x] Finish the accent comparison, update the evidence and roadmap, and use `save-branch` to commit/push the completed work. Present the samples and the remaining listening decision.

## Open questions

- No product clarification is needed. The owner downloaded the requested voices, and both now resolve as premium quality; the earlier download blocker is resolved. The user requested comparison first, or a selector if premium voices behave alike; uniform delivery is not established. A selector is feasible but is proposed for subsequent product playback work, not implied implemented by this audition.

## Results

- The owner completed the Ava/Jamie downloads after the documented automation blocker. Both resolve as quality 3: `com.apple.voice.premium.en-US.Ava` and `com.apple.voice.premium.en-GB.Malcolm` (display name Jamie Premium).
- Same-paragraph auditions rendered at rate 0.50. Ava is 24.523719 seconds with padding; Jamie is 24.176689 seconds. Each preserves native cadence and uses only constant level matching, PCM conversion, and equal end padding.
- Separate standard-library CAF/WAV parsing and exact PCM reconstruction pass. Text, hashes, formats, frame counts, levels, and absence of clipping are verified. Lee/Karen, original F, and the full-session master retain their fingerprints.
- The narration reference, decision log, preparation status, and durable roadmap now record completed audition preparation and pending listening. README and product-brief content from the previous checkpoint remains accurate; no further edits were needed there.
- No application code, test files, or bundled assets change. App builds are unnecessary for this documentation/local-audio completion. All 26 repository checks passed, along with direct artifact validation and the reviewed documentation diff. The completed audition evidence is saved on the current feature branch.
- Default voice choice, a curated selector, full-session remeasurement, and target-iPhone synthesis validation remain separate next steps. Preparing these auditions does not establish their perceived quality or implement a selector.
