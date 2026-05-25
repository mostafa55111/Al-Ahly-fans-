# Firebase Surface Audit — Phase D

## Active production paths

| Prefix | Usage |
|--------|--------|
| `match_votes/{club}/active_match` | Session metadata (single fan listener via `MatchVotingCubit`) |
| `match_votes/{club}/players` | Pitch players + legacy vote totals |
| `match_votes/{club}/user_votes/{matchId}/{uid}` | Scoped vote writes (preferred) |
| `match_vote_shards/{club}/{matchId}/...` | Sharded vote counts when `voteSharding` enabled |
| `awards/{club}/...` | Match/month/season awards on finalize |
| `{ahly\|zamalek}_squad` | Pitch card library (primary) |
| `app_cards/{club}/items` | Card fallback |
| `users/{uid}/crowd/formation` | User pitch layout |
| `stadium_cms/{club}/...` | Admin CMS (not fan tab) |
| `cards/{club}/...` | Card registry |
| `admins/{uid}` | Admin gate reads |
| `eagle_nesr/active_celebration` | Celebration overlay only |

## Deprecated / legacy (no production writes)

| Prefix | Status |
|--------|--------|
| `eagle_nesr/session_current` | Read-only celebration; voting streams removed |
| `eagles_results/*` | Display after publish (Hall of Fame) |
| `best_player` | Third fallback read in `CrowdCubit` |
| `match_votes/.../user_votes/{uid}` (unscoped) | Compat read fallback only |
| `votes/{matchId}` | Old match center — **feature deleted** |

## Heavy-read risks

1. `MatchVotesAdminCubit.watchBundle` — `onValue` on entire `match_votes/{club}`
2. `CrowdCubit` — 3 parallel card root listeners
3. Admin `admins/{uid}` stream in lineup widgets (admin preview only)

## Optimization candidates (no UX change)

- Collapse card listeners to single active path per club identity
- CMS bundle watch → scoped child paths when editing players only
- Remove `best_player` fallback after migration confirmation

## Root listeners

**Forbidden in production fan path:** no `ref('/').onValue` or unscoped `match_votes` root on fan screen.
