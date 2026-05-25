# Launch Checklist — Crowd / Match Votes

## Pre-staging

- [ ] Separate Firebase projects: dev / staging / production
- [ ] RTDB rules reviewed (`lib/features/crowd/firebase_phase7_rules_snippet.txt`)
- [ ] Cloud Functions deployed to staging
- [ ] Remote Config keys seeded (see playbook)
- [ ] Owner emails configured per environment
- [ ] Crashlytics enabled on release builds

## Staging validation

- [ ] Build: `CROWD_ENV=staging`, `RELEASE_CHANNEL=internal`
- [ ] Staging banner visible in debug
- [ ] Production Ops quick suite passes (sandbox IDs only)
- [ ] Go-live score ≥ controlled_launch threshold
- [ ] Device validation profiles run (low-end + weak network)
- [ ] Hybrid shadow: zero mismatches on test session
- [ ] Reconnect storm stabilization ≥ 80%
- [ ] Cost guard stays below `high` under load test

## Production gates

- [ ] `crowd_env_lock=production` in production RC
- [ ] `release_channel=production` for store builds
- [ ] Verification dashboard **hidden** (production channel)
- [ ] `crowd_authority_mode` promoted intentionally (local → remote)
- [ ] No sandbox sessions in production RTDB paths
- [ ] Rollback flags documented and tested once in staging

## Post-launch (first 24h)

- [ ] Crashlytics: no critical finalize spike
- [ ] Incident store: no unacknowledged critical incidents
- [ ] Firebase billing: reads/writes within budget
- [ ] Local fallback rate acceptable
- [ ] Owner on-call has playbook link

## Mass event readiness

- [ ] Go-live classification `mass_event_ready` or owner sign-off
- [ ] Shard skew < 35% under synthetic load
- [ ] Emergency RC switches tested without app update
