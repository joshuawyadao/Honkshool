# Quiet curiosity: Honkshool design language

## Status and authority

**Approved 2026-09-30.** This is the default visual and interaction language for every current and future Honkshool screen unless the owner explicitly changes it. The owner approved the [33-screen design atlas](../design/quiet-curiosity/screen-atlas.html), its Rest-first organization, palette, typography, shape, spacing, and restrained sleeping-goose motif. The atlas is a design reference, not a statement that every pictured feature ships. Product and platform behavior remain governed by the [product brief](Product-Brief.md), [nap-planning domain](Nap-Planning-Domain.md), and [decision log](Decision-Log.md).

The guiding feeling is **open the app, choose a few things, put the phone down, and rest**. Honkshool helps the listener settle in; factual exposure is secondary. A sleepy person should understand the main action at a glance, with no visual pressure to browse, track achievement, or keep looking at the screen.

## Foundations

### Color

Use semantic colors that adapt to the system appearance. The design atlas's reference values are:

| Role | Daylight | Evening | Use |
| --- | --- | --- | --- |
| Screen background | `#F6F2EA` | `#091A35` | Quiet full-screen canvas |
| Card | `#FFFDFA` | `#142944` | Grouped choices and saved places |
| Inset well | `#EAE5DC` | `#203752` | Secondary choices or information |
| Primary text | `#172B49` | `#F5F0E7` | Titles and essential state |
| Secondary text | `#53637A` | `#B4C1D4` | Explanations and metadata |
| Divider | `#D7D8D5` | `#344B66` | Sparse separation within lists |
| Quiet notice | `#E3EAF0` | `#203B58` | Recoverable status and guidance |
| Primary action | `#E1B066` | `#E1B066` | One clear next action |
| Text on primary action | `#152844` | `#152844` | Readable button label |

The app icon's midnight navy `#0B2550` is the identity anchor. Amber is an action cue, not a decorative glow. Use system semantic colors for errors, warnings, selection, and accessibility states; test contrast in both appearances. Do not use gradients, saturated status color, bright badges, or moving color as the default rest surface.

### Type, space, and shape

- Use SF Rounded for short page titles and card titles; use SF Pro/system body text for longer reading and controls. Keep weights restrained, typically regular or medium.
- Support Dynamic Type with native text styles and layouts that grow vertically. Do not encode critical meaning only in tiny uppercase labels or iconography.
- Use an 8-point spacing rhythm. Give the main title and primary action generous breathing room; prefer a small number of calm groups to a dense dashboard.
- Use 16–24-point corners for controls, wells, and cards. The icon can have its own artwork shape; let iOS mask the installed app icon.
- Make interactive targets at least 44 by 44 points, preserve VoiceOver order, use native controls where appropriate, and honor Reduce Motion. Test light/dark, larger text, narrow phones, and long localized labels.

### Goose signature

The approved [thought-bubble sleeping goose](App-Icon.md) is an occasional, static signature. It may welcome the listener, mark a settled state, or anchor the Rest home. Two small trailing thought dots and a soft feather-like curve may echo it sparingly. These details should never pulse, loop, or compete with the deadline or the action. Do not add floating Zs, twinkling stars, streaks, confetti, waveforms, or achievement effects. Keep the icon artwork itself intact rather than approximating it with an unrelated emoji or system symbol.

## Navigation and component patterns

**Rest first.** The everyday root is Rest with History close at hand. The default path is Continue or choose a session → choose a rest window and sound → review the exact plan → confirm → Start resting. Keep the experimental Feasibility Lab under Settings → Advanced. As the catalog grows, Journeys may become a meaningful browsing destination, but the current two-session catalog should not turn the bedtime entry into a library to explore.

| Pattern | Implementation rule |
| --- | --- |
| Rest home | One prominent next action, saved place or current session, and short choices. An active wake alarm takes precedence over making another plan. |
| Cards and inset wells | Cards group one decision or one record; wells explain a secondary state. Avoid several equally weighted cards fighting for attention. |
| Primary and secondary actions | Use one amber primary action per decision point. Secondary actions are quiet filled or text controls. Destructive or alarm-changing actions name their consequence. |
| Time and deadline | Show the local wake time clearly, with start, duration, and alarm state nearby. Use tabular numerals for times; include date when crossing midnight could confuse. The reviewed deadline remains fixed. |
| Plan review | Show the ordered route, narration estimate, any remainder as rain or silence, post-narration behavior, and alarm before explicit confirmation. If the route changes or a start expires, require another review. |
| Rest screen | Minimize content to current state, fixed end time, alarm state, and pause/resume/Stop when applicable. No live waveform, progress pressure, changing prompts, or branch choice. The phone can be put down. |
| History | Use “Played,” “Partially played,” and “Last verified checkpoint.” Continue, Resume, and Replay lead to a fresh plan review; reopening does not play audio. |
| Errors and recovery | State exactly what happened, whether audio and the alarm are active, and the one next step. Remain calm and truthful: a failed rain loop becomes visible silence; an unavailable requested alarm blocks playback. |
| Empty, permission, and loading states | Keep them as composed as the normal flow. Explain why a permission matters at the time it is needed. Never present a spinner or busy animation as bedtime decoration. |
| Settings and advanced tools | Use short grouped native rows. Keep experimental diagnostics available to testers without placing them in the routine nap path. |

