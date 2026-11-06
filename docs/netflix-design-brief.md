# NOVA × Netflix UI/UX — Design Brief (source of truth)

All screens MUST adopt the Netflix design language below. This file is the
single source of truth for the port. NEVER change behaviour, logic, strings,
keys, or test-relevant widget types — visual restyle only.

## Palette (lib/core/theme/nova_theme.dart → NovaColors)

| Token                | Value    | Use                                        |
|----------------------|----------|--------------------------------------------|
| `NovaColors.ink`     | #000000  | Page canvas (dark mode)                    |
| `NovaColors.graphite`| #161616  | Cards / sheets / menus surface             |
| `NovaColors.surfaceHigh` | #262626 | Hover / elevated surface               |
| `NovaColors.raised`  | #323232  | Inputs, secondary buttons, chips fill      |
| `NovaColors.red`     | #E50914  | Primary accent (buttons, progress, badges) |
| `NovaColors.redDeep` | #B00710  | Pressed accent                             |
| `NovaColors.white`   | #FFFFFF  | Primary text / icons                       |
| `NovaColors.mist`    | #A0A0A0  | Secondary text                             |
| `NovaColors.textDisabled` | #6B6B6B | Disabled / subtle text                |
| `NovaColors.divider` | #2E2E2E  | Hairline separators                        |
| `NovaColors.netflixLine` | #222222 | Row separators on #161616             |

Light mode: use `Theme.of(context).colorScheme` roles (they already map to
Netflix light tokens). Dark mode may use `NovaColors.*` constants directly.

`NovaTheme.of(context).gold` / `HorseTheme.gold` are the OLD accent API —
replace every remaining call-site with the correct new token (white for
icons-on-dark, `NovaColors.red` for accents).

## Geometry

- Buttons / inputs / small controls: **4dp radius**.
- Cards / thumbnails / sheets: **8dp radius** (thumbs may use 4dp).
- Chips / pills: **StadiumBorder** (full pill).
- Sheets (bottom): top radius 16–20, background `#161616` (dark) /
  scheme.surface (light), drag handle, bold white title, `LucideIcons.x` close.
- Row min-height 56dp; hairline separators `#222222` at 1dp.
- Section titles: 18dp w700 white; meta text 12–13dp `#A0A0A0`.

## Patterns

- **Selection list (audio / subtitles / sources / speeds)**: flat rows on the
  sheet surface, NO card boxes; row = white 15dp w500 label (+ muted trailing
  meta); selected row = red check (`LucideIcons.check`) at the row END and
  white w700 label; unselected = white w400. Padding 16/20.
- **Primary CTA**: `FilledButton` (red fill, white text) — already themed.
- **Secondary CTA**: white/ink text on `#323232` (`FilledButton.tonal` style or
  `FilledButton` with `backgroundColor: NovaColors.raised`).
- **Tertiary/link**: plain `TextButton` with white or `#A0A0A0` text, no icons
  unless meaningful.
- **Badges/chips**: `#333333` fill (or `NovaColors.raised`), white text, 4dp
  radius, 11–12dp w500.
- **Empty/error states**: centered icon 36–44dp in `#A0A0A0`, headline 16dp
  w600 white, body 13dp `#A0A0A0`, optional red `FilledButton` retry.
- **Spinners**: `CircularProgressIndicator(color: NovaColors.red, ...)` on dark
  canvases (white on video overlays).
- **Forms (login/sign-up)**: `TextFormField` keeps theme input style (#323232
  fill, 4dp radius). Primary submit = red `FilledButton`, full width, 48dp
  tall. Secondary links: white w600 text, centered. Form errors: bold-ish
  text in `NovaColors.warning` (#F5C451) — Netflix uses warm warnings on dark.
- **Welcome/hero surfaces**: black canvas; big bold headline (headlineMedium/
  displaySmall, w700); muted 16dp body `#A0A0A0`; red CTA.

## Hard rules

1. RTL correctness: `EdgeInsetsDirectional`, `AlignmentDirectional`,
   `PositionedDirectional` everywhere (Arabic is RTL).
2. Icons: `lucide_icons_flutter` (`LucideIcons.*`) only.
3. Keep every existing string (NovaStrings lookups), Key, Semantics label,
   widget TYPE finders rely on (FilledButton/TextFormField/Switch...), and
   ALL logic/callbacks identical. Visual containers may change freely.
4. Do NOT touch: `lib/features/settings/**` (except nothing),
   `lib/features/shell/glass_dock.dart`, `lib/shared/widgets/glass_navigation.dart`,
   `lib/features/shell/main_shell.dart`, `test/**`.
5. Prefer surgical edits (MultiEdit) over file rewrites when the file is
   behavior-heavy; full rewrite only when the widget tree is being restructured.
6. Import `../../core/theme/nova_theme.dart` (adjust depth) for tokens.
7. `NovaNetworkImage` (shared/widgets/nova_network_image.dart) stays the image
   loader; shimmer placeholder stays.
8. Do not run flutter/dart commands; the integrator runs analyze + tests.
