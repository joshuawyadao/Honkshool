# Plan

Create the first Honkshool iPhone app icon in the isolated `codex/app-icon` worktree from `origin/main`. Develop a calm sleeping-goose concept, integrate it into the app's asset catalog, and save a buildable first iteration for visual review.

## Scope
- In: original generated icon artwork, iOS asset-catalog configuration, an icon design/source record, repository validation, and a branch push.
- Out: app-screen redesign, playback/alarm changes, distribution, custom alternate appearances, and a pull request.

## Action items
[x] Read `README.md`, `CONTRIBUTING.md`, `docs/Product-Brief.md`, `docs/Project-Overview.md`, the Xcode project, and verification scripts; confirm there is no existing icon or brand system.
[x] Create a managed worktree from the remote default branch and select `codex/app-icon`.
[x] Commit this resolved plan as the first local checkpoint using the save-branch staging guardrails.
[x] Generate and visually inspect a simple sleeping goose with a moonlike silhouette, midnight-blue background, warm cream body, and amber beak; preserve the full prompt and source provenance.
[x] Add a full-square opaque 1024-pixel icon under `Honkshool/Resources/Assets.xcassets/AppIcon.appiconset` and wire the asset catalog plus AppIcon build setting into both app configurations.
[x] Add `docs/App-Icon.md` with the design intent, generated-artwork provenance, Apple configuration references, and future-edit instructions; link it from `docs/Project-Overview.md`.
[x] Verify full-size and small-size legibility, PNG dimensions/opacity, asset-catalog compilation, and compiled app icon metadata. Avoid baked rounded corners and confirm the widget/test targets keep their current settings.
[x] Run `./scripts/verify-repository.sh` and the complete `./scripts/test-ios.sh` suite required by `CONTRIBUTING.md`, using isolated derived data. No test files need changes because this adds artwork and build resources without executable behavior.
[x] Record validation evidence, commit the implementation and completed plan, and push `codex/app-icon` using save-branch.

## Open questions
- None. The sleeping-goose direction is an initial design proposal for review, not a claim of user-approved final branding.

## Validation evidence

- Repository gate: all 40 Python checks passed; project plist and whitespace checks passed.
- Debug and Release simulator builds include the AppIcon catalog and generated icon metadata. The original asset is a valid opaque 1024 × 1024 RGB PNG; the iPhone target and widget metadata remain unchanged.
- Full-size artwork, a 60-pixel preview, and the compiled 120-pixel icon were visually inspected. A separate Apple-platform review found no actionable correctness issues.
- The default simulator test command could not resolve iPhone 17 Pro with OS=latest under Xcode 27. The complete suite passed with the installed iPhone 17 Pro on iOS 26.5 via HONKSHOOL_TEST_DESTINATION: 233 passed, 0 failed, 6 skipped. Xcode reported internal thread-priority warnings in the existing spike tests; no test failures or asset-compiler warnings occurred.
- No test files were changed because no executable behavior changed. Device Home Screen review and custom appearance variants remain outside this initial iteration.

- Save record: plan checkpoint `c00d365` and artwork/integration checkpoint `7b61784`; the final validation commit records this completed plan. All task files are included; no unrelated files were changed.
