# PhotonLink UI/UX Redesign

A front-end-only redesign of PhotonLink. **No transfer protocols, transports,
reliability/FEC/compression/encryption layers, the adaptive engine, packet
formats, session management, or any business logic were modified.** Only
screens, navigation, layouts, components, styling, theme, and UX changed.

The redesign follows the provided wireframe and is dark-theme-first, card-based,
rounded, responsive across Android / Windows / Linux / macOS, and built on a
reusable `Photon*` component library.

---

## Design language

- **Default theme:** Dark (near-black canvas, dark-gray cards, high-contrast
  white text). Light theme is still available via Settings → Appearance.
- **Background:** `#0A0A0C` with a subtle indigo/cyan gradient wash.
- **Cards:** `#161619` with `#2C2C33` borders and rounded corners.
- **Accents:** PhotonLink brand indigo `#6366F1`, violet `#8B5CF6`, cyan
  `#06B6D4`, plus per-transport accent colors.
- **Motion:** lightweight — card hover/press feedback, staggered entry on Home,
  animated success/failure hero on completion.

### Design tokens

| File | Purpose |
| --- | --- |
| `lib/ui/colors.dart` | Palette: brand seeds, light/dark surfaces, gradients |
| `lib/ui/typography.dart` | Inter type scale (unchanged) |
| `lib/ui/spacing.dart` | Spacing scale (unchanged) |
| `lib/ui/radii.dart` | Corner radius tokens (unchanged) |
| `lib/ui/motion.dart` | Durations / curves (unchanged) |
| `lib/ui/responsive.dart` | **New** — breakpoints + `context` helpers |
| `lib/core/theme/app_theme.dart` | `ThemeData` for light + dark |

Breakpoints: `mobile < 600 ≤ tablet < 905 ≤ desktop`. Use
`context.isWide`, `context.isMobile`, and `context.responsive(mobile:…, tablet:…, desktop:…)`.

---

## Reusable component library

Import the barrel: `import '../../shared/components/components.dart';`

| Component | Description |
| --- | --- |
| `PhotonCard` | Foundational rounded dark-gray surface; optional `onTap` with hover elevation + press scale; optional `accentColor` glow; `selected` state; `semanticLabel` |
| `PhotonButton` | Primary / secondary / ghost / danger variants, sizes, icon, `loading`, `expand` |
| `PhotonIconButton` | Tonal rounded icon button with tooltip (history / settings / back / filter) |
| `PhotonSectionHeader` | Title + subtitle + optional leading icon + trailing action |
| `PhotonMethodCard` | Transport method tile (icon + name + description), vertical or `compact` row |
| `PhotonHistoryCard` | History row: file, method, direction, size, date, time, duration, status, failure reason |
| `PhotonSettingsPanel` | Settings navigation: vertical sidebar (wide) or horizontal chip strip (mobile) |
| `PhotonInfoTile` | Label / value (or value widget) row for info & diagnostics panels |
| `PhotonStatusBadge` | Status pill with tone (success/error/warning/info/neutral) + icon |
| `PhotonBackButton` | Consistent top-left back affordance (pops, falls back to Home) |

Supporting shared widgets (`lib/shared/widgets/`):

- `InnerScreenHeader` — back button + centered title + optional actions.
- `TransferInfoPanel` — the right-hand details panel for transfer screens.
- `TransferStageLayout` — responsive two-pane (display | info) for transfers.
- `TransferPresentation` — maps backend phase/bytes to display strings/tones.
- `CompletionHero` — animated success/failure hero.
- `GradientScaffold` — animated gradient background scaffold (retained).

---

## Screens

| Screen | File | Layout |
| --- | --- | --- |
| Home | `features/home/home_screen.dart` | History (top-left) + Settings (top-right); centered branding; 3 horizontal method cards (stacked on mobile); footer with about/analytics, copyright, version |
| Method | `features/transfer_setup/transfer_setup_screen.dart` | Back + centered method name; two cards (description \| Send/Receive actions), stacked on mobile |
| Transfer (QR/Color Matrix, send/receive) | `features/qr_transfer/*`, `features/color_matrix_transfer/*` | Two-pane: optical display \| info panel (file, size, method, status, progress, throughput, quality, adaptive profile, encryption, compression, session); full-bleed camera on mobile receivers |
| History | `history/presentation/history_screen.dart` | Back + title + Filters; search field; method/status filter sheet; card list (2-col on desktop); tap for detail |
| Settings | `settings/presentation/settings_screen.dart` | Two-pane: category nav \| content (General, Appearance, Transfer, Adaptive Engine, FEC, Diagnostics, History, Language, About) |
| About / Analytics / File Picker / Camera Scan / Completion | various | Restyled to the new component system |

---

## Accessibility

- Semantic labels on interactive cards; tooltips on icon buttons.
- High-contrast text tokens on dark surfaces.
- Touch-friendly target sizes (44px icon buttons, large action tiles).
- Keyboard/pointer hover affordances on desktop via `MouseRegion`.
- Layouts scale with text/window size; no horizontal overflow on mobile.

---

## Migration notes

**Removed (obsolete) widgets** — replaced by the `Photon*` library:

- `shared/widgets/glass_card.dart` → `PhotonCard`
- `shared/widgets/animated_pill_button.dart` → `PhotonButton`
- `shared/widgets/section_header.dart` → `PhotonSectionHeader`
- `shared/widgets/staggered_reveal.dart` → `flutter_animate` directly
- `features/home/widgets/transfer_method_card.dart` → `PhotonMethodCard`
- `features/qr_transfer/widgets/diagnostics_panel.dart` → `TransferInfoPanel`
- `photonAppBar()` helper (in `gradient_scaffold.dart`) → `InnerScreenHeader`

**Behavioral defaults changed (UI only):**

- Default `ThemeMode` is now **dark** (`AppSettings.themeMode` default and the
  no-preference fallback in `SettingsRepository.load`). Users can still pick
  System/Light/Dark in Settings.

**Settings consolidation:** existing settings were reorganized into categories.
No new settings or persistence keys were added. The FEC category is read-only
(FEC remains fully managed by the adaptive engine). The History category reuses
the existing `PersistentHistoryRepository.clearAll()`.

**Unchanged:** all controllers, providers, repositories, protocol/transport
code, routes (`AppRoutes`), and route wiring. Screens call the exact same
notifier methods and read the same providers as before.

### Pre-existing issues (out of scope)

`flutter analyze` reports a small number of errors/warnings in backend files
that were already modified on this branch before the redesign and are **not**
part of this UI work (and must not be touched per the brief):

- `transfer/application/color_matrix_receiver_controller.dart` — nullable
  `decoder` access (2 errors)
- `transfer/application/sender_controller.dart` — unused `dart:io` import
- `transfer/color_matrix/color_frame_generator.dart` — unused import

All redesigned UI files pass analysis cleanly.
