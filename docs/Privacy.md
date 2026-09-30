# Privacy and local data

[Documentation index](README.md) · [User guide](User-Guide.md) · [Security policy](../SECURITY.md)

This describes the current source implementation, not a promise about a future release. Honkshool has no app backend, user account, advertising, analytics, runtime content downloads, or app-managed cloud sync. It does not record microphone audio. Narration and rain play from bundled files.

## What is stored

| Data | Location and purpose |
| --- | --- |
| Narration attempts and verified in-flight checkpoints | SwiftData under the app's Application Support directory, in `Honkshool/ListeningHistory.store`; supports partial/completed history and resume |
| Session, journey, script, and prepared-render identity; timing and playback position | Part of local history; ensures a saved position matches the content that actually played |
| Preferred feasibility rest duration | Local app preferences, reused by the console |
| Nap Plan alarm ID, plan ID, and deadline | Local preferences, so the app can reconcile a system alarm after reopening |
| Separate feasibility test-alarm ID and original date | Local preferences; kept distinct from Nap Plan alarms. Current state is reconciled from iOS |
| Scheduled alarm | Managed by iOS AlarmKit after authorization; remains separate from the audio run |
| Feasibility diagnostic events | In-memory controller events shown in the app; any screenshots or externally captured logs can still contain sensitive details |

The history configuration explicitly disables CloudKit. Honkshool does not upload these records to a project-operated service. **Local storage is not a guarantee of exclusion from operating-system backups, device migration, or diagnostics.** The project does not configure or verify all such system behavior.

## Permissions and system services

An alarm-enabled **Start resting** requests AlarmKit authorization when needed. Denial or failed scheduling blocks that alarm-enabled plan. The app includes an explanation in its `NSAlarmKitUsageDescription`; Apple documents the [alarm permission requirement](https://developer.apple.com/documentation/bundleresources/information-property-list/nsalarmkitusagedescription).

Background audio and Lock Screen media controls use iOS media services. There is no microphone permission request in this implementation. Account credentials used by Xcode to sign a development build are development setup, not a Honkshool sign-in.

## Retention, removal, and reset limits

Earlier attempts remain when you replay a session. Relaunching does not erase history or restart audio. Rain and silence do not create narration history. A failed history store remains visible for retry; the app does not silently replace it with a fresh empty one.

There is currently **no in-app history deletion, reset, or export control**. Reinstalling, changing a fork's bundle identifier, deleting development containers, or resetting a simulator can affect access to stored data. They are not supported recovery/export workflows and should not be assumed to preserve history or cancel a scheduled alarm. Before removing or resetting a build, stop playback, explicitly cancel any tracked Nap Plan and feasibility alarms, and check their displayed status.

## Keep public contributions safe

Use synthetic listening examples in issues, tests, and screenshots. Keep personal schedules, device identifiers, account/team details, local databases, raw diagnostics, and private notes out of public Git history and attachments. Ignore rules help prevent accidental staging; they are not an access-control or encryption boundary.

`Config/Local.xcconfig`, `local-data/`, `reports/`, and generated output are local-only destinations covered by the repository's ignore rules. The [trial guide](Ten-Nap-Trial.md) uses a blank template for private notes and only a sanitized summary for any future public closeout.

Report suspected credential exposure or private-data disclosure through [SECURITY.md](../SECURITY.md). See the [domain contract](Nap-Planning-Domain.md#local-persistence-and-recovery) and [architecture](Architecture.md) for implementation details.
