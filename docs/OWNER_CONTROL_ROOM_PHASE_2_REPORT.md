# Owner Control Room — Phase 2 Report (Matchday Broadcast Operations)

**Scope:** Operational polish only. No fan features, no `MatchVotingCubit` / vote runtime changes.

**Repos:** `gomhor_alahly_v2` ↔ `zamalekawy`.

---

## Operational philosophy

The owner panel should feel like a **broadcast control room**: fast, clear, calm control — not an engineering dashboard.

Two tabs only:
1. **المستودع** — card repository
2. **يوم المباراة** — unified operational surface

---

## Matchday flow

```
idle → preparing → live → closing → finalizing → completed
```

Resolved from **current session + server time** via existing `MatchVotesAdminCubit` stream — **no new streams**.

| Phase | Source |
|-------|--------|
| preparing | Session exists, voting disabled |
| live | `VotingSessionVisualState.live` |
| closing | endingSoon window |
| finalizing | closed, not finalized |
| completed | `awardsFinalized` |

---

## Module layout

```
matchday_operations/
├── matchday_timeline/     resolver + horizontal bar
├── session_preview/       static tactical preview
├── emergency_controls/    safe close, retry finalize, recovery
├── runtime_confidence/      session/finalize/authority/reconnect chips
├── broadcast_status/      top status strip
├── operational_surface/   main matchday layout
└── widgets/               confirmation sheet, controls, emergency panel
```

---

## Preview architecture

`MatchdaySessionPreview` — **static composition**:
- `StadiumFoundationSafeLayout`
- `TacticalFormationLayout`
- `FifaCardWidget` (premium/stadiumUltraMode)
- Bench rail + countdown chip (mock duration)

**No** `MatchVotingCubit`, **no** extra listeners, **no** polling.

Shows idle fan surface when lineup empty (no-session fallback preview).

---

## Start confirmation

`MatchdayStartConfirmationSheet` — broadcast-grade sheet:
- Formation, starters, bench, duration, readiness
- Button: **«بدء البث والتصويت»**

---

## Emergency safety

| Action | Behavior |
|--------|----------|
| Safe Close | `adminSetVotingEnabled(false)` only |
| Retry Finalize | `ProductionFinalizePipeline.run(trigger: owner_retry)` |
| Recovery Check | `DeadSessionRecoveryService` + queued replay |

**Never:** delete votes, override winner, parallel finalize paths.

All actions audit-tagged via `OwnerAuditLog.logEmergencyRollback`.

---

## Runtime confidence model

Five chips only:
- Session health
- Finalize health
- Uploads (Cloudinary)
- Authority mode
- Reconnect stability (`SocketPressureGuard`)

No raw logs or Firebase dumps.

---

## Timeline behavior

Horizontal cinematic bar with restrained glow on active node. Club colors via `ControlRoomTheme`.

---

## Performance notes

- Reuses single `MatchVotesAdminCubit` subscription from Phase 1
- Preview is stateless widgets from admin snapshot
- No shader masks, no heavy blur stacks added
- Server time read once per `BlocBuilder` frame (no Timer polling)

---

## QA

```bash
flutter analyze lib
flutter test test/features/crowd/
```

`test/features/crowd/owner_control_room/matchday_operations_test.dart`

**Manual:** owner-only access, preview matches lineup, safe close, no duplicate finalize, status/timeline accuracy.

---

## Phase 2 outcome

**Operational Maturity Layer** — owner matchday control without admin-heavy UI or fan-scope expansion.
