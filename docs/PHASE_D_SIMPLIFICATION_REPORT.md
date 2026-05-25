# Phase D — Production Simplification Report

**Date:** 2026-05-19  
**Repos:** `zamalekawy`, `gomhor_alahly_v2` (mirrored)

## Gate status

| Check | Result |
|-------|--------|
| `flutter analyze lib` | **0 errors** (1 info: prefer_function_declarations — fixed) |
| `flutter test test/features/crowd/` | **117/117 GREEN** |

## Step 1 — Single Voting Authority Path

- Added `production_finalize_pipeline.dart` — sole production finalize entry.
- Flow: lease → `FinalizeRecoveryOrchestrator.plan` → `AuthorityOrchestrator.finalizeSession` → lease mark + queue cleanup.
- `VotingSessionLifecycleService` and `DeadSessionRecoveryService` delegate to pipeline only (no direct orchestrator / no parallel `_authority` path).

## Step 2 — Dead Runtime Path Elimination

See `docs/LEGACY_REMOVAL_AUDIT.md`.

**Removed:** `voting_match_center/`, `MainNavigation`, `MatchDataManager`, `EaglesResultsPanel`, `EagleVotingCubit` (+ state), `_CrowdEagleSync`.

**UX:** No-session stadium shows `_SquadPreviewWhenNoMatchSession` (squad cards, no legacy vote).

## Step 3 — Subscription Topology Reduction

| Before | After |
|--------|-------|
| `MatchVotingCubit` + `VotingSessionLifecycleService` both `watchActiveSession` | **One** session stream (`MatchVotingCubit`) |
| Lifecycle stream id `votingLifecycleSessionStream` | Removed — `notifyActiveSession` feed |

Added `subscription_topology_report.dart` (debug/profile graph).

## Step 4 — Runtime Decision Compression

Added `runtime_policy_matrix.dart` — `CrowdRuntimePhase` reducer from session + infrastructure signals.

## Step 5 — Memory & Lifecycle Hardening

Added `runtime_memory_audit.dart` (debug/profile): stream audit snapshot, queue depth, orphan warnings.

`StreamLifecycleAudit.snapshot()` added for topology reports.

## Step 6 — Production Surface Isolation

- `ProductionSurfaceGate` — ops dashboard requires `kDebugMode` + `VerificationSandboxGuard`.
- `ProductionOpsDashboardPage` gated at init.

## Step 7 — Firebase Surface Minimization

Documented in `docs/firebase_surface_audit.md` — active vs deprecated paths, heavy-read risks.

## Step 8 — Operational Ownership

Documented in `docs/runtime_ownership_matrix.md`.

## Findings summary

| Area | Finding |
|------|---------|
| Duplicate orchestration | **Resolved** — single pipeline |
| Subscriptions | **−1** RTDB listener on fan crowd mount |
| Removed paths | **~11** dart files + unreachable nav |
| Memory leaks | No new leaks; audit tooling added |
| Firebase reads | Admin bundle watch remains main risk |
| Technical debt | `CrowdRepository` deprecated but required; MOTM admin path retained |
| Launch blockers | None from Phase D gates; monitor admin broad reads under load |

## Remaining before public launch

1. Load-test admin CMS + fan tab concurrently (bundle watch overlap).
2. Confirm `best_player` fallback can be dropped per club migration.
3. Deploy rules aligned with `active_match` path (not draft `sessions/` snippet only).
