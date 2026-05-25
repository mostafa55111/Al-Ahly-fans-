# Phase A — Runtime Stability Report

**Date:** 2026-05-19  
**Scope:** Legacy isolation, stream lifecycle audit, navigation guards, animation pause, mock isolation.  
**Repos:** `zamalekawy`, `gomhor_alahly_v2` (mirrored).

---

## 1. Legacy systems isolated

| Component | Status |
|-----------|--------|
| `LegacyCrowdFeatureFlags` | `enableLegacyVoting/Routes/Streams = false` |
| `EagleVotingCubit` | `@Deprecated`; no timer/vote stream when flags off |
| `CrowdRepositoryImpl` | `@Deprecated`; `loadCurrentSession` / `watchUserVote` gated |
| `_CrowdEagleSync` | Skips sync when `enableLegacyVoting` is false |
| `MatchCenterScreen` | `@Deprecated`; hidden from `MainNavigation` when routes flag off |
| `_getMockMatches` | `ProductionMockIsolationGuard.assertDebugOnlyMock` |

**Dormant (not deleted):** `voting_match_center/*`, `VotingMatchBloc`, `PredictWinScreen`, `MotmVotingCubit` on alternate routes, eagle admin paths in `CrowdAdminPage`.

---

## 2. Streams audited

### Production subscriptions (expected active at runtime)

| ID | Owner |
|----|--------|
| `match_session_stream` | `MatchVotingCubit` |
| `match_players_stream` | `MatchVotingCubit` |
| `match_my_vote_stream` | `MatchVotingCubit` |
| `match_auth_stream` | `MatchVotingCubit` |
| `voting_lifecycle_session_stream` | `VotingSessionLifecycleService` |
| `crowd_formation_stream` | `CrowdCubit` |
| `crowd_cards_path_stream_*` | `CrowdCubit` (per RTDB path) |

**Count:** ~4 match vote + 1 lifecycle + 1 formation + N card paths (typically 2–4).

### Legacy (inactive when flags false)

| ID | Owner |
|----|--------|
| `eagle_vote_stream` | `EagleVotingCubit` |
| `eagle_eligibility_timer` | `EagleVotingCubit` |

### Debug tracker

`lib/features/crowd/runtime/stream_lifecycle_audit.dart` — duplicate subscribe asserts, leak assert on cubit/service `close`/`dispose`.

---

## 3. Duplicate routes prevented

- `CrowdNavigationRuntimeGuard` — tracks `CrowdScreen`, `CrowdFanImmersiveShell`, `HallOfFamePanel` mounts.
- `_CrowdRouteMountGuard` on `CrowdScreen` — debug warning on duplicate mount.
- `tryAcquireCrowdRoutePush()` — blocks stacked `Navigator.push` crowd routes.

`AppShell` uses a single `IndexedStack` `CrowdScreen` instance (no duplicate push in primary path).

---

## 4. Animation lifecycle safe

- `MatchStadiumVotingLayer` — stops `_lightPhase` / `_votePulse` / banner timer on `paused|hidden|detached`.
- `MatchCardAnimatedAssetOverlay` — `TickerMode` + `VisibilityDetector` (pre-existing).
- `VisibilitySubscriptionGuard` — tab visibility for read tiers (pre-existing).

---

## 5. Mock isolation status

- `ProductionMockIsolationGuard` — throws in release if mock path invoked.
- `MatchCenterScreen._getMockMatches` — debug-only guard.
- Production fan path: `MatchVotingCubit` + RTDB only.

---

## 6. Remaining high-risk areas (future cleanup)

1. **Delete** `voting_match_center` module after confirming no external deep links.
2. **Remove** `EagleVotingCubit` provider from `CrowdScreen` once `LineupWidget.eagleCrowd` is retired.
3. **CrowdCubit** card-path listeners — consider consolidating to single squad stream.
4. **Flaky** `ShardDistributionAnalyzer` test under full suite (gomhor) — unrelated to Phase A.
5. **CrowdAdminPage** still references legacy eagle session APIs for owner tooling.

---

## 7. QA

```bash
flutter analyze lib/features/crowd
flutter test test/features/crowd
```

Expected: analyze clean; crowd tests pass (zamalekawy 74+ with `phase_a_runtime_test`).
