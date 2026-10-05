# Quiet curiosity screen implementation map

The [approved atlas](../design/quiet-curiosity/screen-atlas.html) establishes layout and tone. This map describes the functional iPhone routes and states in the current Rest-first implementation. An atlas number is a visual reference, not a claim that its illustrative content, timing, or every control exists. Actual choices come from the bundled catalog, verified audio, plan, history, and alarm state. The first 24 entries often share one stateful view rather than separate screens.

**Everyday route:** Rest tab → choose duration, sound, and wake alarm inline → Start resting. **Plan a narrated rest** opens the separate prepared-session → review → confirm → start route. History is the other tab. Settings opens from Rest; its content pages are for browsing before rest. No page starts narration simply by opening it.

| Atlas | Reachable route or state | Current implementation and boundary |
| --- | --- | --- |
| 01 `screen-welcome` | First-launch welcome cover; dismiss to Rest. | `FeasibilityConsoleView.swift` (`welcomeScreen`); informational introduction. |
| 02 `screen-home` | Rest tab, idle choices or current rest state. | `FeasibilityConsoleView.swift` → `NapPlanReviewView.swift`; inline timer choices and one Start action; a secondary narration path. |
| 03 `screen-choose` | Rest → Plan a narrated rest → Change session sheet. | `RestContentViews.swift` (`RestSessionPickerView`); the two currently prepared sessions only, with validated saved-place or beginning selection. |
| 04 `screen-session` | Narrated choices → About this session, or picker → About this session. | `RestContentViews.swift` (`RestSessionDetailView`); catalog summary, estimate, saved point, availability, and explicit selection. |
| 05 `screen-time` | Narrated choices → More options sheet. | `RestSetupSheets.swift` (`RestTimeSheet`); native hours/minutes wheels or exact wake time. Cancel/dismiss keeps prior choices; Apply updates the unreviewed draft. |
| 06 `screen-sound` | Narrated choices → After narration sheet. | `RestSetupSheets.swift` (`RestSoundSheet`); Silence or verified Gentle rain. Cancel/dismiss keeps prior choice. |
| 07 `screen-review` | Narrated choices → Review nap plan. | `NapPlanReviewView.swift` (`reviewContent`); actual ordered route, deadline, rest sound, and alarm before confirmation. |
| 08 `screen-permission` | Timer Start resting or confirmed narrated Start resting with undetermined AlarmKit access. | Timers request system permission inline; narrated plans use `alarmAccessContent` then the system permission request; alarm must be scheduled and verified before playback. |
| 09 `screen-ready` | Narrated review → Confirm this plan. | `NapPlanReviewView.swift` (`confirmedContent`); Start resting remains a separate action. |
| 10 `screen-waiting` | Narrated plan before approved audio or visible silence-only rest starts. Timers have no scheduled waiting period. | `NapPlanReviewView.swift` (`runContent`), driven by `NapRunController`; keep the app foregrounded until that state advances. |
| 11 `screen-playing` | Active narration. | `NapPlanReviewView.swift` (`runContent`); prominent remaining-time countdown after admission, fixed deadline and actual playback status. |
| 12 `screen-paused` | Pause or audio interruption during a run. | `NapPlanReviewView.swift` (`runContent`); fixed rest countdown continues, playback pause/interruption is separate, and explicit resume is available when allowed. |
| 13 `screen-quiet` | Planned quiet or rain after narration, or silence-only rest. | `NapPlanReviewView.swift` (`runContent`); prominent remaining-time countdown after admission, fixed deadline, no attention-demanding prompt. |
| 14 `screen-finished` | Run reaches its deadline. | `NapPlanReviewView.swift` (`runContent`); Rest time ended confirmation; completed/partial narration is based on playback evidence. |
| 15 `screen-stopped` | Listener stops playback. | `NapPlanReviewView.swift` (`runContent`); any separately scheduled wake alarm remains active until explicitly cancelled. |
| 16 `screen-fallback` | Gentle rain unavailable before planning or during review. | `RestSetupSheets.swift` and `NapPlanReviewView.swift`; show Silence as the available or reviewed fallback. |
| 17 `screen-history` | History tab. | `ListeningHistoryView.swift`; Continue, valid Resume, and Replay open a fresh review. |
| 18 `screen-saved-place` | History entry whose checkpoint cannot resume against current content/audio. | `ListeningHistoryView.swift`, also reflected in `RestContentViews.swift`; record remains visible and current audio may be chosen from the beginning. |
| 19 `screen-alarm-failure` | Alarm-requested start fails permission or scheduling. | `NapPlanReviewView.swift` (`blockedStartContent` for narration, inline error or tracked-alarm recovery for timers); playback has not started; Settings/retry/change-plan actions are explicit. |
| 20 `screen-existing-alarm` | Rest reopened with a tracked wake alarm. | `NapPlanReviewView.swift` (`existingAlarmPage`, `trackedAlarmContent`); cancel the old alarm before another plan. |
| 21 `screen-short-plan` | Reviewed route contains no narration that fits. | `NapPlanReviewView.swift` (`reviewContent`); the actual selected rain or silence runs to the fixed deadline after confirmation and Start. |
| 22 `screen-rain-fallback` | Rain fails during active rest. | `NapPlanReviewView.swift` (`runContent`); visible silent rest, unchanged deadline and wake alarm. |
| 23 `screen-recovered` | Rest reopened with a verified checkpoint as the latest saved entry. | `NapPlanReviewView.swift` (`checkpointRecovery`); no autoplay or inferred completion. |
| 24 `screen-expired` | Confirmed plan has a stale approved start. | `NapPlanReviewView.swift` (`blockedStartContent`); refresh choices and review again. |
| 25 `screen-journeys` | Rest → Settings → Journeys and sessions. | `FeasibilityConsoleView.swift` → `RestContentViews.swift` (`RestLibraryView`); one real journey, **How a Car Works**, containing two prepared sessions. No illustrated extra journeys. |
| 26 `screen-journey` | Journey library → View journey. | `RestContentViews.swift` (`journeyDetail`); actual ordered sessions and completion/partial/next state from history. Planning opens a fresh review. |
| 27 `screen-branches` | No route in the current catalog. | `PreparedCatalog.json` has no next-journey destinations. `NapPlanReviewView.swift` shows transition approval only when a future validated catalog supplies real destinations; no branch choice interrupts playback. |
| 28 `screen-sources` | Session detail → Notes and sources, including from a journey detail. | `RestContentViews.swift` (`RestSessionNotesView`); actual summary, narration paragraphs, paragraph source IDs, publisher/title, and live source links from bundled metadata. These notes are read while awake, not spoken. |
| 29 `screen-preferences` | Rest → Settings → Session detail. | `RestPreparationViews.swift` (`CurrentDetailView`); informational **Enthusiast** page. There is only one prepared detail variant, so there is no detail picker or saved choice. |
| 30 `screen-downloads` | Rest → Settings → Offline library. | `RestPreparationViews.swift` (`BundledAudioView`); rechecks packaged narration hashes and rain availability and reports the local inventory. No download, deletion, or storage management. |
| 31 `screen-voices` | Rest → Settings → Narration voice. | `RestPreparationViews.swift` (`NarrationVoiceView`) and `NarrationPreviewController.swift`; explicit 12-second George sample from verified bundled audio. Preview is blocked during an active rest or Feasibility Lab audio, stops on exit, and writes no listening history or alarm. George is the sole prepared voice; no voice selector. |
| 32 `screen-settings` | Rest → Settings button. | `FeasibilityConsoleView.swift`; Rest defaults, prepared-content pages, app information, and Advanced. `RestDefaultsView` in `RestPreparationViews.swift` saves duration, available sound, and wake-alarm defaults for the **next unreviewed** plan only. |
| 33 `screen-lab` | Rest → Settings → Advanced → Feasibility Lab. | `FeasibilityConsoleView.swift`; experimental audio/alarm controls remain outside the ordinary Rest path. |

