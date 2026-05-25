# Owner Control Room — Phase 3 Report

## Operational speed + secure owner authentication

Phase 3 adds **real matchday execution speed** for the owner and **Firebase-backed privileged access** without hardcoded passwords in source.

---

## 1. Secure auth flow

| Component | Role |
|-----------|------|
| `OwnerLoginSurface` | Premium dark login UI — email + password, button «دخول غرفة التحكم» |
| `OwnerAuthService` | `signInWithEmailAndPassword` → whitelist via `SecureOwnerResolver` / `app_configs/owner_emails` |
| `OwnerSecureSession` | Stores UID + last activity in `flutter_secure_storage` (no password in code) |
| `OwnerControlRoomGate` | Login → privileged shell; revalidates on app resume |
| `OwnerSessionGuard` | Requires Firebase owner **and** active secure session for admin surfaces |

**Non-owner behavior:** silent redirect (no routes, FAB hidden for logged-in non-owners).

**Session security:** 12h inactivity timeout, secure logout clears storage + Firebase auth, `revalidateOnResume()` on gate lifecycle.

**Owner email:** validated against RTDB `app_configs/owner_emails` (e.g. `mostafareyad772@gmail.com`) — not hardcoded as sole gate.

---

## 2. Template architecture

**Path:** `owner_match_templates/{club}/{templateId}`

**Model:** `OwnerMatchTemplate` — formation, starters, bench, `createdAt`, `lastUsedAt`, `appId`.

**Services:**
- `OwnerMatchTemplateRepositoryRtdb` — watch / upsert / mark used
- `OwnerTemplateWriter` — snapshot current admin lineup to template

---

## 3. Quick launch flow

**Target:** template → preview → duration → START (< 30 seconds)

```
Owner picks template → QuickLaunchService.applyTemplate()
  → MatchVotesAdminCubit.applySessionTemplate()
  → MatchdaySessionPreview + LaunchValidationBanner
  → MatchdayStartConfirmationSheet (blocked if invalid)
  → publishVoting()
```

**UI:** `MatchdaySpeedPanel` on **يوم المباراة** tab.

---

## 4. Draft lifecycle

**Path:** `owner_session_drafts/{club}/{draftId}`

**States:** `draft` → `ready` → `live` → `archived`

**Model:** formation, lineup, bench, duration, optional notes.

**Shortcut:** «آخر مسودة» loads draft via `OperationalShortcuts.launchFromLatestDraft`.

---

## 5. Validation system

`LaunchValidator` (before broadcast):

- Exactly 11 starters (`y < 0.88`)
- Goalkeeper in starters (`GK`)
- No duplicate IDs or names
- Bench size ≤ 12
- Formation supported (via `OwnerSessionRules`)
- Card images present for all players
- No active duplicate session
- Duration bounds

Invalid → confirmation sheet disables «بدء البث والتصويت».

---

## 6. Operational shortcuts

| Shortcut | Action |
|----------|--------|
| آخر تشكيلة | `resumeWorkspace()` |
| نسخ الجلسة | `duplicateSession()` |
| آخر مسودة | apply draft + mark `live` |
| Rapid replacement | `replacePitchPlayerWithRegistry` (position preserved) |

---

## 7. Operational speed gains

| Before | After |
|--------|-------|
| Upload → pick → build → review → run | Pick template → quick preview → run |
| Manual lineup rebuild | Saved templates + drafts |
| Weak pre-flight checks | Full `LaunchValidator` gate |

**Estimated owner path:** ~15–25s with saved template (vs several minutes manual).

---

## 8. Security notes

- No plaintext password in repository
- No local fake auth / release bypass
- Single owner whitelist (RTDB), no multi-admin expansion
- Privileged state not cached without secure session record
- Fan voting / runtime / cubits unchanged

---

## 9. Launch workflow timing

1. Tap owner FAB (login if needed) — ~5s
2. Select template + apply — ~3s
3. Review preview + validation banner — ~5s
4. Confirm + publish — ~5–10s

**Total:** under 30s target with prepared template.

---

## Module layout

```
lib/features/crowd/owner_control_room/
├── owner_auth/
├── matchday_speed/
│   ├── saved_templates/
│   ├── quick_launch/
│   ├── session_drafts/
│   ├── rapid_replacements/
│   ├── launch_validation/
│   ├── operational_shortcuts/
│   └── widgets/
```

## QA

```bash
flutter analyze lib
flutter test test/features/crowd/
```
