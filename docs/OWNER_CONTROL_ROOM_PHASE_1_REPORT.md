# Owner Control Room — Phase 1 Report

**Scope:** Owner-only Broadcast Match Control Room foundation (`Mostafa` / `owner_emails`). Not a public admin CRUD dashboard.

**Repos:** `gomhor_alahly_v2` ↔ `zamalekawy` (mirrored).

---

## Architecture

### Access

- `OwnerAuthorityService` + `OwnerGuard` + `SecureOwnerResolver`
- `AdminSurfaceIsolation` on `OwnerControlRoomPage`
- Non-owners: no FAB, no control room route (guard returns locked surface)

### Module layout

```
lib/features/crowd/owner_control_room/
├── control_room_shell/     OwnerControlRoomPage, ControlRoomTheme
├── card_repository/        CrowdCardRepository, upload, UI
├── voting_session_builder/ OwnerSessionBuilderPage
├── active_match_control/   OwnerActiveMatchPage
├── owner_runtime/          rules, route guard, lifecycle
├── widgets/                card tile, idle voting surface
└── models/                 OwnerCardRecord
```

---

## Repository architecture

**Primary RTDB path (per app, no sharing):**

```
crowd_card_repository/{ahly|zamalek}/cards/{cardId}/
  playerName, playerNumber, position
  imageUrl, thumbnailUrl, dominantColor
  createdAtServer, ownerUid, appId
```

**Legacy read fallback:** `cards/{club}/` for existing cards until migrated.

**Upload:** `OwnerCardUploadService` → Cloudinary full image + scaled thumbnail URL → `CrowdCardRepository.upsertCard`.

---

## Upload flow

1. Owner picks image (gallery)
2. Light client validation (`CardMediaValidator`)
3. Cloudinary upload
4. Thumbnail URL (`c_scale,w_320`)
5. Metadata write to `crowd_card_repository/{appId}/cards/`

UI: large cinematic panel in **المستودع** tab — not a tiny form.

---

## Owner isolation

- `FanAppIdentity.registryAppId` scopes repository stream and writes
- Ahly build never reads Zamalek cards (separate RTDB subtree)
- Upload stamps `ownerUid` from Firebase Auth

---

## Session lifecycle

**Owner:**

1. Upload cards (repository tab)
2. Add to pitch/bench from card tiles
3. Build session (formation, duration, preview)
4. **START SESSION** → `MatchVotesAdminCubit.publishVoting`

**System (unchanged production runtime):**

- Opens voting + countdown
- Auto close at `closesAt`
- Finalize pipeline + winner to Hall of Fame tab

**Rules (`OwnerSessionRules`):** single live session, ≥11 players, no duplicates, supported formations, duration 5–180 min.

---

## Fan experience (no session)

`MatchVotingIdleSurface` — premium idle (not error):

- Cinematic overlay on stadium
- «التصويت غير متاح حالياً»
- Optional last MVP card from `HallOfFameCubit`
- Countdown hidden (no active session)

Winners / Hall of Fame tab remains available.

---

## Countdown design

Existing `GlobalVoteCountdown` + Phase 5 broadcast calibration (club gradients, glass, readability).

---

## Security

| Action | Gate |
|--------|------|
| Open control room | `AdminSurfaceIsolation` |
| Upload / delete cards | Owner only |
| Create / close session | Owner only |
| Release bypass | None — `SecureOwnerResolver` + RTDB whitelist |

---

## Performance

- Reuses `MatchVotesAdminCubit` streams (no extra polling)
- Card repository: single RTDB `onValue` per app
- No new heavy blur stacks in control room chrome

---

## Entry points

| Surface | Target |
|---------|--------|
| Crowd FAB (owner) | `OwnerControlRoomPage` |
| Admin dashboard assistant button | `OwnerControlRoomPage` (still behind owner session on CMS) |

Legacy `CrowdAdminPage` / `StadiumCmsPage` remain in codebase for ops but fan FAB no longer opens them.

---

## QA

```bash
flutter analyze lib
flutter test test/features/crowd/
```

`test/features/crowd/owner_control_room/owner_control_room_test.dart`

**Manual:** non-owner sees no FAB; owner upload; per-app card isolation; session publish; auto close; idle screen; countdown when live.

---

## Phase 2 hints

- Firebase rules for `crowd_card_repository/*`
- Migrate legacy `cards/{club}` → new path
- Deep link registration with owner guard only
- Lineup drag on tactical preview in builder
