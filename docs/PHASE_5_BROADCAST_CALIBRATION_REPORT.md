# Phase 5 — Broadcast UI Calibration & Real Device Perfection

**Scope:** Calibration and visual mastery only. No new product features, no `MatchVotingCubit` / stream / finalize changes.

**Repos:** `gomhor_alahly_v2` (Ahly) ↔ `zamalekawy` (Zamalek) — mirrored under `lib/features/crowd/fan_experience/broadcast_calibration/`.

---

## Calibration philosophy

The voting screen should read like a **professional sports broadcast**, not a game UI or a motion-heavy demo. Phase 5 adds a **read-only tuning layer** that multiplies existing visual tokens (spacing, opacity, motion duration, glass alpha) based on:

- viewport / device profile
- `MatchNightPhase` (from existing `MatchVotingCubit` via `MatchNightAtmosphere.resolve`)
- hall tab vs pitch tab

Central entry: `BroadcastVisualCalibrator` → `BroadcastCalibrationScope` → `BroadcastCalibrationSnapshot`.

---

## Module layout

| File | Responsibility |
|------|----------------|
| `broadcast_visual_calibrator.dart` | Scope + snapshot resolve |
| `broadcast_device_profiles.dart` | compact / tall / tablet / low-end GPU |
| `broadcast_visual_density.dart` | Glow, cards, bench, overlay, FX |
| `broadcast_spacing_calibrator.dart` | Card scale, gaps, HUD, rail breathing |
| `broadcast_focus_balance.dart` | Eye-path priority (winner > formation > countdown > bench > atmosphere) |
| `broadcast_readability_matrix.dart` | Scrim, contrast, sunlight boost |
| `broadcast_color_balance.dart` | Club warmth (Ahly gold / Zamalek silver-graphite) |
| `broadcast_motion_calibrator.dart` | Fade / press / breath caps (≤240ms) |
| `broadcast_surface_harmony.dart` | Unified glass, borders, countdown, sheets |
| `broadcast_finish_quality.dart` | Final polish + noise cap |

---

## Spacing matrix (multipliers)

| Profile | `cardScaleMul` | `edgeMarginMul` | `formationSpreadMul` |
|---------|----------------|-----------------|----------------------|
| Compact | ~0.94 | 1.06 | 1.0 |
| Tall | 1.0 | 1.0 | 1.0 |
| Tablet | ~1.05 | 1.0 | 1.03 |
| Low-end GPU | ~0.92 | 1.0 | 1.0 |

Wired into `TacticalSpacingSystem`, `TacticalFormationLayout`, and `MatchStadiumVotingLayer` layout resolve.

---

## Focus hierarchy

1. Selected / winner card — full opacity, glow only when `glowVisibility > 0.72`
2. Formation structure — `formationClarity` + spread mul
3. Countdown — `countdownPriority` + harmony backdrop
4. Substitutes — `benchAttention` × `benchWeight`
5. Atmosphere FX — capped by `visualNoiseCap` and `atmosphereFxMul`

Non-focused cards blend cinematic + broadcast opacity (min when unfocused).

---

## Readability strategy

`BroadcastReadabilityMatrix` boosts scrim darkness and text contrast on compact / low-end devices. `PremiumCardTypography.bottomNameStrip` applies `calibratedScrim()`. Countdown chip uses `countdownBackdropAlpha` and calibrated glow.

**Manual QA (required on device):** low brightness, sunlight, bright/dark card art, 15-minute continuous use — no eye fatigue, countdown always readable.

---

## Device tuning

Profiles use `DevicePressureClassifier` for low-end GPU without new architecture. FX and motion multipliers reduce on weak devices; countdown glow blur reduced on low-end.

---

## Color balancing

`BroadcastColorBalance.current()` applies club-specific warmth:

- **Ahly:** controlled warmth, gold not oversaturated
- **Zamalek:** silver not cold-blue, graphite readable

(No scene-wide color filters — token-level only.)

---

## Motion calibration

Fade/scale durations follow `BroadcastMotionTune` (180–240ms). `WinnerRevealSurface` uses calibrated fade/scale instead of aggressive bounce. Rule: motion should **psychologically disappear**.

---

## Visual density strategy

| Phase | Cards | Bench | FX |
|-------|-------|-------|-----|
| Live voting | +2% prominence | subdued | full × device |
| Closing soon | slightly brighter glow | — | — |
| Finalizing | — | quieter | ×0.65 |
| Winner reveal | hero emphasis | minimal | reduced |
| Hall tab | — | softer | ×0.8 |

---

## Wiring (integration)

- `CrowdFanImmersiveShell` — `BroadcastVisualCalibrator` inside cinematic stack
- `MatchStadiumVotingLayer` — card opacity, glow gate, FX opacity, spacing
- `TacticalFormationLayout` / `TacticalSpacingSystem` / `TacticalBenchRail`
- `FifaCardWidget` — premium tier opacity
- `GlobalVoteCountdown`, `WinnerRevealSurface`, `vote_confirmation_sheet`
- `fan_experience_contract.dart` export

---

## Performance discipline

- No extra `Bloc` streams
- InheritedWidget scope only (rebuild when device/phase changes)
- No new blur stacks, shader masks, or animated gradients
- Opacity nesting minimized

---

## QA

```bash
flutter analyze lib
flutter test test/features/crowd/
```

Unit tests: `test/features/crowd/broadcast_calibration/broadcast_calibration_test.dart`.

---

## Final polish notes

Target feeling: **premium, calm, elite sports product** — “real professional football platform,” not Flutter demo or gaming UI.

If any club feels visually louder than the other after device QA, adjust only `broadcast_color_balance.dart` identity branch — not shared layout logic.
