# Phase E — Production Economics & Cost Survivability

**Date:** 2026-05-19  
**Repos:** `zamalekawy`, `gomhor_alahly_v2` (mirrored)

## Gate status

| Check | Result |
|-------|--------|
| `flutter analyze lib` | **0 issues** |
| `flutter test test/features/crowd/` | **120/120 GREEN** (+3 economics tests) |

## Step 1 — RTDB Cost Mapping

`production_cost_surface_report.dart` — tiers (LOW/MEDIUM/HIGH) per `CostSurfacePath`: session, players, reconnect, HoF, CMS, votes, shards, media.

## Step 2 — Read Budget Enforcement

`read_budget_guard.dart` — per-surface caps:

| Surface | Budget |
|---------|--------|
| Crowd fan | 6 concurrent reads |
| Hall of Fame | 10 reads / open |
| CMS | 24 reads / tab |
| Reconnect | 4 reads / wave |
| Finalize aggregation | 8 reads |

Wired: `MatchVotingCubit`, `LazyVoteSubscriptionController`, `HallOfFameCubit`.

## Step 3 — Media Economics

`media_economics_report.dart` + `ProgressiveCardImage`:

- Duplicate URL promotion block
- Device/cache pressure skips
- Thumbnail vs full upgrade metrics

## Step 4 — Reconnect Cost Compression

`reconnect_cost_profile.dart` + `LazyVoteSubscriptionController`:

- Collapsed duplicate restore requests
- Budget-gated phased restore
- Heavy stream deferred metrics

## Step 5 — Hall Of Fame Optimization

`hall_of_fame_budget_policy.dart`:

- Featured-first load (3 items)
- Full timeline only when HoF tab visible + budget allows
- 30min sticky snapshot cache (prefs)
- Respects `FirebaseCostGuard.shouldReduceHofPreload`

## Step 6 — Vote Aggregation Economics

`aggregation_cost_guard.dart`:

- 45s aggregation timeout
- Max 3 finalize aggregation attempts / match
- Duplicate monthly/season recompute prevention

Wired: `VoteAggregationService`, `FinalizationAuthorityService`, `VotingSessionLifecycleService`.

## Step 7 — Background Runtime Suppression

`background_runtime_policy.dart` — unified pause/resume; wired via `MobileRuntimeSurvivalBridge`.

## Step 8 — Device Survival

`device_pressure_classifier.dart` — low/medium/high tiers from cost guard, background, image cache fill.

## Step 9 — Cost Simulation

`production_cost_simulator.dart` — 10k / 100k / 1M fan models with red-zone detection (debug/profile).

## Estimated Firebase load (steady match, per active fan/min)

| Scale | RTDB reads/min | writes/min | Risk |
|-------|----------------|------------|------|
| 10k | ~3.5k | ~1.2k | LOW |
| 100k | ~35k | ~12k | MEDIUM (HoF + reconnect) |
| 1M | ~350k+ | ~120k+ | **RED** without sharding + budget gates |

## Top 5 expensive runtime paths (before → after)

1. **Dual session listeners** → single stream (Phase D) + read budget
2. **HoF full timeline on tab open** → staged + budget + cache
3. **Reconnect heavy restore** → phased + deferred + collapsed
4. **Full card promotion storm** → duplicate block + device tier
5. **Finalize shard scan** → timeout + bounded attempts

## Eliminated waste (Phase E)

- Duplicate monthly/season aggregation in same process
- Duplicate image URL promotions
- Reconnect restore storms when budget exceeded
- HoF timeline hydrate when tab hidden or cost elevated
- Background heavy streams via `BackgroundRuntimePolicy`

## Remaining scaling risks (pre-1M concurrent)

1. Admin CMS `watchBundle` on full `match_votes/{club}` root
2. `CrowdCubit` triple card-path listeners
3. Shard aggregation fan-out at finalize under extreme vote rates
4. Image bandwidth on stadium tab with 11+ full promotions
5. Reconnect spike if thousands resume same second (mitigated, not eliminated)

## Expected monthly operating pressure

With budgets active: cost scales **sub-linearly** vs raw fan count for reads; writes remain **linear** with votes. Primary bill driver at scale = **vote writes + shard increments**, not HoF reads.

## Launch recommendation

Phase E gates pass. Before 100k+ live concurrent voters: load-test reconnect resume + HoF tab switch under `FirebaseCostGuard` elevated mode.
