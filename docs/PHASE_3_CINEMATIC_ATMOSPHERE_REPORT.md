# PHASE 3 — Cinematic Atmosphere & Premium Motion

**Status:** Complete (gomhor_alahly_v2 + zamalekawy)  
**Date:** 2026-05-22

---

## Goal

Elevate the voting screen to a **Live Match Night** feel through visual polish and disciplined motion — without touching voting runtime, cubits, streams, or awards logic.

---

## New module

`lib/features/crowd/fan_experience/cinematic_atmosphere/`

| File | Role |
|------|------|
| `cinematic_motion_tokens.dart` | Max 240ms transitions; breath scale 1.0→1.015 |
| `cinematic_match_state_palette.dart` | Per-phase + Ahly/Zamalek ambient colors |
| `cinematic_depth_fx.dart` | Static vignette / center glow / field dim (gradients only) |
| `cinematic_focus_orchestrator.dart` | Focus priority: winner → vote → formation → bench |
| `cinematic_visibility_policy.dart` | FX visibility, bench prominence, card dimming |
| `cinematic_overlay_balance.dart` | Caps stack opacity; keeps cards dominant |
| `cinematic_breathing_motion.dart` | Subtle breath on selected/winner cards; pauses on background |
| `cinematic_transition_system.dart` | Fade + 0.985 scale (≤240ms) |
| `cinematic_atmosphere_layer.dart` | Main layer + `CinematicAtmosphereScope` |

---

## Atmosphere states

Mapped from existing `MatchNightPhase` (no new streams):

| Phase | Ambient | Field | Focus |
|-------|---------|-------|-------|
| pre_match | Soft club ambient | Light dim | Formation |
| live_voting | Warmer glow | Open center | Formation / active cards |
| closing_soon | Stronger warmth | Slight vignette | Formation |
| finalizing | Darker | Heavy dim | Background; FX reduced |
| winner_reveal | Gold/white highlight | Cinematic vignette | Winner card |
| hall_of_fame | Cool prestige | Moderate dim | Content list |

**Ahly:** deep red ambient + warm gold highlight.  
**Zamalek:** graphite ambient + white/silver highlight.

---

## Motion philosophy

- Subtle, slow, breathable — **not** game/RGB/cyberpunk.
- Max transition **240ms**; breathing full cycle **4.8s**; scale cap **1.015**.
- No particles, camera shake, infinite aggressive loops, or rotating glows.
- Breathing only on **selected** / **winner** cards; stops when app backgrounded.

---

## Focus hierarchy

1. Winner reveal  
2. Selected vote  
3. Live formation  
4. Substitutes (bench prominence scaled down on winner/finalizing)  
5. Background  

Non-focused starter cards dimmed via `CinematicVisibilityPolicy` (e.g. 0.62–0.92 opacity multiplier).

---

## Wiring

| Surface | Integration |
|---------|-------------|
| `CrowdFanImmersiveShell` | `CinematicAtmosphereLayer` under `StadiumAtmosphereController` |
| `SquadFieldPage` | Inherits depth FX via parent layer (foundation → depth → tactical) |
| `MatchStadiumVotingLayer` | FX gating, card dim/breath, atmosphere opacity |
| `TacticalBenchRail` | Bench prominence opacity |
| `MatchVoteClosureOverlay` | `CinematicTransitionSystem` + palette-tinted scrim |
| `HallOfFamePanel` | Phase-keyed transition wrapper |

**Flow:**

```
StadiumFoundationLayer
  → CinematicDepthFx (RepaintBoundary)
  → TacticalFormationLayout + voting overlays
  → Card breathing / focus dim (selected only)
```

---

## Repaint strategy

- `CinematicDepthFx`: single `RepaintBoundary`, static gradients — no animated repaint.
- `CinematicBreathingMotion`: isolated `RepaintBoundary` per breathing card.
- Atmosphere FX wrapped in `Opacity` from policy — no extra blur/shaders.
- `BlocSelector` on `MatchVotingState` for snapshot — no new subscriptions.

---

## Performance impact

- No `BackdropFilter` added in this phase.
- Opacity stacks capped via `CinematicOverlayBalance` (≤0.72 atmosphere contribution).
- Finalizing hides collective pulse + reduces crowd/FX layers.
- Low-end behavior unchanged for device pressure (existing `StadiumMotionProfile`).

---

## Extension limits (out of scope)

- No new streams / polling / cubit API changes.
- No live percentages, leaderboards, 3D, particles.
- No redesign of `StadiumCrowdAtmosphereLayer` internals — only visibility/opacity gating.

---

## QA

| Check | gomhor_alahly_v2 | zamalekawy |
|-------|------------------|------------|
| `flutter analyze lib` | **0 issues** | **0 issues** |
| `flutter test test/features/crowd` | **154 passed** | **154 passed** |

New tests: `test/features/crowd/cinematic_atmosphere/cinematic_focus_orchestrator_test.dart`

---

## Manual verification

1. Live voting — cards readable, soft depth, no glow overload.  
2. After vote — selected card breathes; others slightly dimmed.  
3. Finalizing — FX fade down; countdown still readable.  
4. Winner overlay — 240ms transitions; bench subdued.  
5. HoF tab — calm transition; no voting FX bleed.  
6. Background app — breathing pauses (lifecycle).
