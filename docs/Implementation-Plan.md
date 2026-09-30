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
[x] Run repository checks, targeted iOS tests, the complete iOS suite, Release build, and simulator visual checks in light/dark and larger text; review timing/alarm/privacy contracts and repair findings.
[x] Update status and usage documentation, record validation, commit coherent checkpoints, and push the completed branch.

## Open questions
- None. The approved overview establishes the design direction; implementation of future content capabilities remains phased as already labeled in the overview.

## Validation results
- Repository checks: all 40 passed; Markdown links and diff whitespace checks passed.
- Debug build-for-testing and the final Release simulator build passed.
- Complete iOS 26.5 / iPhone 17 Pro run: 239 passed, two sound-picker UI failures, six intentional physical-device skips. The UI helper had treated a picker partly behind the pinned review action as tappable; it now requires controls to be fully above that action.
- Final dark-appearance follow-up on the completed sources reran every Nap Plan and Rest shell UI case plus authorization and playback/Stop Lab cases: 21 passed, zero failed, one intentional physical-only skip. Both failed sound cases passed. Across the full and follow-up runs, all 241 simulator cases have passing evidence; the six device-only cases remain skipped.
- New `RestShellUITests` covers welcome persistence, navigation, service lifetime across tabs, and larger text. Existing Nap Plan, history, and Lab UI tests retain their safety assertions; the controller test verifies the displayed plan survives Stop and clears on reset.
- Native simulator screenshots were inspected in daylight and evening, including larger accessibility text. The Lab button/text contrast issue found during inspection was fixed with shared components/tokens and included in the final follow-up. Checked body-on-background, secondary-on-card, and primary-action pairs measured at least 6:1 contrast.
- Apple-platform review findings about saved-place wording and consumed History confirmations were repaired and rechecked. No deadline, alarm ownership, completion-evidence, or privacy contract change was required.
- No new physical-device audio, alarm, headphone, or comfort acceptance is claimed. Future expanded journeys, detail/voice variants, and download management remain specifications, not enabled features.
- Local checkpoints: resolved plan `c0d120c`, coherent implementation `6d273ef`; final verification and repairs are saved with this plan on `codex/app-icon`.