The two prepared sessions are **Turning Fuel Into Motion** and **Air, Fuel, and Spark**, both at Enthusiast detail with the prepared George `0.86` narration. The offline inventory reports what the installed bundle can verify; it does not repair missing assets. Additional journey sessions and branches, alternate voices/detail recordings, arbitrary topics, and download management require real prepared content and separate validation before controls can be enabled.

This route map does not change the existing acceptance record: simulator and focused target-iPhone checks cover portions of audio, rain, alarm, and history behavior; complete locked-control, headphone, and extended listening-comfort observations are still pending. See [Project overview](Project-Overview.md) and the [device test guide](Feasibility-Spike.md).

Settings summaries, Rest defaults, and a fresh plan use the same normalized sound preference and verified availability. If saved rain is unavailable, the displayed effective choice is Silence; the stored preference is retained for an installation where it validates again.

The offline inventory verifies packaged audio on a background task. A quiet checking message leaves navigation responsive, Recheck is unavailable until the current scan completes, and leaving the page cancels the request so its result cannot overwrite a later visit.

George preview preparation also verifies its source on a background task before activating audio. Cancel preview, leaving the page, losing eligibility, or a lifecycle interruption invalidates pending preparation; only the current eligible foreground request may begin the bounded sample.

The system-hosted remaining-rest card uses `RestActivityCoordinator` and `RestCountdownActivity`. It appears only after admitted rest/audio begins, counts toward the unchanged deadline through pauses, and keeps a stopped-playback card only for a matching verified future wake alarm. It is separate from the AlarmKit snooze card and does not expose listening history.
