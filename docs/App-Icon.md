# Honkshool app icon

## Approved design

The icon shows an ivory goose asleep with its neck folded into its wing against a midnight-blue background. Its softly rounded body and two small trailing dots also suggest a thought bubble. The closed eye and compact silhouette emphasize rest; the small amber beak makes the face recognizable. It contains no text or claims about learning during sleep.

The owner approved this second design iteration as the active app icon. It does not establish a complete app design system.

## Asset and integration

The installed artwork is [AppIcon.png](../Honkshool/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png), an opaque 1024 × 1024 RGB PNG exported from the approved [thought-bubble goose source](../design/app-icon/thought-goose-v2.png). The [original sleeping-goose icon](../design/app-icon/sleeping-goose-v1.png) is archived alongside it. The app target includes the asset catalog and selects `AppIcon` in both Debug and Release. Xcode generates the required iPhone sizes and icon metadata. The source Info.plist does not need hand-maintained icon filenames.

The artwork fills a square without baked rounded corners; iOS supplies its icon mask. This iteration supplies the default appearance only. Custom dark, tinted, and layered Icon Composer artwork remain future design work. Playback, alarms, signing, permissions, and the widget target are unchanged.

Apple references: [Configuring your app icon using an asset catalog](https://developer.apple.com/documentation/xcode/configuring-your-app-icon) and [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons).

## Approved artwork provenance

- Created on 2026-09-30 with Codex's built-in image generation edit tool, using the first sleeping-goose icon as its reference. The exact edit prompt and source details are saved in [thought-goose-v2.json](../design/app-icon/thought-goose-v2.json).
- Approved source: `design/app-icon/thought-goose-v2.png`, an opaque 1254 × 1254 RGB PNG copied from the tool output without modification; SHA-256 `7918f9419dffa2604a17f84e4b642bb323c49179b9b1c6b6884822932d9428ae`.
- Installed export: `Honkshool/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, an opaque 1024 × 1024 RGB PNG; SHA-256 `36570c609fc29650d9c507197138ea2d1d0d4b811c3ec56f352d783a5ebcc9ea`.
- The only change from approved source to installed export was a proportional resample to 1024 × 1024 with macOS `sips`. No crop or visual redesign was applied.

## First design iteration (archived)

- Created on 2026-09-29 with Codex's built-in image generation tool; no reference images or third-party artwork were supplied.
- The tool returned an opaque 1254 × 1254 RGB PNG. The only export adjustment was a proportional resample to 1024 × 1024 with macOS `sips`; no crop or visual redesign was applied after generation.
- Original generated PNG SHA-256: `0488bb93c0579a2249f473457bcbd514b64b26bfad33f11b0c799774a3ec771e`.
- Archived first export: [sleeping-goose-v1.png](../design/app-icon/sleeping-goose-v1.png), SHA-256 `4d72e8125382ecf415320e816140064b41a55bd7d0b5a85b4e1a054eda37e869`.
- This first export served as the reference image for the approved edit. The original tool output remains in the local generation history; the build does not depend on that history.

### Exact generation prompt

```text
Use case: logo-brand
Asset type: production iPhone app icon artwork for Honkshool, a calm factual narration app for naps and bedtime.
Primary request: create one polished original icon of a peacefully sleeping white goose, curled into an elegant compact crescent-like silhouette, neck tucked softly toward its wing, a single closed-eye stroke and a small muted amber beak. A calm, memorable mascot with restrained charm.
Scene/backdrop: a full-bleed deep midnight-blue square, very subtle tonal depth, no scenery.
Style/medium: refined minimal editorial illustration with crisp smooth contours and broad sculpted shapes; warm ivory goose with very subtle blue-gray shading. Designed to read immediately at small home-screen icon sizes, not a detailed painting or toy render.
Composition/framing: single centered large goose silhouette occupying roughly 72 percent of the square, comfortably inset on every side; clear beautiful negative space; no additional symbols.
Lighting/mood: quiet, warm, sleepy, sophisticated.
Color palette: midnight navy, warm ivory, restrained amber accent.
Text: none.
Constraints: exactly one square 1024x1024 artwork, opaque edge-to-edge background. Straight square outer edges; do not draw rounded corners, an inset tile, a border, a device frame, or a surrounding mockup. No lettering, numbers, stars, floating Zs, headphones, books, separate moon, photorealistic feathers, watermark, or multiple design options. The goose must look asleep and be recognizably a goose with a graceful folded neck rather than a duck.
```

## Editing and verification

Create a new sibling draft when exploring alternatives, then replace the installed asset after choosing a revision. Keep a full-square opaque 1024 × 1024 RGB export and update the provenance and prompt. Inspect the closed eye, folded neck, beak, bubble dots, edge padding, and light-on-dark contrast at Home Screen and Settings sizes.

Run `./scripts/verify-repository.sh` and `./scripts/test-ios.sh`. Confirm the compiled app contains `Assets.car`, generated icon PNGs, and `CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconName = AppIcon`. A Release build checks the other app configuration. Reinstall on a simulator or device for visual Home Screen review if iOS has cached earlier artwork.

No new automated test cases are needed for this resource-only change. The asset compiler, built-bundle inspection, existing suite, and visual review cover the relevant risks.
