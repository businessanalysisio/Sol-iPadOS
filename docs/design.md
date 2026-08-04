# design.md — Sol Design System (iPadOS)

**Source of truth:** Sol Design & Brand Guideline (official PDF) — "Intelligence that illuminates action."
**Supersedes:** PRD §3.1 color spec (Green #46B152 / Forest #0C2F1F). ADR-D07: the official brand guideline wins; all green tokens are retired.
**ADR-D08 (02/08/2026, PO-approved — CR-D3 from PRD-APP-IPAD v1.1.1):** heading typeface **Be Vietnam Pro replaces Poppins** everywhere. Evidence: cmap audit of official Google Fonts files — Poppins covers only 46/134 Vietnamese characters (missing all of ơ/ư U+01A0–01B0 and 90/96 of U+1EA0–1EFF); Be Vietnam Pro covers 134/134; Inter (body) covers 134/134 and is unaffected. Poppins is retired for all in-app roles; Brand Guideline PDF to be amended accordingly.
**Consumers:** Agent A1 (iOS-Core/DesignSystem), A2 (editor chrome), mockups, marketing site.

> **Canonical location note (04/08/2026):** file này chuyển vào repo `Sol-iPadOS/docs/` sau khi bản tại `Downloads/design.md` bị mất khỏi máy; từ nay sửa đổi qua git.

---

## 1. Brand foundation (context for design decisions)

Sol = the sun: **illumination · energy · center of gravity · orientation · rhythm**. The mark encodes 5 ideas: circular S (connected memory), central spark (insight), rising diagonal (action), O as orbit (shared context), L as foundation (logic). Operating framework: **C.O.D.E.** — Clarify, Organize, Define, Execute.

Design implications used throughout this system:
- Light is the metaphor → light mode is **warm cream**, not clinical white; dark mode is **charcoal with a warm orange glow**, not neutral black.
- "Orbit" and "spark" are the sanctioned decorative vocabulary (concentric rings, dot grids, radial glow, diagonal hatch) — used sparingly, never behind body text.

## 2. Color tokens

### 2.1 Primitives (from brand palette — do not invent new brand colors)

| Token | Hex | Brand name |
|---|---|---|
| `orange.core` | `#D85A0B` | Sol Orange (primary) |
| `orange.sunrise` | `#FF8A00` | Sunrise |
| `orange.burnt` | `#8F3408` | Burnt Core |
| `cream` | `#F8F2EA` | Warm Cream |
| `charcoal` | `#2B211B` | Charcoal |
| `gray.900` | `#191512` | Gray 900 |
| `gray.700` | `#384152` | Gray 700 (slate) |
| `gray.500` | `#6B7280` | Gray 500 |
| `gray.300` | `#DADEE2` | Gray 300 |
| `gray.100` | `#F3F4F6` | Gray 100 |

Derived (documented, not brand-invented): `line.warm #EAE0D3` (border on cream), `surface.dark #241C16`, `line.dark #3A2E24` — warm neutrals interpolated between cream/charcoal for UI chrome. Flag to PO in the next brand review.

### 2.2 Semantic tokens

| Semantic | Light | Dark | Usage |
|---|---|---|---|
| `bg` | cream `#F8F2EA` | gray.900 `#191512` | app background |
| `surface` | `#FFFFFF` | `#241C16` | cards, panes, sheets |
| `surface.alt` | gray.100 | `#2B211B` | gutters, toolbars |
| `text.primary` | charcoal `#2B211B` | `#F3EBE0` | body |
| `text.secondary` | gray.500 | `#B9A895` | metadata, captions |
| `accent` | orange.core | orange.sunrise | CTA, selection, active states |
| `accent.strong` | orange.burnt | orange.core | links/accent **text** on light (contrast), pressed states |
| `border` | `#EAE0D3` | `#3A2E24` | hairlines |
| `positive` | `#3B7A3F` | `#6FBF73` | sync OK (functional) |
| `warning` | orange.sunrise tint 12% + burnt text | same | conflict banners |
| `danger` | `#C2452F` | `#E06A54` | destructive, LIVE dot |

### 2.3 Data-visualization ramp (charts, in order)

`#D85A0B → #FF8A00 → #8F3408 → #384152 → #6B7280`. Bar gradient: `linear(180°, #FF8A00, #D85A0B)`. Axis/baseline: `text.primary`. Never use accent orange for both a selected UI state and a chart series in the same view — charts win, UI falls back to `gray.700`.

### 2.4 Presence palette (functional extension — needs PO sign-off)

Peer cursors/avatars must be distinguishable from `accent`: self = orange.core, peer-1 = slate `#384152`, peer-2 = violet `#7C6BD9`, peer-3 = teal `#2E7D74`. Selection tints at 18% alpha.

### 2.5 Contrast rules (WCAG, verify in CI snapshot)

- Body text: only `text.primary` on `bg`/`surface` (≈12:1 ✓).
- `orange.core` on white ≈ 4.0:1 → allowed for UI components and text ≥15pt semibold only; running-text links use `orange.burnt` on cream (≈7:1 ✓).
- Dark mode accent text uses `orange.sunrise` on gray.900 (≈8:1 ✓); `orange.core` reserved for fills.
- Never place the logo or accent on low-contrast grounds (brand "incorrect usage" rule).

## 3. Typography

| Role | Face | Size/weight (iPad, pt) |
|---|---|---|
| Display / H1 | Be Vietnam Pro SemiBold/Bold | 28 / 22 |
| H2 | Be Vietnam Pro SemiBold | 17 |
| Subheading | Be Vietnam Pro Medium | 15 |
| Body | Inter Regular | 15 (editor preview 13–15, Dynamic Type scaled) |
| Label / accent | Inter Medium–SemiBold | 12–13, +2% tracking, sentence case |
| Numbers / data | Inter SemiBold or mono (SF Mono fallback for `Inter Mono`) | tabular figures ON |
| Code / Markdown source | SF Mono / ui-monospace | 13, line-height 1.7 |

Rules: Be Vietnam Pro **only** for headings/subheads (personality lives there); everything functional is Inter. Numbers in tables/charts always tabular. Vietnamese diacritics: coverage **verified 02/08/2026** (Be Vietnam Pro 134/134, Inter 134/134 — ADR-D08); snapshot tests still assert precomposed + combining rendering on every font update.

## 4. Layout, spacing, shape

- Spacing scale: 2 / 4 / 8 / 12 / 16 / 24 / 32.
- Radius: controls 8–9, cards 12, sheets/panels 14, pills 999. Never 0-radius (not the brand's language) and never squash the logo (no stretching per guidelines).
- Elevation: borders first; shadow only for overlays (`0 16px 44px rgba(25,21,18,.22)`).
- Hairline dividers use `border`; section emphasis uses a 3pt `accent` left rule (H2 in preview).

## 5. Iconography & graphic elements

- Icon style: **outline** as default state, **fill** for active/selected (per guideline icon types). Mono single-color in `text.secondary`; accent only when interactive-active. Gradient icons reserved for marketing, not in-app.
- Sanctioned decoration (max one per screen, never behind text): dot grid (empty states), concentric orbit rings (About/share/branding surfaces), radial orange glow (dark-mode hero/backdrop), diagonal hatch (skeleton/loading fills).
- Logo: use provided marks only — no stretching, recoloring, outlining, rearranging, added elements, or low-contrast placement.

## 6. Component specs (app)

| Component | Spec |
|---|---|
| Nav/app bar | 44pt; surface bg; title Be Vietnam Pro SemiBold 14–15; trailing CTA = accent filled button |
| Button (primary) | accent fill, white label Inter SemiBold 12–13, radius 9, pressed → `accent.strong` |
| Chip/status | pill, border, Inter Medium 11; status dot: positive/warning/`gray.500` (offline) |
| Card (document) | surface, border, radius 12, hover/focus → accent border + warm shadow; file-type tag in mono `accent.strong` |
| Editor gutter (signature) | 34pt rail, `surface.alt`; block tags mono 8pt — structural blocks (H1/H2/TB/BQ/UL/DB — CR-D2) in `accent`, P/empty in `text.secondary`. The gutter mirrors the Block Model — it is product truth, not decoration |
| Toolbar | 34pt, `surface.alt`, tokens as bordered keys; active key = accent fill |
| Table (preview) | header row `orange.burnt` bg + cream text; zebra `surface.alt` |
| Charts | ramp §2.3; value labels Inter SemiBold tabular; baseline 1.5pt `text.primary` |
| Conflict banner | `warning` tint bg + burnt border/text; always names the conflicted-copy file; actions: filled sunrise + ghost |
| Presence | 22pt avatars, 2pt surface ring, palette §2.4; cursor flag = peer color, name Inter SemiBold 8pt |

## 7. Motion

- Durations: micro 120–180ms, pane/mode changes 250–350ms, ease-out.
- Sanctioned ambient motion: LIVE pulse, sync-in-progress dot, cursor blink. Nothing else loops.
- `prefers-reduced-motion` / iOS Reduce Motion: disable all loops and crossfade instead of move.

## 8. Dark mode principles

Dark = **warm**: gray.900 base, charcoal surfaces, warm borders; accent shifts one step brighter (core→sunrise) for text, fills stay core. Optional radial glow (§5) only on non-reading surfaces. Never invert the logo into outline.

## 9. Implementation notes

- **SwiftUI:** ship as asset-catalog colors named exactly as semantic tokens (`bg`, `surface`, `accent`, …) with light/dark variants; typography via `Font.custom("BeVietnamPro-SemiBold", …)` + Dynamic Type relative sizing (bundle Be Vietnam Pro OFL files in the app); spacing/radius as `enum Sol.Spacing/Radius`.
- **Web/mockups:** CSS custom properties mirroring §2.2 names, `data-theme="dark"` switch.
- Snapshot tests (A1 DoD) must cover: both themes × **all three split ratios (50/50, 33/67, 67/33 — CR-D1, APP-FR-02)** × Dynamic Type XL, plus a contrast assertion for §2.5 pairs.

## 10. Open items

1. PO sign-off: presence palette (§2.4) and derived warm neutrals (§2.1).
2. Confirm licensed availability of "Inter Mono" (guideline mentions it; fallback chain defined in §3).
3. Marketing surfaces (site, App Store) may use photography/illustration styles from the guideline — out of scope for this app spec.
