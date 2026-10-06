# Using Honkshool

[Documentation index](README.md) · [Install from source](Getting-Started.md) · [Troubleshooting](Troubleshooting.md)

This guide describes the current experimental build. Honkshool helps you rest with calm factual narration; a session marked **played** says nothing about whether you heard, learned, or retained it.

## Find the ordinary listening flow

The app opens on **Rest** after the first-launch welcome. **History** is the other tab, and **Settings** opens from Rest. Choose a duration, Silence or Gentle rain, and whether to use a wake alarm on the same screen, then tap **Start resting**.

The experimental **Feasibility Lab** is under **Settings → Advanced**. Its background-audio test and test alarm are separate diagnostic tools. Stop feasibility audio and cancel its test alarm before starting a Nap Plan. The app blocks overlapping use and explains what needs to stop.

## Start a nap timer

1. Choose a duration on **Rest**. Expand **Custom duration or wake time** for native hours-and-minutes wheels (1–180 whole minutes) or an exact ending time; these choices stay on the same screen.
2. Choose **Silence** or available **Gentle rain**, and set **Wake alarm** on or off.
3. Tap **Start resting**. If needed, iPhone asks for alarm permission. Once a requested alarm is verified, rain begins immediately, or the app shows silent rest. There is no separate review, confirmation page, or one-minute waiting period for a timer.

Saved Rest defaults apply. **Settings → Rest defaults → Rest sound** chooses Silence or Gentle rain for both timers and narrated plans. Timers use the sound as rest begins; narrated plans use it during any quiet time before or after narration. The duration begins after any alarm-permission prompt; brief alarm setup uses part of that window. The ending time then stays fixed. Setup longer than five seconds (three seconds for a one-minute timer) blocks a new start; a tracked alarm remains available to cancel. Keep the screen open until rest begins. If you leave during setup, return and explicitly start again after handling any tracked alarm. A timer contains no narration and creates no listening history.

## Plan a narrated rest

Tap **Plan a narrated rest** below the timer choices. Narrated sessions retain their full route review:

1. **Choose content.** The narrated flow suggests a prepared session in **How a Car Works**. Tap **Change session** to choose the first or second session. Starting with the first can include the second when the window allows. The reviewed route is the authority for what will actually play.
2. **Choose your rest window.** Pick a duration on Rest, or tap **More options** for hours-and-minutes wheels or an exact wake time. The window includes settling, narration, and any remaining rest; it is not a measure of time asleep. The selected window and narration estimates determine what fits.
3. **Choose the rest sound.** Tap **After narration** for **Silence** (the default) or **Gentle rain** when its bundled audio and provenance validate. If no complete narration fits, the plan can use only the selected rest sound. Honkshool does not speed up narration to squeeze it in.
4. **Choose the alarm.** Leave **Wake alarm** on if you want a system wake alarm at the fixed deadline, or turn it off. With it off, Honkshool schedules no wake alarm for that plan; set another alarm if you need one.
5. **Review.** Tap **Review nap plan** and check the planned start, fixed wake deadline, full narration route, sound, and alarm choice. Choose any shorter alternatives before review; the current bundled catalog is one ordered two-session journey and has no branch destination.
6. **Confirm and start.** Tap **Confirm this plan** or **Confirm quiet plan** when no narration fits, then **Start resting** before the approved start passes. The normal review lead time is about one minute; short exact-wake windows can allow less. If it expires, review the refreshed times and route again.

An alarm-enabled start first asks for alarm access if needed, schedules the alarm, and checks that its time matches the plan. Denied permission or failed verification blocks that start. You can explicitly choose an alarm-free plan instead. A previously tracked Nap Plan alarm must be cancelled before another plan can start.

## When can I lock the phone?

For a **nap timer**, wait until Gentle rain is playing or the silent-rest status appears, then lock the phone. Silence has no media playback or Lock Screen audio controls.

For a **narrated plan**, keep Honkshool in the foreground until the approved narration or rain begins. This includes any initial silent settling period before narration. Then you can lock the phone.

For a **silence-only plan with no narration**, wait for the visible rest-until-deadline state at the approved start. You can then lock the phone even though there is no audio to hear.

Leaving a narrated plan too early ends the pending run and requires a new review. An alarm already scheduled for it can remain active. If rain fails, a visible status explains the fallback to silence; if that happens before narration while the app is backgrounded, the run ends rather than relying on a later silent background start.

## Remaining time on the Lock Screen

After rest begins, the Rest page shows **Rest timer running** and a prominent **Time remaining** countdown. The fixed end time, selected sound, and wake-alarm status remain nearby. Pausing or interrupting playback keeps counting toward the same deadline and says that rest time continues. Waiting for playback admission does not claim a running timer; finished or expired time says **Rest time ended**. Stop removes the running countdown while preserving any separately scheduled wake alarm.

