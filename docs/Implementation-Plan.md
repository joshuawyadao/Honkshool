# Plan

Build a pre-play Nap Plan chooser and review flow on `codex/nap-plan-review`, rooted at content commit `8a23174de451e5c8f714af9ff71b1b7e7fbf7dc0`. Use the prepared catalog and pure planner with injected time and availability, then retain the reviewed value as the confirmed snapshot without starting playback.

## Scope

- In: choose available prepared content, duration or exact wake time, available rest sound, and alarm preference; review the fixed deadline, complete route, transitions, shorter or empty-route fallback, post-narration sound, and alarm; confirm an immutable plan.
- Out: production playback, real alarm scheduling, SwiftData history, rain-candidate acceptance, and changes to the feasibility console's test behavior.

## Action items

- [x] Add a small Foundation-only review adapter and confirmation state around `NapPlanner`, with explicit clock, plan ID, catalog, and sound availability inputs; retain route and review metadata as snapshots.
- [x] Add the SwiftUI chooser and review screens, reachable from the existing console, with clear empty/error states, native time controls, complete ordered route, transition and fallback details, accessible labels, and honest confirmation messaging.
- [x] Extend focused unit tests for duration and exact-time requests, invalid and past deadlines, short windows, shorter alternatives, sound fallback, preapproved transitions, missing subsequent content, and snapshot immutability.
- [x] Add UI tests for choosing/reviewing duration and exact time, displaying fallback and alarm details, confirming the fixed plan, and accessibility identifiers and readable labels.
- [x] Update `README.md`, `docs/Project-Overview.md`, `docs/Nap-Planning-Domain.md`, `docs/Content-Catalog.md`, and `docs/Project-Implementation-Plan.md` with the actual review boundary and remaining runtime/device work. Keep the product brief and decision history unchanged because the accepted rules do not change.
- [x] Run targeted simulator tests, the full available simulator suite, `scripts/verify-repository.sh`, Swift formatting, and Debug/Release simulator builds; inspect the final diff and leave the physical iPhone and real alarms untouched.
- [x] Commit reviewable checkpoints and push `codex/nap-plan-review`; record the parent and final commits for moving only this branch's commits onto updated main after the content branch merges.

## Open questions

- None. The current bundled catalog supplies one prepared session and no accepted ambience; the UI will offer silence now and support injected available ambience and additional routes as the catalog grows.

## Results

- Parent commit: `8a23174de451e5c8f714af9ff71b1b7e7fbf7dc0` on `codex/local-content-catalog`. The content checkout remained clean and unchanged.
- Focused review checks: five unit and three UI tests passed on iOS 27.0. A fresh iOS 26.5 simulator completed the full suite: 142 passed, zero failed or skipped. Earlier full-suite attempts became inconclusive after simulator stalls; one subsequent run had a UI tap interrupted when an unrelated app took the simulator foreground. The final fresh-device result is the acceptance evidence.
- Repository gate: 31 passed. Strict Swift formatting lint, Foundation-only typecheck, Xcode project lint, Debug simulator compilation through tests, and Release simulator build passed. The physical iPhone and real alarms were not used.
- After the content branch merges, update `main` and cherry-pick only the ordered commits in `8a23174de451e5c8f714af9ff71b1b7e7fbf7dc0..codex/nap-plan-review` onto a fresh branch from that updated main. Resolve any task-plan or documentation conflicts against main's merged content state and rerun the validation gate before opening a review PR.
