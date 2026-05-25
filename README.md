# gomhor_alahly_clean_new

تطبيق Flutter لجمهور النادي الأهلي — ريلز، جمهور، ترحال، وربط Firebase.

## البدء

المشروع يعتمد Flutter و Firebase (Auth، Realtime Database، Messaging، وغيرها).

راجع [توثيق Flutter](https://docs.flutter.dev/) للإعداد العام.

---

## Cloud Functions — إشعار الترحال (`notifyTravelTrip`)

الكود في **`travel_system/index.js`** (codebase: `travel_system`)، المنطقة **`me-central1`**.

```bash
cd travel_system
npm install
cd ..
firebase deploy --only functions:travel_system
```

- الدالة قابلة للاستدعاء (Callable v2) اسمها **`notifyTravelTrip`**.
- العميل يستدعيها من `lib/features/travel/services/travel_cloud_push_trigger.dart` بنفس المنطقة `me-central1`.

---

## قاعدة البيانات اللحظية

- قواعد الأمان: `database.rules.json`
- ترحال الرحلات والشات: مسارات تحت `travel/trips/{tripId}/…` (انظر `lib/features/travel/data/travel_rtdb_paths.dart`).
