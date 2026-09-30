# Troubleshooting

[Documentation index](README.md) · [Getting started](Getting-Started.md) · [User guide](User-Guide.md)

Use the visible app or Xcode message first. This is an experimental build, so keep failures distinct from behavior that has not yet been observed. Do not reset local storage as a first repair step.

## Build and installation

| Symptom | Next step |
| --- | --- |
| Terminal finds only Command Line Tools | Use full Xcode. The test script accepts `HONKSHOOL_XCODE_PATH`; other commands can use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. See [Development](Development.md#verification). |
| iOS platform or simulator is missing | Install the relevant component through Xcode's settings, then choose an installed destination. Override `HONKSHOOL_TEST_DESTINATION` for tests. |
| Signing team is missing | Create and edit the ignored `Config/Local.xcconfig` using your own Team ID. Do not publish it. |
| Bundle identifier cannot be registered | Your team may not own the repository's identifiers. Follow the personal-fork signing steps in [Getting started](Getting-Started.md#install-a-development-build-on-an-iphone); check both app and widget targets. |
| Phone will not launch the development build | Unlock/connect it, inspect Xcode's device-support and signing message, and complete the phone's Trust/Developer Mode prompts. A newer phone OS may need newer Xcode. |
| A command-line simulator build is all you need | Use the unsigned build command in [Development](Development.md#verification); do not add private signing values to shared configuration. |

## Starting a Nap Plan

| Symptom | What it means and what to do |
| --- | --- |
| You see Feasibility Lab instead of a simple home screen | This is the current entry screen. Scroll to **Choose and review a Nap Plan**. The audio and alarm test controls are separate. |
| Start says to stop feasibility audio or cancel a test alarm | Stop that console run and explicitly cancel its test alarm. Then return to the Nap Plan. |
| A previous wake alarm blocks a new plan | Use **Cancel Nap Plan wake alarm** on Feasibility Lab, or **Cancel wake alarm** on the inactive confirmed plan, and check the result before starting another. |
| The approved start passed | Review the updated deadline and route, confirm again, and tap **Start resting** before the new approved start. Do not assume the old confirmation is still valid. |
| Alarm access is denied or scheduling fails | The alarm-enabled plan cannot start. Check the app's alarm permission in iOS Settings and review again, or deliberately turn off **Request a wake alarm** and review an alarm-free plan. |
| Audio failed after an alarm was scheduled | The alarm can still be active. Read the status and cancel it explicitly if no longer wanted. |
| The review has no narration | The selected complete narration may not fit after the plan's allowances. Choose a longer rest window or accept the reviewed rain/silence-only plan. |
| The run ends when you lock the phone | Keep the app foregrounded until approved narration/rain starts. Silence-only plans with no narration can be locked after the visible rest-until-deadline state. Review again after a premature background exit; check any remaining alarm. |

## Listening and history

| Symptom | What to check |
| --- | --- |
| Gentle rain is unavailable | Its bundled file/provenance did not validate or could not play. Silence remains available. Contributors can run repository/asset checks; users should not replace the audio with an arbitrary file. |
| Rain goes silent | The app falls back visibly to silence if rain fails. A failure before narration while backgrounded can end the run; follow the displayed fresh-review instruction. |
| Audio pauses after an interruption or output change | Restore the desired output and explicitly resume when the app allows it. Pause does not extend the fixed deadline. |
| Stop did not stop the wake alarm | Expected: **Stop playback** controls audio. Explicitly **Cancel wake alarm** and check its result. |
| A session is marked partial | Audio did not reach the session's actual end. A deadline or manual Stop can leave partial progress; duration estimates do not count as completion. |
| A rain-only nap is absent from narration history | Expected: rain and silence do not create narration attempts or completed-session progress. |
| Resume is unavailable after a content change | A saved position must match the current script revision and prepared audio. Use the offered start-from-beginning action and review a new plan. |
| History reports a load or save error | Use **Retry saving** when offered. Active audio and alarms remain separate, but recent progress may not be saved. Preserve the store for diagnosis; reinstalling is not a supported repair/export workflow. |
| Reopening the app is silent | Expected: history and alarm state reconcile, but playback requires an explicit new review and start. |

## Report a reproducible problem

Open a [bug report](https://github.com/joshuawyadao/Honkshool/issues/new?template=bug_report.yml) with the build commit if known, public device model and OS version, which flow you used (Nap Plan or feasibility test), short steps, expected versus observed behavior, and a redacted error message. Describe alarm delivery separately from audio cutoff; mark anything you did not observe as unknown.

Use a synthetic time/example. Exclude device identifiers, team/account details, personal listening history, private paths, raw database files, and unredacted logs or screenshots. Security or private-data issues belong in the [private security reporting process](../SECURITY.md).
