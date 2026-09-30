# Plan

Promote the owner-approved thought-bubble goose to Honkshool's app icon on `codex/app-icon`. Preserve the original artwork, export the approved source at the asset catalog's required size, and update the design record before committing and pushing.

## Scope
- In: approved icon replacement, preservation of the first artwork, provenance/design documentation, asset verification, builds and existing checks, commit and push.
- Out: new artwork generation, alternate icon appearances, runtime changes, physical-device installation, and a pull request.

## Action items
[x] Inspect the saved v2 artwork/provenance, current AppIcon catalog, `docs/App-Icon.md`, `docs/Project-Overview.md`, and the validation guidance in `CONTRIBUTING.md`.
[ ] Checkpoint the resolved plan before replacing the asset.
[ ] Preserve the original 1024-pixel icon as `design/app-icon/sleeping-goose-v1.png`, then export `thought-goose-v2.png` proportionally to the active 1024-pixel `AppIcon.png`.
[ ] Update `docs/App-Icon.md`, its project-overview description, and `thought-goose-v2.json` to record the approved icon, archived reference, exact prompt, and source/export hashes.
[ ] Verify source preservation, PNG size/opacity, both thought dots at small sizes, compiled Debug/Release icon metadata, and target isolation.
[ ] Run the repository gate and existing iOS suite with the installed iPhone 17 Pro iOS 26.5 destination. No new test cases are needed because artwork changes no executable behavior.
[ ] Record the results in this plan, commit only task files, and push `codex/app-icon` using save-branch.

## Open questions
- None. The owner explicitly approved the thought-bubble version and requested making it the app icon.
