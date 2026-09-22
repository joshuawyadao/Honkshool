# Plan

Build a pre-play Nap Plan chooser and review flow on `codex/nap-plan-review`, rooted at content commit `8a23174de451e5c8f714af9ff71b1b7e7fbf7dc0`. Use the prepared catalog and pure planner with injected time and availability, then retain the reviewed value as the confirmed snapshot without starting playback.

## Scope

- In: choose available prepared content, duration or exact wake time, available rest sound, and alarm preference; review the fixed deadline, complete route, transitions, shorter or empty-route fallback, post-narration sound, and alarm; confirm an immutable plan.
- Out: production playback, real alarm scheduling, SwiftData history, rain-candidate acceptance, and changes to the feasibility console's test behavior.

## Action items

- [ ] Add a small Foundation-only review adapter and confirmation state around `NapPlanner`, with explicit clock, plan ID, catalog, and sound availability inputs; retain route and review metadata as snapshots.
- [ ] Add the SwiftUI chooser and review screens, reachable from the existing console, with clear empty/error states, native time controls, complete ordered route, transition and fallback details, accessible labels, and honest confirmation messaging.
- [ ] Extend focused unit tests for duration and exact-time requests, invalid and past deadlines, short windows, shorter alternatives, sound fallback, preapproved transitions, missing subsequent content, and snapshot immutability.
- [ ] Add UI tests for choosing/reviewing duration and exact time, displaying fallback and alarm details, confirming the fixed plan, and accessibility identifiers and readable labels.
- [ ] Update `README.md`, `docs/Project-Overview.md`, `docs/Nap-Planning-Domain.md`, `docs/Content-Catalog.md`, and `docs/Project-Implementation-Plan.md` with the actual review boundary and remaining runtime/device work. Keep the product brief and decision history unchanged because the accepted rules do not change.
- [ ] Run targeted simulator tests, the full available simulator suite, `scripts/verify-repository.sh`, Swift formatting, and Debug/Release simulator builds; inspect the final diff and leave the physical iPhone and real alarms untouched.
- [ ] Commit reviewable checkpoints and push `codex/nap-plan-review`; record the parent and final commits for moving only this branch's commits onto updated main after the content branch merges.

## Open questions

- None. The current bundled catalog supplies one prepared session and no accepted ambience; the UI will offer silence now and support injected available ambience and additional routes as the catalog grows.
