# Plan

Create the first Honkshool iPhone app icon in the isolated `codex/app-icon` worktree from `origin/main`. Develop a calm sleeping-goose concept, integrate it into the app's asset catalog, and save a buildable first iteration for visual review.

## Scope
- In: original generated icon artwork, iOS asset-catalog configuration, an icon design/source record, repository validation, and a branch push.
- Out: app-screen redesign, playback/alarm changes, distribution, custom alternate appearances, and a pull request.

## Action items
[x] Read `README.md`, `CONTRIBUTING.md`, `docs/Product-Brief.md`, `docs/Project-Overview.md`, the Xcode project, and verification scripts; confirm there is no existing icon or brand system.
[x] Create a managed worktree from the remote default branch and select `codex/app-icon`.
[ ] Commit this resolved plan as the first local checkpoint using the save-branch staging guardrails.
[ ] Generate and visually inspect a simple sleeping goose with a moonlike silhouette, midnight-blue background, warm cream body, and amber beak; preserve the full prompt and source provenance.
[ ] Add a full-square opaque 1024-pixel icon under `Honkshool/Resources/Assets.xcassets/AppIcon.appiconset` and wire the asset catalog plus AppIcon build setting into both app configurations.
[ ] Add `docs/App-Icon.md` with the design intent, generated-artwork provenance, Apple configuration references, and future-edit instructions; link it from `docs/Project-Overview.md`.
[ ] Verify full-size and small-size legibility, PNG dimensions/opacity, asset-catalog compilation, and compiled app icon metadata. Avoid baked rounded corners and confirm the widget/test targets keep their current settings.
[ ] Run `./scripts/verify-repository.sh` and the complete `./scripts/test-ios.sh` suite required by `CONTRIBUTING.md`, using isolated derived data. No test files need changes because this adds artwork and build resources without executable behavior.
[ ] Record validation evidence, commit the implementation and completed plan, and push `codex/app-icon` using save-branch.

## Open questions
- None. The sleeping-goose direction is an initial design proposal for review, not a claim of user-approved final branding.
