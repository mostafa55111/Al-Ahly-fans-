# Match Day Operations Runbook

**Audience:** Club owner / match-day operator  
**Apps:** Zamalekawy · Gomhor Al Ahly (same workflow, club-specific Firebase paths)

---

## Before kickoff (T−60 min)

1. Sign in with **owner email** (whitelist only — not RTDB `admins/`).
2. Open **Stadium CMS** from Profile → إدارة الجمهور.
3. Load tactical kit; verify **lineup + bench** on pitch preview.
4. Confirm server time sync (Egypt authority) — countdown must match intent.
5. **Publish session** only when squad is final; note `sessionId` in ops log.
6. Run mental checklist: legacy voting OFF, experimental sandbox OFF (release builds).

## During voting (live hour)

| Signal | Action |
|--------|--------|
| Fans cannot vote | Check session `votingEnabled`, network, Remote Config freeze |
| Countdown stuck | Refresh CMS; verify `closesAt` / server time |
| Spike in reconnects | Expect lazy vote resubscribe; do not open second CMS tab |
| Read budget warnings (debug) | Reduce HoF tab churn; avoid ops dashboard on fan devices |

**Do not:** edit votes, enable legacy routes, run load-test injectors on production paths.

## Delay scenarios

- **Countdown not expiring:** confirm server time; if drift >30s, pause new publishes and contact engineering.
- **Finalize not starting:** check lease holder in ops logs; only one finalize owner (`ProductionFinalizePipeline`).
- **Partial results visible:** expected mask during live voting; full percentages after finalize only.

## Reconnect storms

- Fans: app backgrounds/resumes — votes queue via immutable transaction (no duplicate vote).
- Owner: stay on single device; avoid republishing session.
- If Firebase latency elevated: enable cost guard awareness; defer non-critical CMS refreshes.

## Finalize failure

1. Verify session `awardsFinalized` in CMS.
2. If app killed mid-finalize: reopen app — recovery drill replays queue (see `production_recovery_drill.dart`).
3. If lease conflict: wait 30s; retry from CMS **once** (no double finalize).
4. Escalate if shard aggregation incomplete — see Incident Response Runbook.

## Slow Firebase

- Symptoms: delayed lineup, sluggish vote cast ACK.
- Actions: reduce parallel listeners; avoid opening Production Ops + Crowd on same device; confirm club shard paths healthy.

## Image / Cloudinary pressure

- Card thumbnails may degrade to placeholder — acceptable under load.
- Do not force full-resolution prefetch during match hour.

## Rollback

Use **Safe Rollback Coordinator** (deployment) only with engineering approval:

1. Remote Config: tighten `crowd_runtime_lock` / `crowd_feature_freeze`.
2. Do not revert app binary during active session without comms plan.

## Local authority fallback

Use only when backend authority unreachable **and** ops approves:

- `AuthorityOrchestrator` local mode (configured via `CrowdAuthorityConfigService`).
- Document start/end times; reconcile when cloud authority returns.

---

## Post-match (T+15 min)

1. Verify **closure** in CMS (`awardsFinalized`).
2. Open **Hall of Fame** — monthly/season winners refreshed.
3. Record TTMA + mistakes in owner protocol rehearsal (debug) / ops log (prod).
4. Close operations — sign out owner session on shared devices.