After rest begins, a separate Live Activity shows the remaining rest time, its fixed ending time, and the last reported playback and wake-alarm state. Labels such as **Rest sound started** and **Wake alarm was set** describe the app's last update, so the card does not prove that sound or the alarm is still active. It also works for silent rest and when the wake alarm is off. Pausing audio does not pause this countdown. Stopping playback leaves the card while the app verifies the matching future wake alarm. Canceling through iOS while Honkshool is inactive may leave the older card visible; reopening reconciles and removes it. Reopening never resumes audio.

Enable Live Activities for Honkshool in iPhone Settings if the countdown is unavailable. A disabled or failed card does not stop an admitted rest or change its wake alarm. Very long exact-time windows can exceed the system’s eight-hour Live Activity limit. At the deadline a stale card says **Rest window ended**; it does not prove that audio stopped or an alarm sounded while the app was suspended.

At the largest accessibility text settings, the Lock Screen card keeps compact text so its countdown and status remain visible. Open Rest for the full-size countdown. VoiceOver still reads the complete card text.

## Control audio and alarms

| Control | Effect |
| --- | --- |
| **Pause playback** | Pauses audio. The deadline and scheduled alarm do not move. |
| **Resume playback** | Explicitly resumes when allowed, within the remaining window. |
| **Stop playback** | Ends the run's audio. A narration attempt can be saved as partial. It leaves the wake alarm active. |
| **Cancel wake alarm** | Available after the run is inactive; cancels the separately tracked wake alarm. |
| **Cancel Nap Plan wake alarm** | Cancels the tracked plan alarm from **Settings → Advanced → Feasibility Lab**. Check the resulting status. |
| **Change your plan** or **Plan another rest** | Returns to choices for a fresh review; an old tracked alarm must still be cleared before starting. |

To end both listening and the wake alarm, **stop playback, cancel the alarm, and check the result**. Cancelling an alarm alone is not an audio Stop command. The feasibility console's separate **Cancel alarm** button belongs to its test alarm.

A system interruption or lost audio output can pause playback. Honkshool requires a manual resume rather than unexpectedly restarting. The app requests exclusive playback, so existing music or a podcast yields when its audio session activates. iOS owns the exact Lock Screen media/alarm presentation; current production rain controls and physical headphone-disconnection behavior still need direct observation.

An iOS media-service reset ends a run that has an initialized narration or rain player, including paused audio, and requires a new explicit start. An admitted silent timer, including rain that already fell back to silence, has no player to reset and continues to its fixed deadline. The separately scheduled wake alarm remains independent.

The planned deadline stays fixed even if you pause or start late. Playback never extends the window to finish a session. Cutoff depends on app execution, which iOS can delay while suspended; the independently scheduled system alarm is a separate path. Current verification and its limits are in the [feasibility guide](Feasibility-Spike.md).

## Continue a journey or revisit a session

Open the **History** tab. It shows locally saved narration attempts and journey progress. You can also view the current two-session journey under **Rest → Settings → Journeys and sessions**.

| Action | Meaning |
| --- | --- |
| **Continue listening** | Select the next incomplete session in the journey, using its latest valid partial position when available. |
| **Resume from…** | Start from an available verified position in a partial session. |
| **Replay from start** | Start that session from the beginning and keep earlier listening history. |

Every action opens a new Nap Plan review. Reopening the app never starts audio by itself. A session advances progress only when playback reaches its actual end; reaching the plan's deadline can leave it partial. Rain-only and silence-only plans create no narration progress.

Saved positions depend on the script revision and exact prepared audio. After a content update, an old position may no longer be usable; choose the current session from its beginning and review again. If loading or saving history fails, the app shows the problem; it does not replace a failed store with empty history or stop an active nap to hide the error. The newest progress may be unavailable until saving succeeds.

## Current limits

There are two prepared automotive sessions, no content downloads, and no public supported release. **Rest → Settings** includes defaults for the next timer or unreviewed narrated plan, session and journey browsing, source notes, a verified offline inventory, the current Enthusiast detail level, and an explicit 12-second George voice preview. The preview creates no history and is unavailable during active rest or Feasibility Lab audio. Additional journeys, branch destinations, voices, and detail variants remain future work. There is no in-app history delete or export control; see [Privacy and local data](Privacy.md).

Automated device tests are separate from listening acceptance. Relative rain/narration level, longer comfort, production rain Lock Screen controls, and real headphone disconnection remain direct observations to collect. The [trial guide](Ten-Nap-Trial.md) explains how to evaluate ordinary use without putting personal history in public reports.
