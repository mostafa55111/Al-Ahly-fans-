# Legacy Removal Audit — Phase D

## Removed (dead / non-production runtime)

| Component | Path | Reason |
|-----------|------|--------|
| `voting_match_center` feature | `lib/features/voting_match_center/` | Unwired `VotingMatchBloc`, unreachable `MatchCenterScreen` |
| `MainNavigation` | `lib/core/navigation/main_navigation.dart` | Never mounted from auth/splash (`AppShell` is production entry) |
| `MatchDataManager` | `lib/core/services/match_data_manager.dart` | Zero callers |
| `EaglesResultsPanel` | `lib/features/crowd/presentation/widgets/eagles_results_panel.dart` | Replaced by `HallOfFamePanel` |
| `EagleVotingCubit` / state | `lib/features/crowd/presentation/cubit/eagle_voting_*` | Legacy voting; flags always `false` |
| Duplicate `watchActiveSession` on lifecycle | `VotingSessionLifecycleService` | Fed from `MatchVotingCubit` via `notifyActiveSession` |

## Retained intentionally

| Component | Why |
|-----------|-----|
| `CrowdRepository` / `CrowdRepositoryImpl` | Cards, celebration, squad pitch, admin CRUD |
| `CrowdSyncEngine` | Production stadium atmosphere (not eagle voting) |
| `NesrCelebrationOverlay` | `eagle_nesr/active_celebration` read |
| `MotmVotingCubit` | Admin MOTM seed / `PublicArenaPage` preview |
| `legacy_crowd_feature_flags.dart` | Documents isolation until full eagle RTDB removal |
| `LineupWidget.motm` | Admin public arena preview |

## Risky dependencies (monitor)

- `CrowdCubit` triple card-path listeners (`ahly_squad`, `app_cards`, `best_player`)
- Admin `MatchVotesAdminCubit.watchBundle` — broad club root read when CMS open
- Remote authority fallback in `AuthorityOrchestrator` (single attempt, then local)

## Production voting path (post Phase D)

`CrowdScreen` → `MatchVotingCubit` → `match_votes/{club}/`  
Finalize: `ProductionFinalizePipeline` → `AuthorityOrchestrator` → `FinalizationAuthorityService`
