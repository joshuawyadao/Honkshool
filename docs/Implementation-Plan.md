# Plan

Continue prepared-content development on `codex/local-content-catalog` from current main (`c5025ad`, PR #3). Preserve the owner's acceptance of narration audition F as a provisional listening reference, then add a small bundled catalog that supplies original narration and source metadata to the existing nap-planning domain.

## Scope

- In: a Foundation-only validated catalog loader, stable session/journey metadata, one original citation-backed Enthusiast script, explicit configurable duration estimates, pronunciation notes, script-bound resume validation, bundled-resource tests, and current product/decision/roadmap documentation.
- Out: feasibility-console redesign, production playback or filtering integration, persistence, a final rain asset, voice downloads, headphone/device installation, paid services, dependencies, distribution, and PR creation or merge. F is a Mac audition with offline processing; its acceptance does not establish identical iPhone direct-speech output. Full-session duration measurement and ambience acceptance remain later Phase 2 work.

## Action items

- [x] Read supplied AGENTS instructions (no repository AGENTS.md exists), canonical docs, current domain/content/tests, and validation configuration; verify clean main equals freshly fetched origin/main and create the feature branch.
- [x] Record D-007's provisional F acceptance and natural-delivery priority, MacBook-speaker-only evidence, unchanged pacing, and outstanding iPhone/AirPods validation. Record gentle rain as D-008's approved direction while preserving the unresolved asset/provenance question. Document the reference recipe and fingerprint without publishing machine-specific paths or unverified audio assets.
- [x] Implement and register a small immutable prepared catalog, bundled JSON loading, source/metadata/reference validation, conversion to `NapCatalog`, and revision-aware UTF-16 resume validation without importing playback frameworks.
- [x] Research and author the first original session with multiple primary sources, paragraph-level citation references, summary, pronunciation notes, and an explicitly unmeasured planning estimate. Bundle it separately from the spike script; document factual review and remaining audio preparation.
- [x] Add focused XCTest coverage for bundled availability, planning integration, source separation, malformed/unsupported data, duplicate/dangling IDs, missing/empty metadata, configurable estimates, and valid/invalid Unicode or revision-specific resume points. Preserve existing tests.
- [x] Run focused catalog tests, the complete simulator suite on an available destination, repository checks, Foundation-only typechecking, formatting checks, and a Release simulator build. Verify resource packaging and privacy-safe docs; no physical listening check is required to finish this branch.
- [x] Review code and content, update README, Product-Brief, Project-Overview, Nap-Planning-Domain, and the durable Project-Implementation-Plan with completed scope and remaining calibration/rain/runtime work.
- [x] Use `save-branch` to inspect, explicitly stage, commit, and push the completed branch without opening a PR.

## Open questions

- None block this bounded slice. F is the approved development reference, not a claim of final device validation. Silence remains the only available fallback until a lawful gentle-rain asset is prepared. The existing direct-speech decision stays in force; any runtime change needed to reproduce F requires separate implementation and evidence.

## Validation results

- Focused `PreparedCatalogTests`: 22 passed, no failures or skips. Full simulator suite: 125 passed (111 unit tests and 14 UI tests), no failures or skips, on iPhone 17 Pro / iOS 26.5.
- The first full-suite invocation through `scripts/test-ios.sh` stalled in Xcode's simulator diagnostic collection and was terminated without a complete result. Running the same full suite with `-parallel-testing-enabled NO -collect-test-diagnostics never` completed successfully; no tests or assertions were removed. The successful result contains one internal quality-of-service priority-inversion warning; the focused catalog result contains none.
- `./scripts/verify-repository.sh`: all 12 checks passed. Foundation-only domain/catalog typechecking and strict Swift formatting checks passed. The Release simulator build passed, and its bundled JSON was byte-identical to the source resource.
- Independent code review found no actionable correctness issues. Source/script consistency, documentation links, resource registration, and absence of private local paths in public docs were checked. Full-session audio measurement, target-device voice availability, headphone listening, and a final rain asset remain outside this slice.
