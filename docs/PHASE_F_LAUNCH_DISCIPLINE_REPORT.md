# Phase F — Product Lock & Launch Discipline Report

**Date:** 2026-05-19  
**Repos:** `zamalekawy`, `gomhor_alahly_v2` (mirrored)

## Gate status

| Check | Result |
|-------|--------|
| `flutter analyze lib` | **0 issues** |
| `flutter test test/features/crowd/` | **126/126 GREEN** |

---

## Launch contract

### SUPPORTED (Launch Candidate)

- 1 vote / user / session (immutable transaction)
- 1h voting session + auto finalize at `closesAt`
- Monthly winner by total votes
- Season winner by total votes
- Owner-only CMS (`owner_emails` whitelist)
- Egypt server-time authority

### NOT SUPPORTED BEFORE LAUNCH

- Vote edits
- Reactions persistence
- Public chat
- Live vote percentages (fan mask during live voting)
- Public admin roles (RTDB `admins/` is not owner gate)
- Custom user tournaments
- Multi-match voting
- Realtime leaderboards

Activation attempts → `LaunchContract.warnUnsupported()` (debug).

---

## Product surface lock (Step 1)

`product_surface_registry.dart` — **14** production surfaces:

| Category | Surfaces |
|----------|----------|
| PUBLIC | CrowdScreen, Match Stadium Voting, Hall Of Fame, Countdown, Result Overlay |
| OWNER | Stadium CMS, Card Library, Session Control, Production Ops (debug only) |
| INTERNAL | Finalize pipeline, Aggregation, Authority, Recovery, Economics |

Anything outside registry = legacy/experimental.

---

## Experimental isolation (Step 2)

`experimental_feature_guard.dart` — blocks in strict release:

- Legacy eagle / match center / streams
- Public arena MOTM preview
- Production ops sandbox, synthetic load, debug hooks

Wired: `CrowdAdminPage` ops card, `ProductionOpsDashboardPage`.

---

## Runtime ownership enforcement (Step 3)

`runtime_owner_guard.dart` — seeded matrix; wired:

- `ProductionFinalizePipeline` — finalize claim + in-flight detection
- `LazyVoteSubscriptionController` — reconnect orchestration

Debug: duplicate ownership, multi-finalize, duplicate reconnect violations.

---

## Production feature freeze (Step 5)

Remote Config keys (defaults in `CrowdDeploymentConfigService`):

- `crowd_feature_freeze`
- `crowd_runtime_lock`
- `crowd_disable_experimental`

`ProductionFeatureFreeze` bootstrapped via `ProductLaunchBootstrap`.

---

## Release mode (Step 9)

`release_mode_guard.dart`:

- Strict release hides debug ops
- Sandbox disabled
- Test session IDs blocked in release
- Staging owner email bypass **disabled** in `SecureOwnerResolver` strict release

---

## Admin security (Step 7)

`owner_security_audit.dart`:

- Owner email whitelist only (`OwnerAuthorityService`)
- No multi-admin expansion path in release
- No staging owner bypass in production release build

---

## Operational simplicity (Step 6)

`operational_complexity_report.dart` — classifies runtime as SAFE / RISKY / OVERCOMPLEX from subscriptions + ownership violations.

---

## Launch stability suite (Step 8)

`launch_stability_suite.dart` — 10 scenarios; logic gates run at bootstrap (debug) + unit tests.

---

## DO NOT BUILD BEFORE LAUNCH

1. Vote change / undo
2. Public reactions feed
3. In-app chat
4. Live leaderboard during voting
5. Multi-admin RBAC
6. Second concurrent match vote
7. User-created tournaments
8. New realtime surfaces beyond registry
9. Eagle / legacy voting revival
10. Feature flags that enable experimental paths in release

---

## Remaining launch blockers

1. Load test at target fan concurrency (Phase E simulator red zones)
2. Confirm `app_configs/owner_emails` populated in production Firebase
3. Set `crowd_feature_freeze=true` remotely when cutting release candidate
4. CMS `watchBundle` broad read — operational cost, not product scope

---

## Operational simplicity score

**RISKY → trending SAFE** after Phases D–F:

- Single finalize pipeline
- Single session stream
- Read budgets + launch contract
- Release guards on ops/sandbox

Target before public launch: **SAFE** under 10k concurrent with freeze flags on.
