# Using Honkshool

[Documentation index](README.md) · [Install from source](Getting-Started.md) · [Troubleshooting](Troubleshooting.md)

This guide describes the current experimental build. Honkshool helps you rest with calm factual narration; a session marked **played** says nothing about whether you heard, learned, or retained it.

## Find the ordinary listening flow

The app opens on **Feasibility Lab**. Scroll to **Nap Plan** and tap **Choose and review a Nap Plan**. The **Listening history and Continue** link opens saved narration history.

The console's background-audio test and test alarm are separate diagnostic tools. Stop feasibility audio and cancel its test alarm before starting a Nap Plan. The app blocks overlapping use and explains what needs to stop.

## Choose, review, and start

1. **Choose content.** Under **Start with**, choose one of the two prepared sessions in **How a Car Works**. Starting with the first can include the second when the window allows. The reviewed route is the authority for what will actually play.
2. **Choose your rest window.** Pick a duration, a custom duration, or an exact wake time. The window includes settling, narration, and any remaining rest; it is not a measure of time asleep. The current chooser uses the selected window and narration estimates to determine what fits; its settling and drift allowances are zero.
3. **Choose the rest sound.** **Silence** is the default. **Gentle rain** is offered when its bundled audio and provenance validate. If no complete narration fits, the plan can use only the selected rest sound. Honkshool does not speed up narration to squeeze it in.
4. **Choose the alarm.** Turn **Request a wake alarm** on if you want a system wake alarm at the fixed deadline. With it off, Honkshool schedules no wake alarm for that plan; set another alarm if you need one.
5. **Review.** Tap **Review Nap Plan** and check the planned start, fixed wake deadline, full narration route, sound, and alarm choice. Confirm any shorter alternatives or journey transitions before starting; the current bundled catalog is one ordered two-session journey.
6. **Confirm and start.** Tap **Confirm reviewed plan**, then **Start resting** before the approved start passes. The normal review lead time is about one minute; short exact-wake windows can allow less. If it expires, review the refreshed times and route again.

An alarm-enabled start first asks for alarm access if needed, schedules the alarm, and checks that its time matches the plan. Denied permission or failed verification blocks that start. You can explicitly choose an alarm-free plan instead. A previously tracked Nap Plan alarm must be cancelled before another plan can start.

## When can I lock the phone?

Keep Honkshool in the foreground until the approved narration or rain begins. This includes any initial silent settling period before narration. Then you can lock the phone.

For a **silence-only plan with no narration**, wait for the visible rest-until-deadline state at the approved start. You can then lock the phone even though there is no audio to hear.

Leaving the app too early ends the pending run and requires a new review. An alarm already scheduled for it can remain active. If rain fails, a visible status explains the fallback to silence; if that happens before narration while the app is backgrounded, the run ends rather than relying on a later silent background start.

## Control audio and alarms

| Control | Effect |
| --- | --- |
| **Pause playback** | Pauses audio. The deadline and scheduled alarm do not move. |
| **Resume playback** | Explicitly resumes when allowed, within the remaining window. |
| **Stop playback** | Ends the run's audio. A narration attempt can be saved as partial. It leaves the wake alarm active. |
| **Cancel wake alarm** | Available on the confirmed plan after the run is inactive; cancels the separately tracked wake alarm. |
| **Cancel Nap Plan wake alarm** | Cancels the tracked plan alarm from Feasibility Lab. Check the resulting status. |
| **Review another plan** | Returns to choices for a fresh review; an old tracked alarm must still be cleared before starting. |

To end both listening and the wake alarm, **stop playback, cancel the alarm, and check the result**. Cancelling an alarm alone is not an audio Stop command. The feasibility console's separate **Cancel alarm** button belongs to its test alarm.

A system interruption or lost audio output can pause playback. Honkshool requires a manual resume rather than unexpectedly restarting. The app requests exclusive playback, so existing music or a podcast yields when its audio session activates. iOS owns the exact Lock Screen media/alarm presentation; current production rain controls and physical headphone-disconnection behavior still need direct observation.

The planned deadline stays fixed even if you pause or start late. Playback never extends the window to finish a session. Cutoff depends on app execution, which iOS can delay while suspended; the independently scheduled system alarm is a separate path. Current verification and its limits are in the [feasibility guide](Feasibility-Spike.md).

## Continue a journey or revisit a session

Return to Feasibility Lab and tap **Listening history and Continue**. It shows locally saved narration attempts and journey progress.

| Action | Meaning |
| --- | --- |
| **Continue listening** | Select the next incomplete session in the journey, using its latest valid partial position when available. |
| **Resume from…** | Start from an available verified position in a partial session. |
| **Replay from start** | Start that session from the beginning and keep earlier listening history. |

Every action opens a new Nap Plan review. Reopening the app never starts audio by itself. A session advances progress only when playback reaches its actual end; reaching the plan's deadline can leave it partial. Rain-only and silence-only plans create no narration progress.

Saved positions depend on the script revision and exact prepared audio. After a content update, an old position may no longer be usable; choose the current session from its beginning and review again. If loading or saving history fails, the app shows the problem; it does not replace a failed store with empty history or stop an active nap to hide the error. The newest progress may be unavailable until saving succeeds.

## Current limits

There are two prepared automotive sessions, no content downloads, and no public supported release. Broader branching/restart/random controls and a redesigned ordinary home screen remain future work. There is no in-app history delete or export control; see [Privacy and local data](Privacy.md).

Automated device tests are separate from listening acceptance. Relative rain/narration level, longer comfort, production rain Lock Screen controls, and real headphone disconnection remain direct observations to collect. The [trial guide](Ten-Nap-Trial.md) explains how to evaluate ordinary use without putting personal history in public reports.
