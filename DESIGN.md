# Harbor Design System (Complete Clone for Mobile & Tablet)

## Overview & Philosophy
Complete abandonment of all previous Nova design concepts in favor of a 1:1 reproduction of the **Harbor Design System**. While Harbor originated as a desktop/TV media experience, this implementation fully adapts Harbor's visual language, component hierarchy, geometry, and tokens for **Mobile (iPhone, Android)** and **Tablet (iPad, Android Tablets)** with responsive ergonomics.

---

## What Was Abandoned (Nova Legacy Removal)
1. **Nova Brand Accents & Colors**: Replaced Nova Red (`#D13B47`) and gold ribbons with Harbor's Signature **Cool Grey & Warm Amber** palette (`#F4A25C`).
2. **Vertical Rail Bars**: Removed the vertical accent line (`Container(width: 3, height: 19...)`) beside section titles. Replaced with Harbor's clean, typography-led section headers with subtle trailing chevrons.
3. **Editorial Numbering in Top 10**: Abandoned the small `01, 02` text beneath posters. Replaced with Harbor's iconic **giant outlined numeral (`118-158px`)** positioned behind the poster on the start edge.
4. **Edge-to-Edge Hero with Arrows**: Replaced full-bleed hero and `< 1 / 8 >` arrow buttons with Harbor's **floating rounded card (`aspect 16/13` on phone, `21/9` on tablet)**, featuring a `TrendingUp` badge, white Play stadium pill, frosted circular buttons, and bottom horizontal pill paginator dots.
5. **Plain-Text Detail Metadata**: Replaced raw text metadata in detail screens with Harbor's **frosted pill capsules (`HarborPill`)**.
6. **Circular Cast Avatars**: Replaced `ClipOval` circular avatars with Harbor's **portrait cast cards (`CastChip`: 92x136dp, ratio 2:3, rounded-xl)**.
7. **Dense Plain Navigation**: Replaced plain bottom bars with Harbor's **Floating Island Dock** on mobile and Harbor's **SideRail** on tablet/iPad.

---

## Design Tokens

### Color Palette (Harbor Default Cool Grey)
| Token | Hex / Value | Description |
| :--- | :--- | :--- |
| `canvas` | `#111213` | Root deep cool-grey backdrop (`oklch(0.18 0.004 260)`) |
| `surface` | `#191B1C` | Card and sheet backdrop (`oklch(0.22 0.004 260)`) |
| `elevated` | `#252628` | Floating dock, dropdowns, and overlays (`oklch(0.27 0.004 260)`) |
| `raised` | `#323335` | Interactive hover/pressed surface (`oklch(0.32 0.004 260)`) |
| `edge` | `rgba(60, 61, 63, 0.55)` | Defined element borders (`Color(0x8C3C3D3F)`) |
| `edgeSoft` | `rgba(60, 61, 63, 0.25)` | Subtle dividers and card rings (`Color(0x403C3D3F)`) |
| `ink` | `#FFFFFF` (`#F4F5F7`) | High-contrast headings and primary icons |
| `inkMuted` | `#A8ABAD` | Secondary body text and metadata |
| `inkSubtle` | `#626365` | Inactive icons, subtle hints, text stroke outline |
| `accent` | `#F4A25C` | Signature warm amber (`oklch(0.78 0.13 60)`) |
| `accentDeep` | `#C87A38` | Pressed / focused amber state |
| `rating` | `#F5C451` / `#F5C518` | IMDb star and badge rating gold |
| `danger` | `#C53637` | Destructive actions and alerts |

### Geometry & Radii (`HarborRadii`)
- **`sm` (6dp)**: Badges, trending indicators, small tags.
- **`md` (10dp)**: Control buttons, cast cards, inputs.
- **`lg` (14dp)**: Media posters, rank tiles, card surfaces.
- **`xl` (20dp)**: Floating bottom dock, sheet corners, modal dialogs.
- **`xxl` (28dp)**: Floating Hero card, large section containers.
- **`pill` (9999dp)**: Stadium action buttons, search inputs, active indicator squircle.

---

## Form Factor Architecture: Phone vs. Tablet

