# PHASE 4 — Premium Card Art & Broadcast Finish

**Status:** Complete (gomhor_alahly_v2 + zamalekawy)  
**Date:** 2026-05-22

---

## Goal

Elevate voting cards to **premium football broadcast** quality — visual refinement, readability, and tactile polish only.

**Not changed:** `MatchVotingCubit`, finalize, sharding, streams, awards logic, vote flow, economics.

---

## New module

`lib/features/crowd/fan_experience/premium_cards/`

| File | Role |
|------|------|
| `premium_card_broadcast_tokens.dart` | Borders, sheen, typography scales, press timing |
| `premium_card_identity_system.dart` | Ahly red/gold vs Zamalek graphite/silver |
| `premium_card_hierarchy.dart` | Tiers: normal, selected, locked, captain, winner, substitute |
| `premium_card_state_visuals.dart` | Maps tactical focus → visual state |
| `premium_card_readability_guard.dart` | Scrim/text contrast guards |
| `premium_card_typography.dart` | Broadcast name/rating strips |
| `premium_card_finish_fx.dart` | Edge sheen + field separation |
| `premium_card_glass.dart` | Sheet + bench rail materials |
| `premium_card_interaction.dart` | Press scale ≤160ms |
| `premium_card_surface.dart` | Single-shadow premium frame |

---

## Card hierarchy

| Tier | When | Visual |
|------|------|--------|
| normal | Open voting | Thin border, soft opacity |
| selected | User pick | Warmer border, full opacity |
| locked | After vote | Reduced scale/opacity |
| captain / leader | Live leader | Subtle prestige edge |
| winner | Reveal | Strongest border, warm sheen |
| substitute | Bench | Quieter scale (0.96), 0.88 opacity |

---

## Typography system

- Bottom strip uses gradient scrim tuned by `PremiumCardReadabilityGuard`
- Name / position / meta line scale from card width
- Hero name plate uses `PremiumCardTypography.namePlateTitle`
- Rating badge uses club `broadcastChip` frame

---

## Readability strategy

- Auto scrim boost on designed card art
- Name always on dark gradient strip
- Removed multi-shadow glow stacks on stadium ultra mode
- Static leader crown (no pulsing icon)

---

## Interaction philosophy

- `PremiumCardInteraction`: 0.97 scale, 140–160ms, easeOut (no bounce)
- Stadium ultra: InkWell splash disabled; interaction on outer wrap
- Hero surface: replaces infinite 1.03 pulse with premium press

---

## Material system

- Vote confirmation sheet → `PremiumCardGlass.sheetPanel`
- Bench rail → `PremiumCardGlass.benchRailPanel` (no BackdropFilter)
- Restrained dark glass, single soft shadow

---

## Wiring

| Surface | Integration |
|---------|-------------|
| `FifaCardWidget` | `stadiumUltraMode` → `PremiumCardSurface` + interaction + typography strip |
| `FifaCardHeroSurface` | Premium name plate + interaction |
| `TacticalCardAnchor` | `PremiumCardFinishFx.fieldSeparation` |
| `vote_confirmation_sheet` | Premium glass panel |
| `TacticalBenchRail` | Premium bench glass |
| `WinnerRevealSurface` | Stadium ultra card, 240ms reveal (no easeOutBack) |

---

## Performance notes

- Single box shadow on `PremiumCardSurface`
- No shader masks; no extra leader shadow stacks
- `RepaintBoundary` on wrapped stadium cards
- Removed aggressive crown pulse animations on pitch

---

## Future extension limits

- No new fan features or live rankings
- Captain tier uses leader flag until explicit captain metadata exists
- Designed cards still use clean surface path (`designedVoteClean`)

---

## QA

| Check | gomhor_alahly_v2 | zamalekawy |
|-------|------------------|------------|
| `flutter analyze lib` | **0 issues** | **0 issues** |
| `flutter test test/features/crowd` | **156 passed** | **156 passed** |

New tests: `test/features/crowd/premium_cards/premium_card_hierarchy_test.dart`

---

## Manual checks

1. Vote on pitch — card press feels tactile, not bouncy  
2. Dark / bright card art — name readable  
3. Bench cards quieter than starters  
4. Confirmation sheet readable glass  
5. Winner reveal — restrained scale-in  
