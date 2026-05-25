# Owner Control Room — Phase 4 Reliability Report

## Matchday reliability & operational hardening

Phase 4 hardens **owner-only** matchday operations for production: reconnect, weak network, accidental taps, app kill/resume, and duplicate operations — without changing fan UX, `MatchVotingCubit`, or vote runtime/sharding.

---

## 1. Module layout

```
lib/features/crowd/owner_control_room/matchday_reliability/
├── live_session_guard.dart
├── owner_operation_lock.dart
├── critical_action_protection.dart
├── matchday_network_resilience.dart
├── live_session_persistence.dart
├── owner_resume_recovery.dart
├── operational_health_monitor.dart
├── safe_finalize_recovery.dart
├── matchday_reliability_audit.dart
├── matchday_failure_banner.dart
├── owner_runtime_status_strip.dart
├── matchday_recovery_section.dart
├── matchday_reliability_header.dart
├── matchday_reliability_bundle.dart
├── matchday_reliability_scope.dart
└── matchday_reliability_exports.dart
```

---

## 2. Operational protections

| Component | Protection |
|-----------|------------|
| `LiveSessionGuard` | Blocks dual live sessions, publish on completed session, finalize during preparing, emergency close during finalize |
| `OwnerOperationLock` | In-memory scoped lock per shell; 15s max hold; rejects duplicate publish/finalize/emergency taps |
| `CriticalActionProtection` | Hold-to-confirm (≥600ms) for finalize, emergency close, destructive actions |
| `LaunchValidator` (Phase 3) | Unchanged — still gates broadcast start |

---

## 3. Recovery flow

- **`SafeFinalizeRecovery`** — advises stuck finalize; retries only via `MatchdayEmergencyControls` → `ProductionFinalizePipeline` (single path).
- **`OwnerResumeRecovery`** — on app resume: validates session/phase, syncs health, restores tab index; **never auto-finalize**.
- **Recovery UI** — `MatchdayRecoverySection` + emergency panel with locks + critical confirm.

---

## 4. Restart behavior

- **`LiveSessionPersistence`** (SharedPreferences, club-scoped):
  - active match id, phase, formation, tab index, timestamp
- **On cold start:** shell restores tab **يوم المباراة** when live context exists.
- **Does not:** recreate session, re-publish, or replay finalize.

---

## 5. Reconnect behavior

- **`MatchdayNetworkResilience`** — evaluates `Connectivity` + `SocketPressureGuard` (no polling).
- States: healthy / degraded / reconnecting / unstable / offline.
- **Safe reads** may retry once; **writes** never auto-replay — pending action stored for explicit owner retry.
- **`MatchdayFailureBanner`** surfaces offline/degraded/stuck finalize messages.

---

## 6. Dangerous actions policy

| Action | Policy |
|--------|--------|
| Publish session | Guard + operation lock |
| Finalize retry | Critical hold-confirm + lock + pipeline in-flight check |
| Emergency close | Critical hold-confirm + lock; blocked during finalize |
| Recovery check | Blocked while finalize in-flight |

---

## 7. Release safety

- `MatchdayReliabilityAudit` — debug diagnostics only (`ProductionSurfaceGate`).
- No new fan streams, cubits, or polling.
- All surfaces behind `AdminSurfaceIsolation` + owner auth (Phase 3).
- Debug tooling not exposed in release builds.

---

## 8. UI integration

- **`OwnerControlRoomShell`** — `MatchdayReliabilityBundle` + lifecycle resume + tab persistence.
- **`MatchdayOperationalSurface`** — reliability header, guarded publish, persistence on publish.
- **`MatchdayEmergencyPanel`** — critical confirm + guards.
- **`OwnerActiveMatchPage`** — reliability header when used in owner flows.

---

## 9. QA

```bash
flutter analyze lib
flutter test test/features/crowd/owner_control_room/
```

Tests: `test/features/crowd/owner_control_room/matchday_reliability/matchday_reliability_test.dart`

---

## 10. Fan experience guarantee

No changes to:

- Stadium / voting UI
- `MatchVotingCubit` public API
- Sharding / finalize architecture (read-only `isFinalizeInFlight` only)
- Vote streams or runtime layers

This phase is **operational hardening only** for the owner control room.
