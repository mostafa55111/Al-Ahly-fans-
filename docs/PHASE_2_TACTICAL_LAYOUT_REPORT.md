# PHASE 2 — Tactical Card Placement & Hero Layout

**Status:** Complete (gomhor_alahly_v2 + zamalekawy)  
**Date:** 2026-05-22

---

## Goal

Transform the voting screen from “pitch background + floating cards” into a **cinematic broadcast formation** experience — UI/layout only.

**Not changed:** `MatchVotingCubit`, voting logic, finalize pipeline, sharding, streams, awards, backend authority.

---

## New module

`lib/features/crowd/fan_experience/tactical_layout/`

| File | Role |
|------|------|
| `tactical_layout_tokens.dart` | Scales, safe ratios, bench/anchor constants |
| `tactical_spacing_system.dart` | Compact / tall / tablet card metrics |
| `tactical_safe_zones.dart` | Playable clamp, tabs/bench/gesture bands |
| `tactical_position_map.dart` | 4-3-3, 4-2-3-1, 3-4-3, 4-4-2, 3-5-2 anchors (relative) |
| `tactical_card_focus_state.dart` | idle / active / selected / locked / finalizing / winner |
| `tactical_card_anchor.dart` | Radial base glow + single shadow + scale hierarchy |
| `tactical_bench_rail.dart` | Floating dark-glass horizontal subs (no BackdropFilter) |
| `tactical_formation_layout.dart` | Main layer + `TacticalLayoutScope` + card positioning API |
| `tactical_layout_exports.dart` | Barrel |

---

## Wiring

| Integration | Change |
|-------------|--------|
| `SquadFieldPage` | `StadiumFoundation` → `TacticalFormationLayout` (default 4-3-3 scope) |
| `MatchStadiumVotingLayer` | `TacticalFormationLayout` wraps pitch stack; orbs use tactical positioning + `TacticalCardAnchor` |
| `FloatingSubstitutesPanel` | Broadcast mode → `TacticalBenchRail` |
| `stadium_slot_system.dart` | Deprecated wrappers delegate to tactical APIs |
| `fan_experience_contract.dart` | Exports tactical module |

**Flow:**

```
StadiumFoundationLayer
  → TacticalFormationLayout
      → atmosphere / FX (unchanged)
      → TacticalCardAnchor → FifaCardHeroSurface → FifaCardWidget
      → TacticalBenchRail (broadcast)
```

---

## Formation system

- All coordinates are **normalized** (0–1), blended lightly with RTDB (`formationBlend = 0.14`).
- GK isolated near y≈0.56; midfield compressed; forwards y≈0.10–0.18 with `forwardHeroScale`.
- Clamped to foundation playable band (top 10%, bottom 22%, sides 6%).

---

## Safe-zone strategy

- **Top:** tabs + countdown (`MediaQuery.padding.top + 72`).
- **Bottom:** bench rail height + system inset.
- **Sides:** gesture margin from horizontal safe ratio.
- Cards clamped inside foundation playable rect — reduces notch/small-phone clipping.

---

## Card hierarchy

| State | Scale | Opacity |
|-------|-------|---------|
| Forward (active) | ~1.06× | 1.0 |
| Selected | 1.04 | 1.0 |
| Winner | 1.035 | 1.0 |
| Locked | 0.94 | 0.72 |
| Finalizing | 0.97 | 0.82 |
| Idle | 1.0 | 0.9 |

Emphasis animations capped at **240ms** (card enter fade).

---

## Performance notes

- `RepaintBoundary` on each anchor and bench rail.
- **No** `BackdropFilter` on bench (replaces heavy broadcast glass).
- **No** `ClipPath`; single box shadow per card.
- No nested animated builders added on anchors.
- Existing atmosphere FX unchanged (not expanded in Phase 2).

---

## Responsive behavior

| Band | Trigger | Card width |
|------|---------|------------|
| compact | shortest < 360 | ~14.8% viewport, clamped 44–72 |
| tall | default phones | ~15.6% |
| tablet | shortest ≥ 600 | ~13.2% |

Bench cards at `benchScale` (0.78× starter width).

---

## Future extension points

- Paint foundation vignette/glow from Phase 1 tokens under cards.
- Optional right reserves column (Phase 2 uses single horizontal rail).
- Per-club anchor tuning without touching voting cubit.
- Squad preview: read formation from `SquadCubit` into `SquadFieldPage` scope.

---

## QA

| Check | gomhor_alahly_v2 | zamalekawy |
|-------|------------------|------------|
| `flutter analyze lib` | **0 issues** | **0 issues** |
| `flutter test test/features/crowd` | **151 passed** (+17 tactical tests) | **151 passed** |

New unit tests: `test/features/crowd/tactical_layout/tactical_position_map_test.dart`

---

## Screenshots

Capture on device after `flutter run`:

1. 4-3-3 / 4-2-3-1 from CMS — formation readable on neon pitch.
2. Bench rail — dark glass, no blur halo.
3. After vote — locked/selected hierarchy.
4. Small phone (320w) — no clipped cards at bottom.
