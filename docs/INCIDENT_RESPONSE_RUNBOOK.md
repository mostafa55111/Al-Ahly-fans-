# Incident Response Runbook — Crowd / Match Voting

**Severity guide:** S1 = voting broken for all · S2 = degraded · S3 = cosmetic

---

## S1 — Voting unavailable

| Check | Remediation |
|-------|-------------|
| Active session published? | Owner republish after squad lock |
| `crowd_feature_freeze` true? | Disable freeze via Remote Config if intentional pause ended |
| Firebase outage | Status page; enable graceful degradation; comms to fans |
| Rules denial / unauthorized write | Stop ops scripts; audit `owner_emails` |

**Communication:** In-app stays on last cached squad; post social update if outage >5 min.

---

## S1 — Duplicate finalize / duplicate vote reports

1. Confirm single finalize owner (`RuntimeOwnerGuard` / lease).
2. Inspect session doc — `awardsFinalized` must flip once.
3. Votes: immutable transaction path only; legacy `votes/{matchId}` must stay OFF.
4. If duplicate detected: freeze new votes via Remote Config; engineering post-mortem.

---

## S2 — Reconnect storm

**Symptoms:** CPU heat, battery drain, fan complaints “app spinning”.

- Expected: exponential backoff on vote subscription.
- Action: no new feature flags; reduce HoF full timeline hydration (`HallOfFameBudgetPolicy`).
- Monitor: `ReconnectCostProfile`, active listener count (`StreamLifecycleAudit`).

---

## S2 — Delayed finalize

1. Check lease + `ProductionFinalizePipeline` logs (Crashlytics incidents).
2. Owner disconnect mid-finalize: reopen CMS; pipeline should recover via `DeadSessionRecoveryService`.
3. Do not manually write award docs unless engineering directs (shard integrity).

---

## S2 — Partial shard writes

- Aggregation may lag; HoF shows last good snapshot.
- `AggregationCostGuard` may throttle — wait 2 min before retry.
- Escalate if monthly/season totals diverge from match sum.

---

## S2 — Firebase slow / read budget exceeded

- `ReadBudgetGuard` surfaces exceeded counts in debug economics report.
- Mitigation: fan stays on crowd tab; disable ops dashboard on low-end devices.
- Remote Config: `crowd_runtime_lock` if runaway reads detected.

---

## S3 — Cloudinary / thumbnail slow

- Progressive card images fall back — no user action.
- Owner CMS still functional.

---

## Rollback procedure

1. **Config rollback** (preferred): Remote Config previous template + `crowd_feature_freeze=true`.
2. **Binary rollback**: store release only; never mid-session without owner sign-off.
3. **Data rollback**: forbidden without backup plan — awards are append-only.

---

## Local authority fallback

**When:** Cloud Functions / remote authority unreachable >3 min during finalize window.

**How:**

1. Ops lead approves local execution mode.
2. `CrowdAuthorityConfigService` → local orchestration (pre-configured).
3. Log incident id in `ProductionIncidentStore`.
4. Reconcile when remote authority returns — compare lease timestamps.

---

## Post-incident

- File entry in `ProductionIncidentLogger` / Crashlytics.
- Update `PHASE_G` rehearsal notes if new failure mode found.
- Twin-repo parity check if hotfix applied.
