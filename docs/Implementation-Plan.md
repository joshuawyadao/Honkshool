# Plan

Establish the approved Quiet curiosity / Rest first previews as Honkshool’s durable design language, then apply them to the functional iOS app. Reuse the existing planning, playback, alarm, and history contracts while making setup, review, rest, and return calm and coherent.

## Scope
- In: canonical design guide and contributor guidance; reusable adaptive SwiftUI tokens/components; Rest/History navigation, welcome and settings; session details and existing bundled sources; styled setup, full review, confirmation, active/rest/recovery, history, and advanced lab; accessibility and functional regression verification; commit and push on `codex/app-icon`.
- Out: new recordings, unprepared journeys, alternate voices/detail variants, downloads/backend/accounts, changes to deadline/alarm/history evidence rules, public release, PR creation or merge. Future atlas concepts remain documented specifications until their underlying capabilities exist.

## Action items
[x] Record the approved palette, typography, spacing, motif, components, 33-screen mapping, accessibility rules, and future-feature boundaries in `docs/Design-Language.md`; link it from project/product/roadmap docs and add persistent contributor guidance.
[x] Add reusable native SwiftUI design primitives and the approved goose image for in-app use, preserving the app icon.
[x] Introduce a Rest/History shell, one-time quiet welcome, and Settings → Feasibility Lab with one shared lifetime for playback, alarms, and history.
[x] Apply the design to session selection/detail, duration and sound choices, complete immutable plan review, explicit confirmation/start, active/paused/quiet/ended states, and existing-alarm/error recovery.
[x] Restyle history and checkpoint/unavailable states, preserving verified timestamps, completion evidence, and fresh Resume/Replay reviews.
[x] Update navigation/UI regression tests and add meaningful coverage for the new shell, welcome, session details, and cross-tab active-run/alarm lifetime; retain existing safety assertions.
[ ] Run repository checks, targeted iOS tests, the complete iOS suite, Release build, and simulator visual checks in light/dark and larger text; review timing/alarm/privacy contracts and repair findings.
[ ] Update status and usage documentation, record validation, commit coherent checkpoints, and push the completed branch.

## Open questions
- None. The approved overview establishes the design direction; implementation of future content capabilities remains phased as already labeled in the overview.

## Validation progress
- Debug build-for-testing and Release simulator build passed; repository checks passed (40 cases).
- Targeted contract and UI checks found four accessibility/navigation failures; repairs passed all six follow-up cases, including consumed-confirmation protection and larger text.
- Apple-platform review findings were repaired and rechecked. Full-suite and dark-appearance validation are in progress.
