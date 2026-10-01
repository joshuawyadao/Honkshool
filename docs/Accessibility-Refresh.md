# Accessibility refresh — September 30, 2026

This record follows the owner's request to resolve the six confirmed findings in the September 30 UI accessibility audit and update the connected iPhone. It preserves the approved Quiet curiosity design, including native Dynamic Type, the Rest-first flow, and static decorative artwork. Raw audit hierarchies, recordings, and device identifiers remain local.

## Findings and changes

| Audit finding | Resolution | Evidence and regression coverage |
| --- | --- | --- |
| **A11Y01 · P2** — preset durations wrapped individual digits at the largest text size on a compact phone | `RestDurationChoices` widens adaptive cells at accessibility sizes. Both Rest and the Time sheet use it. The full minute label, selected trait, and native font scaling remain. | The compact AX5 UI test measures button height against a single scaled body-text line, selects presets in both locations, and checks that the applied selection survives dismissal. Screenshots were inspected separately in daylight and evening. |
| **A11Y02 · P2** — review/Ready metadata used narrow horizontal columns, fragmenting labels and times | `RestLabeledContentStyle` stacks labels and values at accessibility sizes. `RestTimingRow` gives date and time separate visual lines and supplies the full combined spoken label. Standard-size rows retain native layout. | The AX5 flow checks full labels and equality of the start/deadline through review, confirmation, and a fixture-backed waiting run; it reaches the pinned Start action and Stop. Existing plan tests cover route, sound, permission, and timing guards. |
| **A11Y03 · P2** — system red did not provide sufficient contrast for small error text on the custom surfaces | `RestStyle.error` now resolves to `#A53C34` in daylight and `#F2AAA0` in evening. Error wording and symbols continue to carry meaning independently of color. | `RestAccessibilityTests` resolves UIKit colors under light/dark and normal/high contrast traits, requiring at least 4.5:1 on page, card, well, and quiet-notice backgrounds. A hosted production History view with isolated failing storage was rendered and visually inspected in both appearances. |
| **A11Y04 · P2** — repeated Choose/About/Continue/Resume/Replay/View journey actions lacked context | Accessible names retain the visible action as a prefix and add the session/journey title. History actions include the dated attempt or the latest played date when one exists. Navigation, disabled guards, and stored history are unchanged. | The UI test checks two sessions' distinct Choose/About names and the seeded History Continue/Resume/Replay names and dates. The Library flow checks the contextual journey name and navigation through its stable identifier. |
| **A11Y05 · P3** — important sections were missing heading traits | Shared `RestCard` titles and direct session, journey, and history record titles now have the header trait. Existing page headings retain theirs. Decorative artwork remains hidden. | Source review checks heading placement and unchanged content order. Actual spoken heading-rotor navigation remains an owner/device acceptance check. |
| **A11Y06 · P3** — sound button labels replaced their useful descriptions | Sound choices expose title plus description and retain the selected trait. Stable identifiers preserve existing choice tests. | The AX5 UI test checks both complete labels, Silence's initial selection, switching to Gentle rain, and applying the choice. Existing tests cover missing rain and Cancel. |

## Resolved color measurements

Ratios use the resolved opaque sRGB colors and relative luminance. Normal and Increase Contrast produce the same intentional semantic pair.

| Error text on | Daylight | Evening |
| --- | ---: | ---: |
| Page | 5.71:1 | 9.11:1 |
| Card | 6.28:1 | 7.71:1 |
| Inset well | 5.08:1 | 6.38:1 |
| Quiet notice | 5.25:1 | 6.04:1 |

## Verification record

The compact iPhone SE (3rd generation), iOS 26.5 run passed all three focused UI cases at the largest accessibility text size or standard size as appropriate. The two AX5 layout/flow cases also passed in evening appearance. The resolved-color and hosted History error tests passed separately; the actual error view was visually inspected in both appearances. All 40 public-repository checks and strict formatting passed. The signed Release build and signature verification passed. App source `06e521b` was installed in place and launched normally on the connected iPhone 18 Pro Max / iOS 27.0 using the existing app identifier and signing setup. The broader iPhone 17 Pro / iOS 26.5 run passed **243 tests with zero failures**; six opt-in physical audio/alarm tests were intentionally skipped. This run selected all unit tests and the Functional Pages, Rest Shell, Listening History, and Nap Plan Review UI suites. The final hosted-error renderer was separately rerun after its correction (2/2 accessibility unit tests passed).

The first focused run caught a newline leaking into the timing announcement; applying the complete spoken label at the row level fixed it. Intermediate test failures came from an unloaded-grid frame query and overstrict whole-viewport scrolling in the new test helper, plus a simulator Busy launch error. The helper now scrolls within content until the actual control is hittable, and the simulator launch recovered after restart. A first offscreen error capture produced an empty background; the final test uses a hosted window and rejects blank captures. None of those intermediate runs is counted as acceptance evidence.

Xcode reported internal priority-inversion warnings during `SpikeModelsTests`; no measured app UI hang or test failure was established by those diagnostics. They are recorded separately from these six accessibility findings.

The Apple-platform source review found no timing, alarm, history, or navigation regression. No domain, persistence, playback, permission, or scheduling implementation was changed.

## Remaining acceptance

The fixes do not establish spoken VoiceOver quality merely because accessibility labels exist. On the updated iPhone, check heading-rotor movement, announcement order, and the dated History actions with VoiceOver; also try Voice Control or Switch Control if used. These settings are not enabled remotely as part of installation. Physical alarm loudness, locked-screen behavior, listening comfort, and prior audio acceptance items remain separate in the [feasibility record](Feasibility-Spike.md).

The audit's additional observations about clipped scanner bounds, More options hit-region reporting, actual Stepper announcements, and prototype-only screens were not confirmed defects. They are not silently promoted to failures or claimed as fixed by these six changes. At AX5 on a compact phone, content necessarily scrolls; pinned actions and individual controls must remain reachable without reducing the selected font size.

## Continuing the design

Use the [design language](Design-Language.md) for new screens. Its shared heading, contextual-label, adaptive metadata, and semantic error rules now incorporate this audit. Apple references: [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), [LabeledContentStyle](https://developer.apple.com/documentation/swiftui/labeledcontentstyle), and [accessibilityLabel](https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(_:)-1d7jv).