```
+--------------------------------------------------------------------------+
|                               FORM FACTORS                               |
+------------------------------------+-------------------------------------+
|         PHONE (iPhone / Android)   |          TABLET (iPad / Android)    |
+------------------------------------+-------------------------------------+
| Navigation:                        | Navigation:                         |
|   Harbor Floating Island Dock      |   Harbor SideRail (Left / Start)    |
|   - Centered bottom dock           |   - 72dp persistent rail            |
|   - Solid white squircle active    |   - Active squircle pill            |
|   - 5 destinations                 |   - Brand mark + Secondary nav      |
+------------------------------------+-------------------------------------+
| Hero Presentation:                 | Hero Presentation:                  |
|   - Aspect Ratio: 16/13            |   - Aspect Ratio: 21/9 or Widescreen|
|   - Horizontal Margin: 16dp        |   - Horizontal Margin: 32dp         |
|   - Border: 28dp rounded card      |   - Full wide content layout        |
+------------------------------------+-------------------------------------+
| Grid Layouts:                      | Grid Layouts:                       |
|   - Rails: Horizontal smooth scroll|   - Rails: Expanded smooth scroll   |
|   - Library / Search: 3 columns    |   - Library / Search: 4 to 6 columns|
+------------------------------------+-------------------------------------+
```

---

## Component Specifications

### 1. Home Hero (`FeaturedHero`)
- **Container**: Floating card with `HarborRadii.xxl` (28dp radius), subtle `edgeSoft` border, and deep ambient drop shadow (`blur: 28dp, offset: 0, 10`).
- **Backdrop**: Smooth cross-dissolve with slow Ken Burns scale, bottom vertical gradient from `black/5` to `black/95`.
- **Trending Badge**: Frosted pill (`black/50`, 6dp radius) with `TrendingUp` icon in Harbor amber (`#F4A25C`) and `#1 in Movies Today` / `#1 in Series Today`.
- **Title / Logo**: TMDB logo (max height 72dp) or bold display title text with text drop shadow.
- **Metadata Line**: Year, yellow IMDb star badge, genre.
- **Action Buttons**:
  - *Play*: Solid white stadium pill (`#FFFFFF`) with dark ink text (`#111213`) and play icon.
  - *Watchlist*: Frosted circular button (`52x52dp`, `white/24` border, `black/38` backdrop) with `plus` / `check` icon.
  - *More Info*: Frosted circular button (`52x52dp`, `white/24` border, `black/38` backdrop) with `info` icon.
- **Paginator**: Elongated pill active dot (`20x6dp` in `#F4A25C`) and circular inactive dots (`6x6dp` in `white/24`).

### 2. Harbor Top 10 Ranked Rail (`Top10Rail`)
- **Card Size**: 152dp wide x 176dp high tile.
- **Signature Numeral**: Giant transparent outlined number (`116-152dp` font size, leading `0.82`, letter spacing `-4`) with 2.4dp stroke outline in `onSurfaceVariant` (`0.5` opacity) anchored on the start edge.
- **Poster Overlap**: 62% width poster card (`94x138dp`, ratio 2:3) overlapping on the end edge with 12dp radius and shadow.
- **Title Caption**: Positioned below the card, offset by 38% to align with the poster.

### 3. Media Rails (`MediaRail`)
- **Header**: Clean typography title (`18px`, `FontWeight.w600`, letter spacing `-0.2`) paired with a subtle trailing `chevron-right` icon. No vertical lines.
- **Posters**: 122dp (phone) or 138dp (tablet) width with 14dp radius (`HarborRadii.lg`) and frosted IMDb rating pill at the bottom-end corner.

### 4. Detail Page (`MediaDetailPage` & `DetailHero`)
- **Hero**: Inset backdrop with gradient fading into canvas.
- **Back Button**: 40x40dp circular frosted button with white chevron at top-start.
- **Metadata Row (`DetailMetaRow`)**: Replaced plain text with Harbor frosted pill capsules (`HarborPill`):
  - Year pill
  - Rating pill (accent star + score)
  - Runtime pill
  - Certification pill
  - Genre capsules
- **Overview (`DetailSynopsis`)**: Clamped synopsis with Harbor amber "More" / "Less" expandable toggle.
- **Cast Row (`DetailCastCrew`)**: Harbor portrait cards (`CastChip`: 92x136dp, ratio 2:3, 10dp radius) with actor and character names.

### 5. Floating Navigation Dock (`GlassDock`)
- Floating island dock centered at bottom with safe area clearance.
- Width: `min(400dp, 100% - 32dp)`.
- Background: elevated charcoal (`#252628`) at 85% opacity with 24dp blur.
- Active Indicator: Solid white squircle pill (`13dp` radius) with ink icon inside (`#111213`).