Use native sheets, pickers, VoiceOver semantics, focus, and system alarm surfaces where the platform owns the interaction. The atlas illustrates intent and hierarchy, not pixel-perfect replacements for system UI. On the resting screen, status changes must remain readable without asking the listener to respond.

## Writing and motion

Write in a warm, direct voice: “Get comfortable,” “Rest until 3:21 PM,” “Your place is saved,” and “Played.” State a problem plainly: “Your wake alarm isn’t set. Playback hasn’t started.” Avoid exclamation marks, streaks, scores, learning claims, promises of sleep quality, and commands that suggest the listener must stay engaged. Content summaries and citations are browsed while awake; citations are not read aloud.

Prefer no motion. If a transition helps orientation, keep it short and respect Reduce Motion. No ambient looping animation, pulsing mascot, flashing highlight, auto-advancing card, surprise sound, or autoplay after reopening. No attention-demanding interaction after playback starts; the only intentional interruption is an explicitly requested system wake alarm.

## Atlas coverage and capability boundary

The [approved atlas](../design/quiet-curiosity/screen-atlas.html) groups its numbered examples as follows. The first 24 depict the core flow and important states, not 24 independent features; actual copy and timing come from runtime state. The later eight are **future concepts**, and #33 is an existing developer utility in a quieter proposed location.

| Atlas screens | Scope and contract |
| --- | --- |
| 1–4 Welcome, Rest home, Choose, Session detail | Rest-first shell and available two-session catalog. Only prepared local sessions may be selectable. Session facts and sources come from bundled metadata. |
| 5–9 Time, Sound, Review, Alarm permission, Ready | Native timing choices; Silence default, verified Gentle rain when available; fixed full-route review; alarm authorization/scheduling before an alarm-requested start; separate Confirm and Start. |
| 10–16 Waiting, Playing, Paused, Quiet, Finished, Stopped, Rain unavailable | Keep foreground until approved audio starts or silence-only rest begins at its approved start. Deadline stays fixed; Stop leaves any wake alarm active; narration history follows actual playback evidence. |
| 17–24 History, invalid saved place, alarm denial, existing alarm, short quiet plan, rain failure, unexpected exit, expired start | Recovery shows evidence and an explicit next step. Resume requires valid revision/render identity and fresh review; no autoplay or invented completion. Existing alarms must be handled before another plan. |
| 25–27 Journey library, journey detail, branch choice | Future expanded 5–8-session journeys and branch navigation. The current catalog has only two prepared sessions; these screens must not advertise unprepared sessions as playable. |
| 28 Session notes and sources | Source-linked metadata exists now; a richer browsing presentation is illustrated for future exploration. It can be surfaced for current prepared content without adding narration or network access. |
| 29–31 Detail for next time, offline library, voice preview | Future capabilities. First prototype has Enthusiast detail, bundled/offline audio, and George `0.86`; alternate detail levels, download management, and voice selection need prepared assets and measured timing before controls become functional. |
| 32 Quiet settings | Proposed routine settings surface; it must stay short and retain the Rest-first path. Only actual preferences may be exposed. |
| 33 Feasibility Lab | Existing experimental controls, moved away from routine navigation but preserved for device testing. |

The atlas is a reference for style and hierarchy, not a mandate to ship speculative features during the current UI pass. Map each screen to an implemented capability before enabling its controls. Do not imply accounts, cloud sync, live research, arbitrary topic generation, downloads, alternative voices, or extra content currently exist.

## Implementation and review checklist

The shared palette lives in `Honkshool/Shared/RestStyle.swift` and is used by the app and its alarm extension. Native components live in `Honkshool/App/RestDesign.swift`: `RestCard`, `RestHeading`, `RestButtonStyle`, `GooseMark`, `ThoughtDots`, and `restScreen()`. Reuse these for new screens.

Build shared semantic colors, typography, spacing, card, button, heading, and goose components before styling individual views. Keep domain and playback state as the source of truth; visual components only present it. For each new or changed screen, check the following:

1. Does the first glance answer what happens next and when rest ends?
2. Can the listener choose, review, and start with only a few clear actions?
3. Are audio, alarm, saved-place, and permission states represented truthfully?
4. Does the layout remain calm in daylight, evening, larger text, VoiceOver, and Reduce Motion?
5. Does the screen avoid drawing attention during active rest?
6. Does every enabled control correspond to an implemented capability?

Changes to the app's visual direction should update this guide and relevant tokens/components together. New screens should inherit Quiet curiosity by default. A deliberate owner-requested departure should be recorded in the [decision log](Decision-Log.md).
