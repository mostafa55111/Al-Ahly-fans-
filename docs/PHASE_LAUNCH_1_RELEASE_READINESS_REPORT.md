# Phase Launch 1 — Release Readiness Report

## From engineering-ready to release candidate

Phase Launch 1 adds **release discipline** and **human validation structure** without new fan features, runtime layers, or `MatchVotingCubit` changes.

---

## 1. Module

```
lib/features/crowd/release_readiness/
├── human_validation_suite.dart
├── real_matchday_rehearsal.dart
├── release_runtime_audit.dart
├── launch_freeze_enforcer.dart
├── release_candidate_validator.dart
├── production_config_validator.dart
├── release_observability_report.dart
├── release_performance_snapshot.dart
├── release_stability_matrix.dart
├── human_feedback_registry.dart
├── release_go_live_gate.dart
├── release_readiness_bootstrap.dart
├── release_readiness_owner_panel.dart
└── release_readiness_exports.dart
```

---

## 2. Release checklist (engineering)

| Check | Tool |
|-------|------|
| No debug/sandbox in release | `ReleaseRuntimeAudit` + `ReleaseBuildAudit` |
| Feature freeze | `LaunchFreezeEnforcer` + RC `crowd_feature_freeze` |
| Owner emails configured | `ProductionConfigValidator` |
| Production Firebase env | `CrowdEnvironmentResolver` |
| Launch stability gates | `LaunchStabilitySuite` (debug run) |
| Go-live score ≥ 72 | `GoLiveReadinessEvaluator` |

---

## 3. Operational checklist (matchday)

1. Owner login (Firebase + `owner_emails`)
2. Template → preview → publish (< 30s)
3. Live voting on device + weak network test
4. Reconnect (airplane mode 10s)
5. Finalize + single winner reveal
6. Idle state when session closed
7. Emergency close + recovery check (owner only)

Use `RealMatchdayRehearsal` to record step timings.

---

## 4. Owner rehearsal flow

```
idle → owner login → session build → publish → live voting
→ reconnect → finalize → winner reveal → no-session fallback
```

Track: duration, runtime confidence, recovery correctness, smoothness.

---

## 5. Real-user validation checklist

`HumanValidationSuite` — 8 structured items:

- Fan: stadium, vote, idle
- Owner: login, publish
- Reconnect weak network
- Finalize + winner

Statuses: `pending` | `validated` | `failed` | `blocked`

Record notes in `HumanFeedbackRegistry` (internal only).

---

## 6. GO / NO-GO criteria

| Verdict | Meaning |
|---------|---------|
| **GO** | All critical checks green + no human failures |
| **CONDITIONAL GO** | Minor non-runtime warnings only |
| **NO-GO** | Runtime risk, auth, finalize instability, reconnect, release exposure |

Final gate: `ReleaseGoLiveGate`

---

## 7. Freeze policy

**Blocked during freeze:** features, tabs, runtime layers, experimental flags, realtime systems.

**Allowed:** bug fixes, readability, spacing, stability, accessibility, performance.

Remote Config: `crowd_feature_freeze`, `crowd_runtime_lock`, `crowd_launch_freeze`.

---

## 8. Performance targets

| Metric | Target |
|--------|--------|
| First frame | < 1.8s |
| Vote / tab interaction | < 120ms |
| Finalize transition | no dropped frames (manual observe) |

`ReleasePerformanceSnapshot` records measurements.

---

## 9. Rollout recommendations

1. **Internal build** — complete human validation suite (all `validated`)
2. **Staging** — full matchday rehearsal on reference devices
3. **Limited beta** — CONDITIONAL GO acceptable with documented warnings
4. **Production** — GO only when `ReleaseGoLiveGate` = GO and freeze enabled
5. **Post-launch** — monitor `ReleaseObservabilityReport` in profile builds only

---

## 10. Integration (owner-only, hidden in release)

- `ProductLaunchBootstrap` → `ReleaseReadinessBootstrap.initialize()`
- `OwnerControlRoomShell` → `ReleaseReadinessOwnerPanel` (debug/profile)
- Fans: **no exposure**

---

## 11. QA

```bash
flutter analyze lib
flutter test test/features/crowd/
```

Tests: `test/features/crowd/release_readiness/release_readiness_test.dart`

---

## 12. What we did NOT change

- Fan UI / animations / tabs
- `MatchVotingCubit` / vote runtime / sharding
- New admin systems or public analytics

This phase is **release discipline + real-world validation only**.
