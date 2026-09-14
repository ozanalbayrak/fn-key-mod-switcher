# Handoff: FnSwitcher visual identity

## Overview

Complete visual identity for **FnSwitcher**, a small open-source macOS menu bar utility that toggles the F1–F12 row between standard function keys and media keys via a global shortcut.

Three deliverable groups:

1. **App icon** — Finder, /Applications, Launchpad, Login Items, About panel. Targets macOS 26 Tahoe (Liquid Glass / Icon Composer) and degrades to a flat icon on macOS 13–15.
2. **Logo set** — horizontal lockup, wordmark, glyph-only mark, README banner, GitHub social preview.
3. **Menu bar status icons** — two monochrome template images, one per toggle state.

## About the design files

`identity-board.html` is a **design reference**, not production code. It is a self-contained review board showing every asset at its real sizes on light and dark grounds. Open it in a browser; nothing needs to be built.

The shippable output is the **`assets/` folder**. Those files are final artwork — copy them into the app bundle and the repository. The only thing to "implement" is wiring them up (Icon Composer project, asset catalog, `NSStatusItem` image, README markdown).

## Fidelity

**High-fidelity.** All geometry, colours and stroke weights below are final. Do not re-derive them; use the supplied vectors.

---

## Design system

Everything is one drawing at three scales.

**Canonical grid: 1024 × 1024** (the app icon canvas).

| Element | Geometry on the 1024 grid |
| --- | --- |
| Icon canvas | Quintic superellipse, `\|x\|⁸ + \|y\|⁸ = 1`, full 1024 (closer to the Tahoe squircle than a circular-radius rounded square) |
| Keycap | x 202, y 182, w 620, h 620, corner radius 148 |
| Sun disc | centre (474, 508), r 108 |
| Sun rays | 8 rays at 45° from −90°, r 146 → 212, stroke 32, round caps |
| "F" legend | x 618, y 326, cap height 234, stem 55 |

The "F" is constructed, not typeset: stem width `sw`, top arm `0.68 × h`, mid arm `0.50 × h` starting at `0.40 × h`, arm heights `sw` and `0.92 × sw`. This keeps it renderable at any size without a font dependency.

**Logo mark** = the same grid at `216 / 620 = 0.3484` scale with the squircle canvas removed, frame stroke 16 (on a 256 box). Two optical adjustments, deliberate: the sun is scaled a further 0.90 and nudged +2px right, and the F legend is nudged −7px left / −2px up, because the mark's frame stroke is proportionally much heavier than the icon's.

**Menu bar glyph** = the same silhouette reduced to outlines on an 18 × 18 pt artboard: keycap rect x 2.5, y 2.5, 13 × 13, radius 3.2, stroke 1.5. State 1 carries the constructed F (cap height 8.4, stem 2.0). State 2 carries the sun (disc r 2.5, 8 rays r 3.9 → 5.0, stroke 1.75). **Both states use an identical keycap rectangle**, so toggling swaps the interior only and nothing in the menu bar shifts.

### Colour

Two hues plus neutrals. No third hue, no second accent.

| Token | Hex | Use |
| --- | --- | --- |
| Keycap midnight | `#2C3A52` | Icon canvas gradient top |
| Canvas floor | `#141B28` | Icon canvas gradient bottom |
| Canvas dark top / floor | `#1B2534` / `#090D14` | Dark icon variant |
| Sunlight | `#FFB02E` | Sun glyph on dark grounds |
| Sunlight, light ground | `#C97500` | Sun glyph on light grounds (contrast) |
| Graphite ink | `#1E2736` | Mark frame + wordmark on light grounds |
| Reversed ink | `#E8ECF2` / `#F3F2F2` | Mark frame / wordmark on dark grounds |
| Receding legend | `#B6C4DA` at 26% | The F on the icon's back layer |
| Social ground | `#1A2230` | GitHub social preview background |
| Social secondary text | `#A8B7CC` | Tagline |

### Typography

**Archivo** (SIL Open Font License, Google Fonts) — an open-licensed geometric sans standing in for SF Pro.

- Wordmark: `Fn` at weight **800**, `Switcher` at weight **500**, letter-spacing `-0.02em`, single line. The 800 weight on `Fn` matches the weight of the key legend on the icon; this is the tie between mark and wordmark and must not be flattened to a single weight.
- Lockup: mark 96px + 26px gap + wordmark 66px, vertically centred.
- Banner: mark 128px + 34px gap + wordmark 88px, centred in 1600 × 400.
- Social preview: mark 140px + 36px gap + wordmark 92px, flush left at 140px margin; 2px rule at 20% white spanning 140 → 1140; tagline Archivo 500 / 30px.

### Icon layer stack

Four full-bleed 1024 × 1024 plates, back to front:

1. **background** — linear gradient plus a 10% radial warm lift behind the sun
2. **keycap** — glass slab, white 19% → 5.5% fill, 10px white stroke at 32%, drop shadow `0 20 24 / black 35%`
3. **glyphs** — the F (blurred σ 3.5, 26% opacity) then the sun (amber, glow `σ 18 / 32%`)
4. **highlight** — a 9% diagonal sheen across the canvas plus a 90px specular fade on the keycap's top edge clipped to the cap

No stroke is thinner than 1/24 of the canvas (≈36px at 1024), so nothing drops out on downscale. At 16px the blurred F disappears by design and the icon resolves to a single lit key.

