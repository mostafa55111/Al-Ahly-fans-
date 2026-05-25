# PHASE H — Fan Experience Lock + Cinematic Stadium

**Status:** Complete (gomhor_alahly_v2 + zamalekawy mirrored)  
**Date:** 2026-05-22  
**Scope:** Fan-facing visual lock only — no new streams, polling, or MatchVotingCubit API changes.

---

## Visual principles

| Principle | Implementation |
|-----------|----------------|
| Card is hero | `FifaCardHeroSurface` — scale pulse, name plate, locked badge |
| Stadium is background | `StadiumSurfaceLayers` + `StadiumDepthSystem` — 62% pitch opacity, radial vignette |
| Premium > flashy | Soft gold/white glow rings, no RGB/neon overload |
| No live competitive UI | Existing `maskLiveCompetitive` unchanged |
| Club identity | `StadiumVisualTokens` branches ahly vs zamalek |

---

## Atmosphere system

**Module:** `lib/features/crowd/fan_experience/`

| File | Role |
|------|------|
| `match_night_atmosphere.dart` | Phases: pre_match, live_voting, closing_soon, finalizing, winner_reveal, hall_of_fame |
| `stadium_atmosphere_controller.dart` | `StadiumAtmosphereScope` via existing `MatchVotingCubit` selector + server time |
| `stadium_depth_system.dart` | Cinematic vignette + center spotlight |
| `stadium_motion_profile.dart` | Breath/glow amplitudes per phase + `DevicePressureClassifier` |
| `stadium_visual_tokens.dart` | Colors, glass, tab styling per club |

Phases use **session fields + `EgyptServerTimeService.serverNowMs`** for closing-soon only (no new RTDB listeners).

---

## Motion rules

- Card pulse: `flutter_animate` scale 1.0→1.03 when voting open (disabled on low-end).
- Glow ring: `VoteCardGlowRing` — sin breath from existing `_lightPhase` controller.
- Stadium FX/audio controllers: unchanged lifecycle (paused/hidden stops animations from Phase A).
- Heavy blur on tabs: reduced on Zamalek / low-end via `StadiumMotionProfile.allowHeavyBlur`.

---

## Voting flow polish

- `showMatchVoteConfirmationDialog` → delegates to `showMatchVoteConfirmationSheet` (modern bottom sheet).
- Haptics: `FanExperienceHaptics` — tap, confirm, success, reveal.
- Post-vote: `VoteLockedInteractionGate` + `VoteLockedBadge` on selected card.
- Winner: `WinnerRevealSurface` in `MatchVoteClosureOverlay` (final totals only after close).

---

## Hall of Fame prestige

- `HallOfFamePrestigeFrame` — glass sections, larger season card (120×166), hero match card.
- Horizontal timeline rail retained; spacing/typography upgraded.

---

## Performance protections

- Reuses `DevicePressureClassifier`, `CrowdAnimationBudget`, existing preload/read budgets.
- No new `StreamSubscription`, `Timer.periodic`, or Firebase paths.
- Card orb rebuild scope unchanged (`BlocSelector` per player).

---

## Fan experience contract

Exported via `fan_experience_contract.dart`:

- One immutable vote per session.
- No live percentages/leaderboards for fans during voting.
- Final vote counts only after `awardsFinalized`.
- Optional haptics only; no autoplay audio added in Phase H.

---

## Integration map

| Surface | Change |
|---------|--------|
| `SquadFieldPage` | Stadium image opacity + depth when atmosphere scope present |
| `CrowdFanImmersiveShell` | `StadiumAtmosphereController`, glass tabs from tokens |
| `MatchStadiumVotingLayer` | Hero cards, glow rings, depth overlay, haptics |
| `HallOfFamePanel` | Prestige frames |
| `MatchVoteClosureOverlay` | Cinematic winner reveal |

---

## QA gate

| Check | Result |
|-------|--------|
| `flutter analyze` (fan_experience + touched files) | 0 issues |
| `flutter test test/features/crowd` | **134 passed** |
| Twin repo `zamalekawy` | Mirrored |

---

## Admin control panel alignment (owner CMS)

**Module:** `admin_control_visual_system.dart` (owner-only surfaces)

| Surface | Change |
|---------|--------|
| `StadiumCmsPage` | Glass app bar + tabs, club gradient scaffold, cinematic preview |
| `StadiumCmsCommandBar` | Glass quick-session panel |
| `StadiumCmsDesign.surfaceCard` | Optional glass panels via same tokens |
| `CrowdAdminPage` | Entry tile to Match Control Console |
| `_PreviewTab` | `cmsPitchPreview` = same stadium layers as fan screen |

**Not changed:** `MatchVotesAdminCubit`, publish/finalize paths, RTDB writes.

---

## Remaining (post-launch, optional)

- Admin CMS panel visual parity with reference mock (owner-only; separate from fan shell).
- Further reduce duplicate name plates if designed cards already embed names.
- Tune `stadium_pitch_*.png` assets for 3D broadcast look per club art pipeline.

---

## DO NOT BUILD BEFORE LAUNCH (unchanged from Phase F)

- Live vote percentages on pitch.
- Public leaderboards during session.
- Fan-facing analytics dashboards.
- Extra realtime surfaces beyond launch contract.
