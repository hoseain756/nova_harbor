# NOVA design system (Harbor Cloned Design)

## Direction
Harbor Cool Grey Slate architecture, warm amber `#F4A25C` (`oklch(0.78 0.13 60)`) accents, crisp off-white `#F4F5F7` ink typography, floating island glass dock with solid squircle active indicator, stadium action pills, and 14px media card geometry.

## Palette
- **Canvas / Background**: Dark slate `#111213` (Harbor canvas, `oklch(0.18 0.004 260)`), pure black `#000000` for OLED mode.
- **Surface**: Dark charcoal `#191B1C` (Harbor surface, `oklch(0.22 0.004 260)`).
- **Elevated**: Elevated charcoal `#252628` (Harbor elevated, `oklch(0.27 0.004 260)`).
- **Raised**: `#323335` (Harbor raised, `oklch(0.32 0.004 260)`).
- **Edges & Borders**: `#3C3D3F` with 0.55 opacity for borders (`Color(0x8C3C3D3F)`), 0.25 opacity for soft hairline dividers (`Color(0x403C3D3F)`).
- **Ink (Typography)**: `#F4F5F7` (Harbor ink, `oklch(0.97 0.003 260)`).
- **Muted**: `#A8ABAD` (Harbor ink-muted, `oklch(0.72 0.003 260)`).
- **Subtle**: `#626365` (Harbor ink-subtle, `oklch(0.50 0.003 260)`).
- **Accent (Primary)**: Harbor warm amber `#F4A25C` (`oklch(0.78 0.13 60)`), deep pressed amber `#C87A38`, soft amber `#F8BE8E`.
- **Status**: Error `#C53637` (`oklch(0.55 0.18 25)`), Success `#45B164`, Rating & Warning `#F5C451`.
- **Light Theme**: Canvas `#F4F5F7`, Surface `#FFFFFF`, Ink `#111213`, Secondary `#52555A`, Accent `#944700`, Divider `#DCDFE2`.

## Typography
Sentient / Serif display hierarchy for hero titles and prominent headings; clean modern sans-serif (Poppins / Switzer / IBM Plex Sans Arabic) for body and UI; Oswald / bold display numbers for Top 10 rank rail. Headings 20/24/32/40 with weights 500/600/700.

## Geometry & Radii
Harbor token ladder:
- `sm`: 6dp (small tags, badges)
- `md`: 10dp (controls, inputs)
- `lg`: 14dp (poster cards, continue watching cards)
- `xl`: 20dp (floating bottom dock, dialogs, bottom sheets)
- `2xl`: 28dp (large containers)
- `pill`: 9999dp (stadium buttons, filter chips, indicator squircle)

## Navigation (Harbor Bottom Dock)
Harbor floating island dock centered at bottom:
- Elevated surface `#252628` at 85-90% opacity with backdrop blur (20dp radius).
- Hairline edge-soft border `Color(0x403C3D3F)`.
- 5 primary destinations: Home, Search, Live TV, Library (My Stuff), Profile/Settings.
- Iconic Harbor active squircle indicator: solid white/ink pill with dark icon inside (`#111213`).
- Inactive icons rendered in `ink-subtle` (`#626365`).
- Profile tab displays user avatar circle.

## Components
- **Cinematic Hero**: Full backdrop with smooth vertical fade to `#111213`, title logo or display typography, metadata pills (Year, Runtime, IMDB rating badge, Genre capsules), large stadium Play button (`#F4F5F7` with dark text) + circular action buttons.
- **Poster Cards**: 14dp rounded corners, hairline border, subtle gradient overlay, rating badge with gold star.
- **Top 10 Rank Rail**: Styled rank numbers (01..10) positioned beside or behind poster cards.
- **Continue Watching**: 16:9 cards with bottom-edge progress bar in amber `#F4A25C`.
