# Plan

Resolve the six confirmed findings in the September 30 accessibility review while preserving Quiet curiosity and the existing playback, alarm, and history contracts. Verify the affected controls and largest-text layouts, save the feature branch, and install the signed update on the connected iPhone.

## Scope
- In: adaptive duration presets; readable stacked timing and metadata at accessibility text sizes; contrasting error text; contextual session/journey/history action labels; section heading traits; complete sound descriptions; focused regressions and simulator screenshots; durable design and resolution documentation; commit/push on `codex/app-icon`; in-place install and launch on the connected iPhone 18 Pro Max.
- Out: redesign, new content or capabilities, changes to timing/alarm/history behavior, speculative fixes for the audit's separate verification risks, enabling VoiceOver or scheduling alarms on the user's phone, PR/merge/public release. Raw generated audit exports remain local in accordance with repository guidance.

## Action items
[x] Confirm affected views, existing UI selectors, signing/device path, and guidance in `docs/Design-Language.md`, the local accessibility report, and `docs/Feasibility-Spike.md`.
[x] Adapt shared duration choices and reviewed/confirmed timing rows to the largest text size without shrinking text or changing plan values.
[x] Add readable semantic error colors and fix shared section headings and sound descriptions.
[x] Give repeated session, journey, and history controls distinct accessible names and entry headings; coordinate disjoint source ownership with a bounded builder.
[x] Add focused UI regressions for AX5 preset readability, complete review/ready timing, labels and selection state, review heading placement, and add a contrast regression using the resolved colors; retain current flow assertions.
[ ] Run focused tests, relevant broader UI tests, repository/format checks, and signed device build; inspect compact-phone daylight/evening AX5 screenshots and review the final changes for Apple-platform regressions.
[ ] Update the design guide, a tracked accessibility resolution record, the local audit status, and device verification notes with evidence and remaining manual checks; checkpoint coherent changes.
[ ] Install and launch the verified signed app on the connected iPhone without removing its data, then finish the save-branch commit/push and report installation and validation results.

## Open questions
- None. The connected iPhone 18 Pro Max is the installation target. Use the existing signing configuration and app identifier; keep real-device assistive-technology and alarm acceptance limitations explicit.