---

## Assets

All paths relative to `assets/`.

### App icon

| File | Notes |
| --- | --- |
| `app-icon-1024.svg` / `.png` | Flattened, clipped to the squircle, transparent outside it |
| `app-icon-512/256/128/64/32/16.png` | Downscaled flattened raster |
| `app-icon-layer-background.svg` / `.png` | Full-bleed layer 1 — Icon Composer |
| `app-icon-layer-keycap.svg` / `.png` | Full-bleed layer 2 |
| `app-icon-layer-glyphs.svg` / `.png` | Full-bleed layer 3 |
| `app-icon-layer-highlight.svg` / `.png` | Full-bleed layer 4 |
| `app-icon-dark-1024.svg` / `.png` | Dark appearance variant |
| `app-icon-tinted-1024.svg` / `.png` | Tinted / monochrome variant |
| `app-icon-glyphs.svg` | Glyph layer as vector, for reuse |

### Logo set

| File | Notes |
| --- | --- |
| `lockup-light.svg`, `lockup-light-2x.png` | Horizontal lockup, light background |
| `lockup-dark.svg`, `lockup-dark-2x.png` | Horizontal lockup, dark background |
| `lockup-black.svg`, `lockup-white.svg` | Single-colour lockups |
| `wordmark-black.svg`, `wordmark-black-2x.png` | Wordmark only |
| `wordmark-white.svg`, `wordmark-white-2x.png` | Wordmark only, reversed |
| `mark-glyph-color-light.svg`, `-2x.png` | Glyph mark, full colour on light |
| `mark-glyph-color-dark.svg`, `-2x.png` | Glyph mark, full colour on dark |
| `mark-glyph-black.svg`, `-2x.png` | Glyph mark, single-colour black |
| `mark-glyph-white.svg`, `-2x.png` | Glyph mark, single-colour white |
| `banner-1600x400.svg` / `.png` | README header, transparent, no tagline |
| `social-preview-1280x640.svg` / `.png` | GitHub social preview, with tagline |

### Menu bar status icons

| File | Notes |
| --- | --- |
| `menubar-fkey.svg`, `menubar-fkey-18pt.pdf`, `menubar-fkey-18/36/54.png` | State 1 — standard F1–F12 |
| `menubar-media.svg`, `menubar-media-18pt.pdf`, `menubar-media-18/36/54.png` | State 2 — media keys |

Pure black on transparent. macOS recolours them.

---

## Implementation

### App icon — macOS 26 Tahoe

Build an **Icon Composer** (`.icon`) project and import the four `app-icon-layer-*.png` plates in order (background, keycap, glyphs, highlight). They are full-bleed 1024 × 1024; Icon Composer applies the squircle mask and its own specular treatment, so do **not** feed it the pre-clipped `app-icon-1024.png` as a layer. Use `app-icon-dark-1024.png` and `app-icon-tinted-1024.png` as references for the dark and tinted appearances if you override Icon Composer's automatic derivations.

### App icon — macOS 13–15

Use the pre-clipped flattened rasters in a classic `AppIcon` asset set / `.icns`:

```
16, 32 (16@2x), 32, 64 (32@2x), 128, 256 (128@2x), 256, 512 (256@2x), 512, 1024 (512@2x)
```

`app-icon-{16,32,64,128,256,512,1024}.png` cover these; generate the two missing intermediate sizes by downscaling `app-icon-1024.png`, or re-render from `app-icon-1024.svg` at any size.

### Menu bar

Use the **PDFs** — vector, so they stay sharp on any display scale — and mark them as **template** images.

- Asset catalog: add each PDF, set *Render As* → **Template Image**, *Scales* → **Single Scale**, *Preserve Vector Data* → on.
- Or in code: `image.isTemplate = true`.
- Set the status item image size to `18 × 18` points and let AppKit handle 1× / 2×.
- On toggle, swap only the image on the existing `NSStatusItem.button`. Because both states share the keycap rectangle, no re-layout occurs.

Do not tint, colour or add a background to these — AppKit inverts template images for dark menu bars and for the highlighted/pressed state automatically.

### Repository

- README header: `assets/banner-1600x400.png` (transparent, works on both GitHub themes).
- GitHub social preview: `assets/social-preview-1280x640.png` — Settings → General → Social preview.

---

## Notes and caveats

- **Wordmark SVGs reference Archivo by name; they do not carry outlines.** A viewer without the font falls back to system sans. Before handing the SVGs to anyone outside the repo, convert text to paths. The PNGs are rendered with Archivo loaded and are safe everywhere.
- **The 18 × 18 pt PDFs are hand-authored vector** (paths only, no font or image resources). Open both once in Preview to confirm before committing.
- **Archivo is SIL OFL**, so it can ship in the repo and in the app bundle. If you prefer, Inter is a reasonable substitute for the wordmark, but re-check the `Fn` 800 / `Switcher` 500 contrast — Inter's weights read lighter at the same numeric value.
- Every raster here was produced from the SVGs in this bundle; the SVGs are the source of truth. Re-render rather than upscaling a PNG.

## Files in this bundle

```
identity-board.html    Self-contained visual reference — open in a browser
assets/                Final artwork (SVG, PNG, PDF)
README.md              This file
```
