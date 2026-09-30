# Honkshool app icon

## First design iteration

The icon shows an ivory goose asleep with its neck folded into its wing against a midnight-blue background. The closed eye and compact curved silhouette emphasize rest; the small amber beak adds warmth and makes the face recognizable. It contains no text or claims about learning during sleep.

This is the first implemented design proposal, pending the owner's visual feedback. It does not establish a complete app design system.

## Asset and integration

The canonical shipped artwork is [AppIcon.png](../Honkshool/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png), an opaque 1024 × 1024 RGB PNG. The app target includes the asset catalog and selects `AppIcon` in both Debug and Release. Xcode generates the required iPhone sizes and icon metadata. The source Info.plist does not need hand-maintained icon filenames.

The artwork fills a square without baked rounded corners; iOS supplies its icon mask. This first iteration supplies the default appearance only. Custom dark, tinted, and layered Icon Composer artwork remain future design work. Playback, alarms, signing, permissions, and the widget target are unchanged.

Apple references: [Configuring your app icon using an asset catalog](https://developer.apple.com/documentation/xcode/configuring-your-app-icon) and [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons).

## Artwork provenance

- Created on 2026-09-29 with Codex's built-in image generation tool; no reference images or third-party artwork were supplied.
- The tool returned an opaque 1254 × 1254 RGB PNG. The only export adjustment was a proportional resample to 1024 × 1024 with macOS `sips`; no crop or visual redesign was applied after generation.
- Original generated PNG SHA-256: `0488bb93c0579a2249f473457bcbd514b64b26bfad33f11b0c799774a3ec771e`.
- Shipped PNG SHA-256: `4d72e8125382ecf415320e816140064b41a55bd7d0b5a85b4e1a054eda37e869`.
- The shipped PNG is the repository's source artwork for this raster iteration. The original tool output remains in the local generation history; the build does not depend on that history.

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

Create a new sibling draft when exploring alternatives, then replace the canonical asset after choosing a revision. Keep a full-square opaque 1024 × 1024 RGB export and update the provenance and prompt. Inspect the closed eye, folded neck, beak, edge padding, and light-on-dark contrast at Home Screen and Settings sizes.

Run `./scripts/verify-repository.sh` and `./scripts/test-ios.sh`. Confirm the compiled app contains `Assets.car`, generated icon PNGs, and `CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconName = AppIcon`. A Release build checks the other app configuration. Reinstall on a simulator or device for visual Home Screen review if iOS has cached earlier artwork.

No new automated test cases are needed for this resource-only change. The asset compiler, built-bundle inspection, existing suite, and visual review cover the relevant risks.
