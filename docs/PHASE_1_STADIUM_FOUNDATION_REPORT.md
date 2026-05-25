# PHASE 1 — Stadium Foundation Rebuild

**Status:** Complete (gomhor_alahly_v2 + zamalekawy)  
**Date:** 2026-05-22

---

## Goal

Replace the legacy voting stadium background with a single vertical cinematic foundation image, ready for card layers in Phase 2.

**Asset:** `assets/images/stadiums/stadium_foundation_vertical.png`

---

## New module

`lib/features/crowd/fan_experience/stadium_foundation/`

| File | Role |
|------|------|
| `stadium_foundation_layer.dart` | Stateless pitch image only (`BoxFit.cover`, `RepaintBoundary`, `FilterQuality.medium`) |
| `stadium_foundation_safe_layout.dart` | Full-screen pitch + `SafeArea` for child content |
| `stadium_foundation_tokens.dart` | Vignette/glow/safe-zone constants (no animations in Phase 1) |
| `stadium_foundation_exports.dart` | Barrel export |

---

## Files modified

| File | Change |
|------|--------|
| `lib/shared/widgets/squad_field_page.dart` | Uses `StadiumFoundationSafeLayout` — removed old `stadium_pitch_*.png` |
| `lib/features/crowd/fan_experience/stadium_surface_layers.dart` | Delegates to foundation (CMS compat) |
| `lib/features/crowd/fan_experience/admin_control_visual_system.dart` | CMS preview uses foundation |
| `lib/features/crowd/match_votes/presentation/widgets/match_stadium_voting_layer.dart` | Removed `StadiumDepthSystem` + `MatchStadiumPitchOverlay` (legacy pitch FX) |
| `lib/features/crowd/match_votes/presentation/widgets/stadium_slot_system.dart` | Playable rect aligned to `StadiumFoundationTokens` safe zones |
| `lib/features/crowd/fan_experience/stadium_visual_tokens.dart` | Tactical overlay disabled |
| `pubspec.yaml` | Added `assets/images/stadiums/` |

## Assets removed (legacy)

- `assets/images/stadium_pitch_ahly.png`
- `assets/images/stadium_pitch_zamalek.png`

Both apps now share the same foundation asset path (club branding on cards/header remains separate).

---

## Not changed (per spec)

- `MatchVotingCubit` / sharding / finalize
- No new streams, polling, or animations on foundation layer
- Card UI unchanged (Phase 2)
- No logos on foundation layer

---

## SafeArea / long screens

- `StadiumFoundationSafeLayout` uses `SafeArea` with `maintainBottomViewPadding: true` when `applySafeAreaToChild: true`.
- Crowd voting shell uses `applySafeAreaToChild: false` so the pitch fills edge-to-edge; tabs use existing `SafeArea` in `CrowdFanImmersiveShell`.
- Playable card zone: top 10%, bottom 22% reserved, 6% horizontal inset — reduces clipping on tall phones and notch devices.

---

## QA

| Check | gomhor_alahly_v2 | zamalekawy |
|-------|------------------|------------|
| `flutter analyze lib` | **0 issues** | **0 issues** |
| `flutter test test/features/crowd` | **134 passed** | **134 passed** |

---

## Screenshots

Capture manually after `flutter run` on each app:

1. Crowd tab → Voting — full vertical neon pitch visible
2. No duplicate old grass/broadcast mock under glass panels
3. CMS → Preview tab — same foundation inside preview frame

---

## Known / Phase 2

- Subtle vignette/glow from tokens not painted yet (constants only).
- Card formation Y anchors may need fine-tuning once cards sit on neon center circle.
- Screenshots not attached in CI — verify on device/emulator.

---

## Scaling notes

- `BoxFit.cover` keeps center circle anchored on tall/narrow devices; extreme aspect ratios may crop side stands slightly — acceptable for cinematic full-bleed look.
- No overflow expected on foundation layer itself (no child layout in layer).
