# Plan

Extend How a Car Works into a two-session journey by preparing Air, Fuel, and Spark with the accepted Kokoro George cadence and connecting it to the existing catalog-driven planning and history flows. Preserve the first session, fixed deadlines, honest completion evidence, and the explicitly deferred manual rain checks. Save this work on `codex/two-session-journey` and prepare a separate reviewed PR before the ten-nap personal trial.

## Scope
- In: original citation-backed Enthusiast content for session two; pinned offline George `bm_george` at `0.86`; measured audio/provenance and resource registration; clear next-session context; real two-session planning, progress, Resume/Replay, handoff, history, and deadline coverage; current documentation; focused checkpoints and PR review.
- Out: the ten-nap trial itself, additional journeys or a full catalog, cross-journey branching UI, random/restart features, home-screen redesign, new voices, runtime synthesis or networking, persistence-schema changes, and any claim that deferred subjective or physical observations have passed.

## Action items
- [x] Merge green PR #9 as `1c7b3bf`, verify deletion of `codex/gentle-rain-playback` locally and remotely, and create this branch from clean main. Inspect the catalog, content review, preparation/provenance, roadmap, and existing history/planner tests with bounded read-only scouts.
- [x] Research primary sources and write original Air, Fuel, and Spark narration with paragraph-linked citations, pronunciation guidance, and stable revision-1 identity. Review its factual qualifications and calm continuity with the first session; target the existing approximate 12–15-minute format without padding or changing voice speed to force a duration.
- [x] Restore the isolated preparation environment from recorded versions and pinned model/voice hashes. Protect existing narration outputs from accidental overwrite, render only the new session, and verify exact text/chunk order, PCM/frame counts, level/clipping, provenance hashes, and a measured rounded-up planning estimate. Keep preparation dependencies and cache outside the shipped app and Git.
- [x] Bundle the new WAV and provenance, append the stable session ID to the existing journey, and retain the first session's revision, text, and audio fingerprint. Reuse existing navigation and route assembly; make the next session's title clear where helpful without introducing another flow.
- [x] Extend portable and Swift catalog checks to both actual assets; test partial-first resume, completion-only advancement to session two, replay preserving history, final journey completion, a real two-session approved route and handoff, partial-second recovery, and rain/deadline behavior. Update only one-session fixture assumptions that the catalog expansion invalidates.
- [x] Update README.md and docs/Content-Catalog.md, Content-Review.md, Audio-Preparation.md, Project-Overview.md, Project-Implementation-Plan.md, and relevant domain/decision notes. Correct stale single-session/audio status claims while retaining the historical preparation evidence and deferred physical acceptance.
- [x] Run targeted Python and Swift/UI tests, repository verification, formatting/project checks, the full simulator suite, and a Release simulator build. Review Apple timing/history boundaries and original content; address concrete failures without weakening assertions.
- [x] Checkpoint coherent work, push the branch, open [PR #10](https://github.com/joshuawyadao/Honkshool/pull/10), and complete Codex/Brooks review. Leave the new PR unmerged and the ten-nap trial as the next task. Hosted CI, subsequent review activity, and final merge readiness are tracked in that PR and must pass before handoff.

## Open questions
- None block implementation. The user selected the two-session journey before the ten-nap trial and already approved the George cadence. Existing Continue/Resume/Replay and journey counts are data-driven, so new broad journey UI is unnecessary. Full-session listening and the deferred rain device observations remain unverified; they do not block preparing this separate implementation PR.

## Discovery and verification notes
- Existing flow: the ordered catalog controls session selection, full-route review, multi-session allocation, and completion-only progression. The feasibility console intentionally keeps its original first-session spike.
- Known updates: the 20-minute route-end explanation changes from journey end to next session not fitting; history progress changes from one to two prepared sessions; tests that equate first-session completion with whole-journey completion need the new transition.
- Original first-session invariants: `turning-fuel-into-motion`, revision `1`, 727.625 seconds, audio SHA-256 `7117b18ce10e45844b6eba29936370131290baf30131b71cf2b01d5999847f37`.
- Initial discovery: preparation supported session/output arguments but overwrote output paths. The added output-safety guard and failure tests protect the original asset during expansion.
- No reusable pinned model manifest or Kokoro environment was found in the project, temporary workspace, or expected model cache. Recreate from recorded dependency versions and verify the existing provenance's asset hashes before offline rendering.
- PR #9's final hosted CI passed on retry after an unreproduced timeout in an unchanged feasibility UI label assertion. Keep that history separate from this branch; diagnose any recurring failure from its actual evidence.

## Implementation checkpoint

- Source review completed with no factual narration blocker; three source titles corrected and one repetitive sentence removed before rendering. Air, Fuel, and Spark is 1,847 words in 14 paragraphs.
- Recreated the recorded local Python preparation dependencies and verified the exact pinned model/voice assets. The offline render measures 756.75 seconds, 18,162,000 frames, and 36,324,044 bytes; planning estimate 760 seconds. WAV SHA-256: `8f8fb647eccb6eec0feeefb20127a681c101ffccb5d94ff9b7b49c95e5cc5fc5`. Exact text/chunk assembly, PCM readback, level checks, and no clipping passed. The English tokenizer version is now captured in provenance.
- Original first-session catalog object is identical to merged main, and the original WAV retains its accepted fingerprint. Existing history and planner logic handle both sessions; only next-title context was added to production Swift UI.
- Apple contract review found no actionable timing, history, route, or interruption issue. It did not establish physical or listening acceptance.
- Portable repository checks: 37 passed. Strict Swift format, Python compile, project plist, and whitespace checks passed. Focused simulator tests are running; full suite, Release build, Brooks/Codex review, and hosted CI remain pending.

## Validation and review ledger

- First focused simulator run: 69 passed, 2 failed. All five selected UI cases passed. One new run-controller assertion expected silent resting after explicitly selected rain; corrected to the existing `ambience` phase. An older rewind/checkpoint test resumed near the first file's end, leaving enough budget for the new second session; constrained that test to its intended single-session window and asserted its route, retaining all checkpoint identity and completion checks. No production playback code changed for these test failures.
- Release simulator build passed. Xcode's diagnostic collection delayed the first focused run after tests completed; only that run's diagnostic collector was stopped, and its result bundle finalized with the counts above. Subsequent local runs use the repository's usual `collect-test-diagnostics never` setting.
- Corrected run-controller suite: 34 passed, 0 failed. Combined with the unchanged focused catalog/navigation/UI results, the affected behavior is green. The full local simulator suite is running; the separate PR will retain pending validation status until required checks finish.

## Local validation closeout and PR handoff

- Full simulator suite: **233 passed, 0 failed, 6 expected opt-in physical-device skips**. This includes the corrected checkpoint test, both actual bundled assets, ordered plan review, history progression, partial-second recovery, rain and fixed-deadline behavior.
- Portable repository suite: **37 passed**. Strict Swift formatting, Python compilation, project plist, whitespace checks, and the Release simulator build passed.
- Source review and Apple contract review found no blocker. Brooks PR review of `origin/main...9c932ab`: 100/100, no Iron-Law findings. Codex review of `9c932ab` completed with no findings and no inline threads. The following commit updates validation documentation only.
- The review cycle and CI remain visible on [PR #10](https://github.com/joshuawyadao/Honkshool/pull/10); its body/checks are the live status record rather than requiring a documentation-only commit after every hosted check. No conflict resolution or production-code review fix was needed at this checkpoint. The PR must remain unmerged at handoff.
- Manual full-session comfort, relative rain level, locked controls, and physical headphone disconnection remain deferred, with the approximately ten-nap personal trial next after this journey PR is merged.

## Codex follow-up: separate narration publication directories

- [ ] Address [Codex P2 feedback](https://github.com/joshuawyadao/Honkshool/pull/10#discussion_r4127829956): prepare both output and provenance parent directories before loading or rendering the model. A fresh provenance directory currently fails after the WAV is written, and the overwrite guard then prevents a straightforward retry.
- [ ] Add a fast regression for distinct missing parent directories and an invalid provenance parent; verify failure occurs before any WAV is published. Preserve early occupied/overlapping-path rejection and exclusive writes.
- [ ] Run the focused publication tests and the portable suite, save and push this item, acknowledge the Codex comment, and re-check hosted CI and review status. No narration re-render, app behavior change, or full local simulator repetition is needed for this preparation-only fix.

There are no new product questions. The first completed Codex pass had no findings; the ready-triggered pass identified this bounded script issue. The hosted iOS run on the preceding commit was still in progress when the feedback arrived.
