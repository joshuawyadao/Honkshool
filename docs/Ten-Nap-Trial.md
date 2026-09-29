# Ten-nap personal trial

Use Honkshool during approximately ten normal nap opportunities to decide whether it becomes your natural choice for calm audio. Count opportunities when you choose YouTube or something else too. No extra naps, full-session attentive listen, or timed technical test is required.

**Status:** the two-session implementation was merged in PR #10 as `19f4339`. This guide prepares the trial; no trial outcomes or deferred physical checks have been recorded here. This is a personal prototype, not a supported release.

## Prepare once, when ready

- Install an ordinary signed build containing the merged two-session journey on your iPhone. Follow [Local setup](Feasibility-Spike.md#local-setup), open the `Honkshool` scheme in Xcode, select the phone, and use Run. Use an ordinary launch with no UI-test launch arguments or test opt-in flags. Installation needs the phone; preparing this guide and log does not.
- Record the installed build's commit (`git rev-parse --short HEAD` in the checkout used to build), device model, and public iOS version in the private log. Record a new build context if you update during the trial. Do not record a serial number, device identifier, signing identity, or account details. Keep the app installed so its local history remains available.
- Open **Choose and review a Nap Plan**. Verify the picker offers **Turning Fuel Into Motion** and **Air, Fuel, and Spark**. **Silence** is always a choice; use **Gentle rain** if available and wanted. Use the Nap Plan flow for the trial; the separate feasibility console still contains diagnostic controls.
- If a previous Honkshool alarm is still tracked, cancel it explicitly before starting another plan. A diagnostic-console alarm and a Nap Plan alarm are separate; follow the visible message for the tracked alarm. Leave alarm preference up to the needs of each nap.
- Create the private copy below. The tracked template must remain blank.

From the repository root:

```sh
mkdir -p local-data/ten-nap-trial
if [ ! -e local-data/ten-nap-trial/Trial-Log.md ]; then
  cp -n docs/Ten-Nap-Trial-Log.template.md local-data/ten-nap-trial/Trial-Log.md
fi
git check-ignore -v local-data/ten-nap-trial/Trial-Log.md
```

The existence check reuses an existing log, and `cp -n` refuses to overwrite it. Confirm the last command identifies the `/local-data/` ignore rule before entering observations. Keep completed notes in that ignored directory or another private local location; do not force-add them, attach them to GitHub, or paste them into a public issue. Git ignore prevents ordinary Git inclusion; it is not encryption or a cloud-backup setting. No analytics or automatic upload is added.

## Use it normally

1. Choose Honkshool only when you want it. If you choose an alternative, record the choice and an optional reason; leave the Honkshool-specific fields not applicable.
2. For Honkshool, choose your rest window, content, sound, and **Request a wake alarm** preference. Tap **Review Nap Plan**, check the route and fixed wake deadline, then **Confirm reviewed plan** and **Start resting** before the planned start. If the plan expires, review its refreshed route and deadline again. A requested alarm must show successful scheduling before the run can begin; a schedule/status message alone does not prove an audible alarm occurred.
3. Keep the app open until approved narration or rain actually begins, then lock it if desired. For a reviewed **silence-only plan with no narration**, wait until the planned start has arrived and the status says **Rest continues in silence until the fixed deadline**; you can then lock the phone even though no audio will begin. **Resting in silence until narration begins** is a different, earlier state: keep the app open while waiting for that narration. If the run ends before playback, follow its fresh-review instruction. Longer windows may include both sessions; short windows may contain rain or silence only. The review is the source of truth for the approved route.
4. Rest normally. Use pause, resume, or **Stop playback** whenever needed. Playback Stop leaves a requested wake alarm active; dismiss or explicitly cancel that alarm when no longer wanted.
5. Afterwards, spend roughly 30 seconds on one log row, including whether the reviewed narration/rest mix suited your chosen window. A brief note or **unobserved** is enough. There is no need to stay awake to watch transitions. Use **Listening history and Continue** when you naturally return; Resume and Replay open a fresh review and do not start automatically.

Rain-only playback creates no narration history. A session counts as completed only when its playback reaches the end; that does not establish that you were awake, slept, learned, or retained anything. Do not clear history to make the trial look complete.

## Deferred observations, when convenient

The private template has a small observation checklist. During ordinary use, note full-session comfort, narration-to-rain level/loop comfort, locked playback and controls, and a real headphone-disconnection event during playback if one is deliberately checked or actually occurs. Disconnecting headphones should pause playback without sending sound to the speaker; reconnecting requires explicit resume. Use the [production rain guide](Feasibility-Spike.md#production-gentle-rain-acceptance-on-the-target-iphone) for details if needed.

Record only what you directly hear or see. A short comfortable excerpt does not establish whole-session comfort. Record alarm delivery and audio cutoff independently: hearing one does not establish the other. If asleep or unsure whether either occurred, mark that specific outcome **unobserved**; automated tests and app history do not fill that gap. Leaving any item pending is valid and must remain visible at closeout.

## Review after approximately ten opportunities

Use the template's summary to count choices across all recorded opportunities and separate observed outcomes from unknowns. For alarms, count requested, directly observed as expected, failed, and unobserved separately. Note any build changes so a later fix does not rewrite earlier failures.

Use these practical decision criteria; they are a guide for the owner's decision, not a statistical reliability certification:

| Decision | Evidence to look for | Next step |
| --- | --- | --- |
| Continue | Honkshool was naturally chosen for most opportunities (for example, at least 6 of 10), observed listening was generally calm, plan/recovery behavior was usable, and no observed blocking defect remains unresolved. | Choose the smallest improvement supported by repeated notes. Keep any unobserved physical checks explicitly pending. |
| Pivot | The basic flow works, but you often prefer an alternative because of setup friction, voice/rain comfort, content repetition, or recovery difficulty. | Pick one recurring cause for a focused change, then reassess during normal use. |
| Stop | You do not want to keep using it and the likely improvements do not justify the effort. | Record that decision; no catalog expansion is required. |
| Inconclusive | Too few opportunities or observations exist, or an important behavior such as a requested alarm remains unobserved. | State the missing evidence and decide whether to gather it later. Do not convert unknowns into passes. |

An observed wrong/missed requested alarm, unintended speaker playback after disconnection, audio continuing past an observed fixed deadline, or lost/incorrect progress warrants a focused defect investigation before repeating the affected path. Clear any unwanted tracked alarm. A later fix gets a new build context and a narrow recheck; it does not erase the original result. Voice preferences and routine setup friction can be prioritized at closeout unless they make continued use undesirable.

The eventual public-safe report should contain aggregate counts, a brief description of reproducible defects, the unresolved observation list, and an explicit continue/pivot/stop/inconclusive decision. Manually remove personal schedules, exact timestamps, identifiers, screenshots, and raw listening history before choosing to publish a summary. This preparation PR includes no completed log or report. The trial and report remain unchecked in the [roadmap](Project-Implementation-Plan.md#phase-5-ten-nap-validation).
