# Production Operations Playbook — Crowd / Match Votes

Operational guide for **staging → production** launches. No auto-deploy of rules or functions from this repo.

## Deploy order

1. **Staging Firebase project** — deploy RTDB rules (`firebase_phase7_rules_snippet.txt`), Cloud Functions (`functions/crowd_authority.js`), Remote Config defaults.
2. **Staging app build** — `--dart-define=CROWD_ENV=staging --dart-define=RELEASE_CHANNEL=internal`.
3. Run **Production Ops** quick suite + device validation on staging only.
4. **Production Firebase** — same artifacts, separate project; lock `crowd_env_lock=production`.
5. **Production app** — release build with `CROWD_ENV=production` and `RELEASE_CHANNEL=production` (default in release).
6. Enable `crowd_authority_mode=remote` via Remote Config canary; monitor incidents.

## Rollback flow (no app update)

| Switch (Remote Config) | Effect |
|------------------------|--------|
| `crowd_emergency_local_authority=true` | Force local finalize path |
| `crowd_disable_heavy_preload=true` | Skip heavy RTDB restore |
| `crowd_pause_background_hydration=true` | Defer background hydration |
| `crowd_reduce_thumbnail_promotion=true` | Throttle full card images |
| `crowd_disable_nesr_overlay=true` | Disable celebration overlay |

Client reads flags in `SafeRollbackCoordinator` on each bootstrap.

## Incident handling

- **Critical** incidents persist locally until acknowledged (`ProductionIncidentStore`).
- **High/Critical** also log to Firebase Crashlytics when enabled.
- Types: finalize failure, authority divergence, reconnect collapse, cloud timeout, recovery queue failure, media/memory pressure.

### Owner emergency checklist

1. Check Crashlytics + ops snapshot (`ProductionVerificationHub.operationalSnapshot()`).
2. If finalize failing: enable `crowd_emergency_local_authority`.
3. If RTDB pressure: enable preload/hydration pause flags.
4. If hybrid mismatch: keep `hybrid_shadow`, do not promote remote until aligned.
5. Replay recovery queue after outage: restart app or trigger admin session (bootstrap replays queue).

## Finalize recovery

1. Confirm session not already finalized in RTDB.
2. Check `authority_runtime/{club}/{matchId}` lease holder.
3. Retry via lifecycle service (bounded retries).
4. If remote down: `crowd_emergency_local_authority=true`.
5. Inspect `FinalizationAuditTrail` in debug snapshot.

## Reconnect storm

1. Watch `ReconnectStormReport.stabilizationRate`.
2. If degraded: reduce concurrent listeners, enable `crowd_pause_background_hydration`.
3. Users keep vote integrity; only non-critical streams defer.

## Cloud Function outage

1. Remote finalize fails → automatic local fallback (orchestrator).
2. Enable emergency local flag if Functions region impaired.
3. Record incident `cloudTimeout` / `finalizeFailure`.

## RTDB pressure response

1. Monitor `FirebaseCostGuard` level in ops snapshot.
2. Elevated: HoF preload reduced, thumbnail promotion throttled.
3. Critical: pause hydration + heavy preload via rollback flags.

## Environment separation

- **Never** run sandbox load/chaos against production (`VerificationSandboxGuard` + `CrowdEnvironmentResolver`).
- Staging owner emails: Remote Config `crowd_staging_owner_emails` (comma-separated).
- Production uses `app_configs/owner_emails` only.
