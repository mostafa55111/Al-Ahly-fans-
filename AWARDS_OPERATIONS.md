# تشغيل نظام الجوائز — جاهزية الإنتاج

## قبل الإطلاق

1. **Firebase Rules** — ادمج `firebase_awards_rules_snippet.txt` في `database.rules.json`.
2. **ساعة التطبيق** — عند التشغيل يُستدعى `AppClockBootstrap.initialize` (خادم Firebase + `Africa/Cairo`).
3. **نشر التصويت من CMS** — يضبط `openedAtServer` و`closesAtServer` تلقائياً.

## مسارات RTDB

| مسار | وصف |
|------|-----|
| `match_votes/{ahly\|zamalek}/active_match` | الجلسة الحية |
| `awards/{club}/matches/{year}/{matchId}` | لقطة فائز المباراة (append-only) |
| `awards/{club}/monthly/{yyyy-MM}` | فائز الشهر (مجموع الأصوات) |
| `awards/{club}/season/{yyyy}` | فائز الموسم |
| `player_awards/{club}/{playerId}` | تجميع اللاعب |

## التوقيت

- **قرارات الإغلاق والجوائز**: `closesAtServer` / `closedAtServer` من الخادم فقط.
- **عرض مصر**: `EgyptClock` (`Africa/Cairo`) + `EgyptServerTimeService.serverNowMs`.
- **لا تستخدم** `DateTime.now()` لإغلاق التصويت النهائي.

## التحقق

```bash
flutter test test/features/crowd/awards/
flutter analyze lib/features/crowd/awards lib/core/time
```

## المشروعان

نفس البنية تحت `lib/` في **zamalekawy** و **gomhor_alahly_v2**؛ الفرق: `FanAppIdentity` والمسارات/الأصول فقط.
