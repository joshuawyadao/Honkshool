# Plan

Promote the owner-approved thought-bubble goose to Honkshool's app icon on `codex/app-icon`. Preserve the original artwork, export the approved source at the asset catalog's required size, and update the design record before committing and pushing.

## Scope
- In: approved icon replacement, preservation of the first artwork, provenance/design documentation, asset verification, builds and existing checks, commit and push.
- Out: new artwork generation, alternate icon appearances, runtime changes, physical-device installation, and a pull request.

## Action items
[x] Inspect the saved v2 artwork/provenance, current AppIcon catalog, `docs/App-Icon.md`, `docs/Project-Overview.md`, and the validation guidance in `CONTRIBUTING.md`.
[x] Checkpoint the resolved plan before replacing the asset.
[x] Preserve the original 1024-pixel icon as `design/app-icon/sleeping-goose-v1.png`, then export `thought-goose-v2.png` proportionally to the active 1024-pixel `AppIcon.png`.
[x] Update `docs/App-Icon.md`, its project-overview description, and `thought-goose-v2.json` to record the approved icon, archived reference, exact prompt, and source/export hashes.
[x] Verify source preservation, PNG size/opacity, both thought dots at small sizes, compiled Debug/Release icon metadata, and target isolation.
[ ] Run the repository gate and existing iOS suite with the installed iPhone 17 Pro iOS 26.5 destination. No new test cases are needed because artwork changes no executable behavior.
[ ] Record the results in this plan, commit only task files, and push `codex/app-icon` using save-branch.

## Open questions
- None. The owner explicitly approved the thought-bubble version and requested making it the app icon.

## Validation evidence

- All 40 repository checks passed, including Markdown links and public-artifact checks; whitespace checks passed.
- Debug and Release builds compiled the updated icon. Both app bundles contain the expected AppIcon metadata and refreshed compiled assets; iPhone-only configuration and widget metadata remain unchanged.
- The original v1 and approved v2 source hashes are unchanged. The installed export is a valid opaque 1024 × 1024 RGB PNG. Visual inspection of the 60-pixel preview and compiled 120-pixel icon confirmed both thought dots and the sleeping face remain visible.
- A separate Apple-platform review found no actionable issues with asset preservation, export fidelity, or small-size legibility. Physical-device Home Screen review is outside this task.
- The full existing iOS suite is running on iPhone 17 Pro with iOS 26.5. No new test files were needed because no executable behavior changed.
