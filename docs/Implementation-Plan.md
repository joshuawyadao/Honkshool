# Plan

Prepare this checkout and the connected iPhone 14 Pro for repeatable physical-device runs of the Honkshool feasibility spike. Keep personal signing values local, verify automatic signing from the command line, install and launch once the phone permits developer access, and document the small amount of device-side setup that cannot be automated.

## Scope

- In: connected-device and signing checks, an optional local Xcode signing configuration, automatic provisioning, a signed Debug build, installation and launch on the connected iPhone, public-safe setup documentation, and repository safety tests.
- Out: completing the physical-device feasibility matrix, changing product behavior, storing a development-team identifier or device identifier in Git, and App Store or TestFlight distribution.

## Action items

- [x] Verify the connected iPhone's pairing, Developer Mode, Developer Disk Image, iOS version, and the Mac's Apple Development identity without recording private device identifiers.
- [x] Add a tracked Xcode configuration that optionally loads an ignored local signing file, then create this checkout's local team setting without committing it.
- [x] Extend repository checks to require the public signing template and reject committed signing-team or device identifiers while allowing the intended ignored local file.
- [x] Use automatic provisioning to produce a signed Debug build for the connected iPhone.
- [x] Install and launch Honkshool on the phone, or identify the exact remaining interactive iOS/Xcode gate if installation is blocked.
- [x] Update the feasibility guide with the repeatable local-signing workflow, Developer Mode steps, safe device commands, and current device-readiness result.
- [x] Run targeted publication tests, the repository verification gate, Xcode build-setting checks, and a generic unsigned device build.
- [x] Review the diff for personal data, mark the plan complete to the achieved boundary, and save the feature branch.

## Open questions

- None. Enabling Developer Mode and accepting trust/restart prompts are expected interactive device steps, not product decisions.
