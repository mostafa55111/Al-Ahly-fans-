# Phase G — Real Production Dress Rehearsal Report

**Date:** 2026-05-19  
**Repos:** `zamalekawy`, `gomhor_alahly_v2` (mirrored)

## Gate status

| Check | Result |
|-------|--------|
| `flutter analyze lib` | **0 issues** (both repos) |
| `flutter test test/features/crowd/` | **134/134 GREEN** (+8 rehearsal tests) |

---

## Module: `lib/features/crowd/product_rehearsal/`

| Artifact | Purpose |
|----------|---------|
| `rehearsal_surface_gate.dart` | Dress rehearsal debug/staging only |
| `match_day_simulation_runner.dart` | 12-step match-day orchestration |
| `cold_start_audit.dart` | ELITE / GOOD / RISKY latency tiers |
| `launch_day_chaos_suite.dart` | 8 chaos scenarios, graceful degradation |
| `owner_matchday_protocol.dart` | Owner TTMA + mistakes log |
| `production_recovery_drill.dart` | 6 recovery drills |
| `release_build_audit.dart` | Release build sanity |
| `firebase_production_audit.dart` | Firebase pressure verdict |
| `soft_launch_gate.dart` | GO / NO-GO / conditional |
| `product_rehearsal_bootstrap.dart` | Debug dress-rehearsal runner |

Wired: `ProductLaunchBootstrap` → `ProductRehearsalBootstrap` (debug), cold-start hooks on deployment / production bootstrap / crowd screen / HoF load.

---

## Cold start metrics (rehearsal targets)

| Metric | Elite | Good | Risky |
|--------|-------|------|-------|
| `app_launch` | ≤800ms | ≤2000ms | >2000ms |
| `crowd_screen_hydration` | ≤800ms | ≤2000ms | >2000ms |
| `hof_first_render` | ≤800ms | ≤2000ms | >2000ms |
| `session_bootstrap` | ≤800ms | ≤2000ms | >2000ms |
| `image_preload_latency` | ≤800ms | ≤2000ms | >2000ms |

Recorded via `ColdStartAudit` when `RehearsalSurfaceGate.allowDressRehearsal`.

---

## Match-day simulation (12 steps)

1. owner login · 2. CMS open · 3. lineup · 4. bench · 5. publish · 6. fan joins · 7. votes · 8. reconnect storms · 9. background/resume · 10. countdown expiry · 11. finalize · 12. HoF refresh

Default path delegates reconnect/finalize to `LaunchStabilitySuite` logic gates.

---

## Reconnect & finalize survivability

- **Reconnect:** `LaunchDayChaosSuite` + stability `reconnectStorm` gate — no owner-guard violations.
- **Finalize:** single owner `ProductionFinalizePipeline` via `RuntimeOwnerGuard`; recovery drills cover kill-app / degraded network.
- **No duplicate vote/finalize:** enforced by existing immutable vote tx + finalize lease (Phases B–D); chaos wraps use `onFailure: () => true` for graceful degrade only.

---

## Firebase production audit

`FirebaseProductionAudit` reads: `FirebaseCostGuard`, `StreamLifecycleAudit`, `ReconnectCostProfile`, `ReadBudgetGuard`, `ProductionCostSurfaceReport`.

Verdicts: `acceptable` · `elevated` · `critical` (blocks soft launch if critical).

---

## Owner workflow

`OwnerMatchdayProtocol` — steps login → close operations; records **TTMA**, interruptions, mistakes, recovery notes.  
Runbooks: `docs/MATCHDAY_OPERATIONS_RUNBOOK.md`, `docs/INCIDENT_RESPONSE_RUNBOOK.md`, `docs/OWNER_QUICK_ACTIONS.md`.

---

## Chaos test outcomes (8 scenarios)

| Scenario | Expectation |
|----------|-------------|
| Firebase slow | Degrade, no crash |
| Reconnect storms | Backoff / guard OK |
| Delayed finalize | Lease path survives |
| Partial shard writes | Aggregation degrade |
| Cloudinary slow | Thumbnail fallback |
| App resume flood | Reconnect cap |
| Owner disconnect finalize | Recovery |
| RTDB transient disconnect | Graceful |

---

## Release audit status

Checks: no debug banners (strict release), sandbox off (release only), experimental off, legacy voting/routes/streams off, freeze config ready, launch contract defined.

---

## Soft launch recommendation

`SoftLaunchGate.evaluate()` / `evaluateWithRehearsal()`:

- Rehearsal-only checks skipped in release (`matchday`, `chaos`, `recovery`, `cold_start`).
- Release audit enforced when `ReleaseModeGuard.isStrictRelease`.

**Recommendation:** **CONDITIONAL GO** until first live match dress rehearsal with owner on staging + `crowd_feature_freeze` validated on Remote Config.

---

## Final launch blockers

| Blocker | Mitigation |
|---------|------------|
| Owner whitelist empty in prod | Populate `owner_emails` before match |
| `crowd_feature_freeze` not set for go-live | Enable via Remote Config when ready |
| Real 10k fan load untested | Run `ProductionVerificationHub` derby_peak on staging only |
| Shard skew under synthetic load | Monitor `AggregationCostGuard` match night |

---

## GO / NO-GO decision

| Decision | Rationale |
|----------|-----------|
| **GO (engineering)** | Analyze clean, 134 crowd tests green, rehearsal framework + runbooks in place |
| **NO-GO (public launch)** | Until owner staging rehearsal + production Remote Config freeze sign-off |

**Operational launch** = engineering GO + owner sign-off + soft launch gate `go` with `requireFreezeEnabled: true` on release build.

---

## Strict scope compliance

- No new fan features · no UI expansion · no new runtime layers
- Verification, rehearsal, operational hardening, launch discipline only
