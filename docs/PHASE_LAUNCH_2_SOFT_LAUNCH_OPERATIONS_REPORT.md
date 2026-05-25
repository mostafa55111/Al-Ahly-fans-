# Phase Launch 2 — Soft Launch Operations Report

## Real soft-launch ready products

Operational rollout discipline only — no fan features, no `MatchVotingCubit` changes, no new realtime.

---

## 1. Module

```
lib/features/crowd/soft_launch_operations/
├── soft_launch_remote_config.dart
├── beta_distribution_registry.dart
├── limited_rollout_controller.dart
├── production_rollout_guard.dart
├── release_channel_policy.dart
├── live_incident_tracker.dart
├── runtime_health_snapshot.dart
├── crash_signal_registry.dart
├── soft_launch_metrics.dart
├── session_success_tracker.dart
├── owner_operation_analytics.dart
├── reconnect_event_tracker.dart
├── soft_launch_governor.dart
├── controlled_rollout_gate.dart
├── soft_launch_bootstrap.dart
├── soft_launch_owner_ops_strip.dart
└── soft_launch_exports.dart
```

---

## 2. Staged rollout plan

| Stage | RC `crowd_rollout_percentage` | Audience |
|-------|-------------------------------|----------|
| Off | 0 | Internal only |
| Wave 1 | 5% | Closed beta |
| Wave 2 | 10% | Soft launch |
| Wave 3 | 25% | Monitored expansion |
| Wave 4 | 50% | Pre-public |
| Full | 100% | Requires `crowd_public_rollout_enabled` + gate GO |

Always start with `crowd_beta_channel_only=true` and `crowd_soft_launch_enabled=false` until Launch 1 human validation is complete.

---

## 3. Beta operations guide

1. Register devices in `BetaDistributionRegistry` (internal / owner / approved beta).
2. Set `release_channel` to `closed_beta` or `soft`.
3. Enable `crowd_soft_launch_enabled` only after Production Rollout Guard = SAFE or CONDITIONAL.
4. Never enable `crowd_public_rollout_enabled` until Controlled Rollout Gate = GO at 50%+ rehearsal.

---

## 4. Incident response flow

```
Detect → LiveIncidentTracker (severity)
       → Owner ops strip + Production Ops dashboard
       → If CRITICAL: crowd_emergency_rollout_stop = true
       → SoftLaunchGovernor → emergencyRollback phase
       → Post-mortem in HumanFeedbackRegistry (Launch 1)
```

Incident types: finalize failure, reconnect storm, upload failure, owner disconnect, degraded reads, emergency close, recovery activation.

---

## 5. Emergency rollback procedure

1. Set Remote Config `crowd_emergency_rollout_stop` = **true**
2. Confirm `crowd_soft_launch_freeze` = **true**
3. Set `crowd_rollout_percentage` = **0**
4. Disable `crowd_public_rollout_enabled`
5. Owner verifies session closed via existing emergency controls (Phase Admin 4)
6. Review `CrashSignalRegistry` + Crashlytics console

---

## 6. Rollout escalation policy

Expand only when `ControlledRolloutGate` returns **GO**:

- No critical incidents (2h window)
- No reconnect storm (3+ high severity)
- No crash spike (5+ signals / hour)
- Finalize success rate ≥ 85% (min 3 attempts)
- Runtime degradation below moderate

**CONDITIONAL GO**: expand with 24h owner watch.  
**NO-GO**: hold percentage, fix blockers first.

---

## 7. Operational readiness checklist

- [ ] Launch 1 GO/NO-GO green
- [ ] `crowd_feature_freeze` or `crowd_soft_launch_freeze` active
- [ ] Owner emails configured
- [ ] Production Firebase env locked
- [ ] Soft launch RC defaults installed (bootstrap)
- [ ] Matchday rehearsal on owner device
- [ ] Incident playbook shared with owner
- [ ] Crashlytics collection enabled for profile/release

---

## 8. GO/NO-GO expansion criteria

| Verdict | Meaning |
|---------|---------|
| **GO** | Stable sessions, low incidents, healthy runtime snapshot |
| **CONDITIONAL GO** | Minor warnings (owner recovery high, partial last session) |
| **NO-GO** | Critical incidents, finalize instability, reconnect storms, crash spikes |

---

## 9. Remote Config keys

| Key | Default |
|-----|---------|
| `crowd_soft_launch_enabled` | false |
| `crowd_rollout_percentage` | 0 |
| `crowd_public_rollout_enabled` | false |
| `crowd_emergency_rollout_stop` | false |
| `crowd_beta_channel_only` | true |
| `crowd_soft_launch_freeze` | true |

---

## 10. Integration (owner-only)

- `ProductLaunchBootstrap` → `SoftLaunchBootstrap.initialize()`
- `OwnerControlRoomShell` → `SoftLaunchOwnerOpsStrip`
- `ReleaseReadinessOwnerPanel` → soft launch phase line
- `ProductionOpsDashboardPage` → rollout expansion gate button

Fans never see rollout, health, incidents, or metrics.

---

## 11. QA

```bash
flutter analyze lib
flutter test test/features/crowd/
```

Tests: `test/features/crowd/soft_launch_operations/soft_launch_operations_test.dart`

---

## 12. Out of scope

- Fan UI redesign
- Social / chat / reels / live rankings
- New reconnect or vote runtime layers
- Public analytics dashboards
