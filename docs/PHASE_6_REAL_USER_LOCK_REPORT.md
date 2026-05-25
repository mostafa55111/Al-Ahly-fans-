# Phase 6 — Real User Lock + Device Validation

**Scope:** Validation, stabilization, and human-feel verification only. No new animations, overlays, cubit changes, or architecture shifts.

**Repos:** `gomhor_alahly_v2` ↔ `zamalekawy` (mirrored).

---

## Philosophy

Stop visual expansion. Confirm the fan experience feels **professionally built**, not “effect-heavy.” Future work requires a **production reason** (measurable UX, performance, or accessibility) — not new ideas or cool motion.

---

## Module: `real_validation/`

| File | Role |
|------|------|
| `production_surface_lock.dart` | Freeze fan UI surface; allowlist modifications |
| `launch_freeze_guard.dart` | Freeze layers; tiny tuning only (±8%) |
| `real_device_validation_suite.dart` | Orchestrator + device matrix |
| `visual_fatigue_audit.dart` | 15+ min calm / glow / contrast |
| `real_user_focus_tracking.dart` | Attention hierarchy heuristics |
| `interaction_quality_audit.dart` | Press/fade/softness |
| `real_world_readability_report.dart` | Sunlight, AMOLED, compact type |
| `thermal_performance_monitor.dart` | GPU tier + FX pressure |
| `render_stability_audit.dart` | Opacity stacking, breathing on low-end |
| `visual_noise_detector.dart` | Glow stacks, FX clutter |
| `launch_freeze_guard.dart` | Stadium/cinematic/cards/motion/calibration lock |

**Runtime:** Active only when `!kReleaseMode && (kDebugMode || kProfileMode)`. Release builds strip `assert()` wiring — **zero production overhead**.

---

## Product surface lock

**Frozen:** extra overlays, tabs, experimental FX, new motion systems, live leaderboards, visual experiments.

**Allowed when locked:**

- Bug fixes  
- Readability fixes  
- Spacing fixes  
- Device compatibility fixes  

API: `ProductionSurfaceLock.instance.guardExpansion(FanExperienceExpansionKind.*)`

---

## Launch freeze rules

Layers: stadium structure, cinematic hierarchy, card hierarchy, typography, motion philosophy, broadcast calibration.

`LaunchFreezeGuard` — relative changes must stay within **±8%** when active.

---

## Fatigue findings (automated heuristics)

- Warn if `glowVisibility > 0.92` or atmosphere FX high outside winner reveal  
- Warn on aggressive edge highlights and heavy overlays  
- Info if fade < 200ms (prefer calm motion)

**Manual:** 20 min continuous use, low battery, night comfort — no eye strain.

---

## Device findings

Reference matrix (automated in bootstrap/tests):

| Class | Viewport |
|-------|----------|
| Compact | 340×720 |
| Tall | 412×915 |
| Medium | 393×851 |
| Flagship | 412×892 |
| Tablet | 800×1280 |
| Low-end | 360×640 |

Verify on real hardware: frame pacing, touch, thermal, scroll, lifecycle resume.

---

## Readability findings

- Text contrast / scrim / countdown backdrop thresholds  
- Compact card scale vs typography overlap risk  
- Sunlight boost ≥ 1.0 on stressed profiles  

**Manual:** sunlight, low brightness, AMOLED, white kit, bright card art.

---

## Thermal & render audit

- Fail if low-end GPU + high `atmosphereFxMul`  
- Warn on opacity layer stacking > cap  
- Warn if card breathing enabled on low-end tier  

---

## Attention hierarchy results

Priority confirmed via `RealUserFocusTracking`:

1. Selected / winner card  
2. Formation  
3. Countdown  
4. Bench (subdued)  
5. Atmosphere (capped)

---

## Wiring

- `ProductLaunchBootstrap` — bootstrap suite + reference matrix log  
- `BroadcastVisualCalibrator` — `assert()` audit hook  
- `CinematicAtmosphereLayer` — `assert()` audit hook  
- `fan_experience_contract.dart` — export  

---

## Approved future modifications

- Crash / logic bugs  
- Illegible text / contrast WCAG-style fixes  
- Spacing overlap / clipped UI  
- Device-specific jank or thermal regression fixes  
- Tiny calibration deltas within freeze guard  

## Prohibited future modifications

- New fan-facing tabs or overlays  
- New motion systems or experimental FX  
- Live leaderboards / extra statistics on pitch  
- “Better animation” or redesign loops without production ticket  

---

## QA

```bash
flutter analyze lib
flutter test test/features/crowd/
```

Tests: `test/features/crowd/real_validation/real_validation_test.dart`

---

## Final principle

> “This platform feels professionally built.”  
> Not: “This app has many effects.”

**Fan experience status: LOCKED FOR LAUNCH.**
