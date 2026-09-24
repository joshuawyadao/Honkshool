# Prepared content catalog

`Honkshool/Content/PreparedCatalog.swift` loads the app-bundled `Honkshool/Resources/PreparedCatalog.json`. It uses Foundation only and makes no network requests. This is the prepared-content boundary between authored narration and the existing [nap-planning domain](Nap-Planning-Domain.md).

The catalog currently contains **How a Car Works → Turning Fuel Into Motion** at Enthusiast detail. The script is original, with paragraph-linked references and a configurable duration estimate informed by a Mac development render. [Content-Review.md](Content-Review.md) records factual review and estimation evidence. The existing feasibility console continues to use `SampleContent`; the new catalog has no production playback or persistence connection yet.

## Loading and planning

- `PreparedCatalog(data:)` decodes injected JSON and returns immutable journeys, prepared sessions keyed by stable ID, and a `planningCatalog` snapshot.
- `PreparedCatalog.load(bundle:)` reads the named JSON resource from the supplied bundle, defaulting to the app bundle. Missing resources, malformed JSON, unsupported schemas, and invalid metadata throw errors. Loading does not silently substitute the spike script or partially accept a broken catalog.
- `planningCatalog` contains the existing `Journey` and `Session` values, including their configured duration estimates. It can be passed directly to `NapPlanner.makePlan`; loading never selects or changes a route.
- A CC0 rain candidate and its provenance now ship as resources. They are not connected to playback or exposed as an available planner choice yet; callers continue to supply an empty available-ambience set until that adapter is implemented. A requested but unavailable ambience resolves to silence under the existing planner rules.

There is no clock, random choice, speech framework, persistence API, or content download in the loader. The only file access is the bundle adapter; decoding and validation operate on `Data`.

## Version 1 format

The top-level object has `schemaVersion`, `journeys`, and `sessions`.

Each journey has `id`, `title`, ordered `sessionIDs`, and `nextJourneyIDs`. Each prepared session has:

- Stable `id`, script `revision`, `title`, `language`, and `detailLevel` (currently `enthusiast`).
- A short `summary`, configurable positive `estimatedDuration` in seconds, and a human-readable `durationEstimateBasis`.
- `paragraphs`, each with exact `text` and a list of `sourceIDs`. Original nonfactual framing may use an empty list.
- At least two distinct `sources`, each with `id`, `title`, `publisher`, and an absolute HTTPS `url` without credentials.
- Optional-in-content `pronunciations` (an array that may be empty), each with a `term` present in the narration and editorial `guidance`.

The loader rejects blank required text, duplicate identities or source URLs, unresolved paragraph citations, unused source entries, unreachable sessions, and dangling journey/session/branch references. Unlike the more general `NapCatalog`, this bundled authoring format is self-contained: unprepared future sessions and journeys are omitted instead of advertised as available. The domain's missing-content behavior remains available to other callers.

These structural checks do not prove factual accuracy, authorship, licensing, source independence, or listening quality. Editorial review remains necessary.

## Spoken text and resume positions

`PreparedSession.narration` is the paragraph texts joined with exactly two newline characters. Titles, summaries, citation URLs, source names, and pronunciation guidance are not appended to speech. The loader does not rewrite punctuation or apply pronunciation substitutions.

`narration(resumingAt:)` checks the checkpoint's session ID and revision against the prepared session, then returns the exact script suffix at its UTF-16 offset. The offset must lie before the end of the script at a complete Swift `Character` boundary. Negative/out-of-range offsets, end-of-script checkpoints, mismatched revisions, and offsets inside surrogate pairs or combined characters are rejected. End-of-script playback belongs to completion handling, not an invented remaining segment.

The future runtime must still capture actual speech progress and remaining-duration estimates. Character validation is not a claim that any arbitrary character is an ideal spoken restart point. The adapter owns word/utterance boundary selection and any mapping introduced by speech transformations.

Keep IDs stable across editorial updates. Change `revision` whenever narration text or its resume positions change, including paragraph ordering or punctuation. A new script revision must not reuse old offsets. Changing a planning estimate or display-only source metadata need not change the spoken revision. Replay, restart, and alternate branches still append history under the existing domain contract.

## Audio status

[Narration F](Narration-Reference.md) is the approved provisional listening reference. Its 38.86-second duration belongs to the separate 97-word audition, not this full session. The owner's MacBook-speaker acceptance lets development continue; AirPods and target-iPhone playback remain unverified.

F combines a Mac-rendered Apple voice with editorial pauses and narrowly applied offline softening. The catalog does not assume that the Mac voice identifier exists in the iPhone app or that direct speech reproduces those edits. D-001's accepted direct-speech strategy remains unchanged. Any change of playback strategy must be separately implemented and validated.

The complete prepared Kokoro George `0.86` narration measures 727.625 seconds; the configurable estimate is 730 seconds, rounded up to five seconds. The catalog identifies the exact bundled WAV by resource name, duration, and SHA-256 without coupling the domain layer to AVFoundation. This is not a completion condition, a reason to change speaking rate, or permission to move the fixed wake deadline. Physical-iPhone playback and full-session pronunciation/listening review remain open. See [Audio-Preparation.md](Audio-Preparation.md) for the preparation command, fingerprints, historical Aaron evidence, rain provenance, and validation limits.

Gentle steady rain is the approved direction. A processed window-rain candidate and its CC0 provenance are bundled, with objective loop and level checks. Its subjective comfort and final selection remain pending. Silence remains the available fallback until the accepted asset is connected to playback. Generated narration auditions remain outside the repository.

## Verification

`PreparedCatalogTests` exercises the packaged resource and planner connection, malformed and inconsistent data, citation separation, estimate changes, missing bundles, exact revision/Unicode resume behavior, and actual decoding of the rain file with matching provenance. These tests run through the existing app-hosted unit-test target, so bundled loading checks the actual application resource rather than a separate test fixture copy. Portable audio tests verify asset fingerprints, PCM properties, loop boundaries, preparation errors, and script/measurement consistency.

Run `./scripts/test-ios.sh` for the full simulator suite and `./scripts/verify-repository.sh` for repository checks. The loader and `NapContent.swift` also typecheck with Foundation alone. No phone installation, audio playback, or new manual acceptance is needed for this catalog branch.
