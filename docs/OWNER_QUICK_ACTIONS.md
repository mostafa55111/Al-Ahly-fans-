# Owner Quick Actions — Match Day

One-page reference for the **owner account** (email whitelist).

---

## Start match voting

1. Login → Profile → **إدارة الجمهور**
2. CMS → load kit → verify lineup + bench
3. **Publish session** → confirm countdown (~1h)
4. Stay available until countdown ends

---

## Monitor live

| Action | Where |
|--------|--------|
| See squad on pitch | Crowd tab (fan app) — read-only for owner OK |
| Session status | CMS session panel |
| Countdown | CMS + fan countdown overlay |

**Avoid:** second publish, legacy admin nodes, sandbox/load-test tools in release.

---

## If fans report issues

| Problem | Quick fix |
|---------|-----------|
| Can't vote | Re-check `votingEnabled`; session published? |
| Wrong player on pitch | Fix lineup in CMS **before** publish; republish only if session not started |
| App slow | Normal under load; don't toggle experimental flags |

---

## End of hour

1. Wait for auto finalize (or CMS finalize when countdown expired)
2. Confirm **awards finalized** badge
3. Check **Hall of Fame** tab for new match / period winners
4. Sign out on shared tablets

---

## Emergency buttons (conceptual)

| Situation | Action |
|-----------|--------|
| Need to pause voting | Remote Config `crowd_feature_freeze` (engineering) |
| Finalize stuck | Close/reopen CMS once; then incident runbook |
| Wrong session published | Do **not** delete shards; call engineering |

---

## TTMA target (rehearsal)

**Time To Match Active:** login → publish < **5 min** in rehearsal; log interruptions in `OwnerMatchdayProtocol`.

---

## Contacts

- Engineering: incident channel + `INCIDENT_RESPONSE_RUNBOOK.md`
- Full workflow: `MATCHDAY_OPERATIONS_RUNBOOK.md`
