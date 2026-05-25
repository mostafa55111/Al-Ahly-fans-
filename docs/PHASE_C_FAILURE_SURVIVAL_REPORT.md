# Phase C — Failure Survival Report

**Date:** 2026-05-19  
**Repos:** zamalekawy + gomhor_alahly_v2 (mirrored)

---

## QA gate

| Check | Result |
|-------|--------|
| `flutter analyze` (failure_survival + touched) | **0 errors** |
| `flutter test test/features/crowd/failure_survival/` | **ALL GREEN** |

---

## Components

| Module | Role |
|--------|------|
| `durable_vote_intent_queue.dart` | Persistent FIFO vote intents (SharedPreferences) |
| `finalize_recovery_orchestrator.dart` | Partial finalize resume without double aggregation |
| `stale_session_guard.dart` | Server-clock stale session rejection |
| `infrastructure_degradation_resolver.dart` | Runtime modes under degradation |
| `mobile_runtime_survival_bridge.dart` | Lifecycle phased restore + intent replay |
| `deterministic_backoff.dart` | Exponential + deterministic jitter |
| `failure_survival_runtime_report.dart` | Debug metrics only |

---

## Production wiring

- `CrowdScreen` → `MobileRuntimeSurvivalBridge` (replaces inline lifecycle switch)
- `MatchVotesRepositoryRtdb` → `StaleSessionGuard` + durable queue on write failure
- `DeadSessionRecoveryService` → duplicate recovery guard + degradation slot
- `VotingSessionLifecycleService` → recovery dedupe on finalize
- `ReconnectBackoffController` → deterministic delays (no `Random`)

---

## Simulation results (tests)

| Scenario | Result |
|----------|--------|
| Queue survives restart | Persisted across prefs reload |
| FIFO cap | 3 max, oldest dropped |
| Interrupted finalize | No re-aggregation when snapshot exists |
| Stale session | Blocks finalized / past `closesAtServer` |
| Reconnect storm | `lightweightRuntime` mode |
| Duplicate recovery | Single in-flight + degradation slot |
| Authority timeout | `authorityFallback` + increasing backoff |
| Deterministic backoff | Same op → same delay |

---

## Metrics (debug only)

`FailureSurvivalRuntimeReport.toJson()` — recovered intents, stale blocks, finalize recovery, degraded activations, reconnect suppression, queue depth.

---

## Remaining risks

- Physical RTDB integration not in unit suite (by design).
- Vote intent replay requires `MatchVotesRepository` + `SharedPreferences` registered (production DI).
- Full `failure_survival` replay success rate depends on live session still open.
