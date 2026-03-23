# 🧪 دليل الاختبار والتكامل - تطبيق جمهور الأهلي

## 📋 اختبار جلب البيانات من Football API

### 1. اختبار الاتصال بـ Football API

#### الخطوات:
1. افتح التطبيق وانتقل إلى شاشة "مركز المباريات"
2. تحقق من ظهور المباريات القادمة
3. تأكد من عرض معلومات صحيحة (الفريقان، التاريخ، الملعب)

#### النتائج المتوقعة:
```
✅ تحميل المباريات من Football API بنجاح
✅ عرض بيانات دقيقة وحديثة
✅ معالجة الأخطاء بشكل صحيح
```

#### معالجة الأخطاء:
```dart
// إذا فشل Football API، سيتم الرجوع تلقائياً إلى TheSportDB
// لا حاجة لتدخل يدوي
```

---

## 🎬 اختبار تشغيل المباريات الحية

### 2. اختبار حالة المباراة الحية

#### الخطوات:
1. انتظر بدء مباراة حقيقية للأهلي
2. راقب تحديث حالة المباراة في التطبيق
3. تحقق من تغيير الحالة من "مجدولة" إلى "جارية"

#### البيانات المراقبة:
- **الحالة:** SCHEDULED → IN_PLAY → FINISHED
- **الوقت:** تحديث كل 30 ثانية
- **النتيجة:** تحديث النتيجة الحية

#### الأكواد المسؤولة:
```dart
// lib/core/services/match_data_manager.dart
void startMatchMonitoring({Duration checkInterval = const Duration(seconds: 30)})

// lib/features/voting_match_center/presentation/pages/match_center_screen.dart
void _initializeMatchMonitoring()
```

---

## 🗳️ اختبار التكامل بين نهاية المباراة والتصويت

### 3. اختبار التصويت التلقائي عند انتهاء المباراة

#### السيناريو:
```
1. المباراة جارية (IN_PLAY)
   ↓
2. انتهاء المباراة (FINISHED)
   ↓
3. ظهور إشعار بانتهاء المباراة
   ↓
4. تفعيل نظام التصويت تلقائياً
   ↓
5. عرض خيار الانتقال إلى تبويب التصويت
```

#### الخطوات:
1. انتظر انتهاء مباراة حقيقية
2. سيظهر إشعار SnackBar بالرسالة:
   ```
   "انتهت المباراة! يمكنك الآن التصويت لرجل المباراة"
   ```
3. اضغط على "صوّت الآن"
4. ستنتقل تلقائياً إلى تبويب التصويت

#### الأكواد المسؤولة:
```dart
// Trigger voting after match ends
void _triggerVotingAfterMatch(Map<String, dynamic> match)

// Save finished match data
void _saveFinishedMatchData(Map<String, dynamic> match)

// Enable voting automatically
Future<void> _enableVotingForMatch(Map<String, dynamic> match)
```

---

## 📊 اختبار جلب البيانات - حالات الاختبار

### 4. حالات الاختبار الشاملة

#### حالة 1: جلب المباريات القادمة
```dart
Test: getNextMatches()
Expected Output:
{
  'homeTeam': 'Al Ahly',
  'awayTeam': 'Opponent',
  'utcDate': '2026-03-15T20:00:00Z',
  'status': 'SCHEDULED',
  'competition': 'Egyptian Premier League',
  'venue': 'Cairo International Stadium'
}
```

#### حالة 2: جلب نتائج المباريات السابقة
```dart
Test: getLastMatches()
Expected Output:
{
  'homeTeam': 'Al Ahly',
  'awayTeam': 'Opponent',
  'score': {'fullTime': {'home': 2, 'away': 1}},
  'status': 'FINISHED'
}
```

#### حالة 3: جلب إحصائيات الفريق
```dart
Test: getTeamStats()
Expected Output:
{
  'name': 'Al Ahly',
  'founded': 1925,
  'venue': 'Cairo International Stadium',
  'website': 'www.alahly.com',
  'area': 'Egypt'
}
```

#### حالة 4: جلب قائمة اللاعبين
```dart
Test: getTeamPlayers()
Expected Output: [
  {
    'name': 'Mohamed El-Shenawy',
    'position': 'Goalkeeper',
    'nationality': 'Egypt',
    'shirtNumber': 1
  },
  ...
]
```

---

## 🔄 اختبار التصويت

### 5. اختبار نظام التصويت

#### خطوات الاختبار:
1. **عرض قائمة اللاعبين:**
   ```
   ✓ تحميل اللاعبين من Firebase
   ✓ عرض صورهم وأسماؤهم
   ✓ ترتيب عشوائي أو حسب الأداء
   ```

2. **التصويت:**
   ```
   ✓ اضغط على صورة اللاعب
   ✓ ظهور نافذة تأكيد
   ✓ تسجيل التصويت في Firebase
   ```

3. **تحديث النتائج:**
   ```
   ✓ تحديث عدد الأصوات في الوقت الفعلي
   ✓ عرض أفضل لاعب بناءً على الأصوات
   ✓ حفظ إحصائيات التصويت
   ```

#### الأكواد المسؤولة:
```dart
// Submit vote
Future<bool> submitVote(String playerId, String playerName)

// Get voting results
Future<Map<String, dynamic>> getVotingResults(String matchId)

// Get man of the match
Future<Map<String, dynamic>?> getManOfTheMatch(String matchId)
```

---

## 🧬 اختبار التكامل الكامل

### 6. سيناريو الاختبار الشامل

#### السيناريو:
```
الخطوة 1: فتح التطبيق
├─ ✓ تحميل المباريات القادمة
├─ ✓ عرض معلومات المباراة الأولى
└─ ✓ تحديث الحالة كل 30 ثانية

الخطوة 2: مراقبة المباراة الحية
├─ ✓ تغيير الحالة من SCHEDULED إلى IN_PLAY
├─ ✓ عرض تحديثات النتيجة الحية
└─ ✓ تحديث معلومات المباراة

الخطوة 3: انتهاء المباراة
├─ ✓ تغيير الحالة إلى FINISHED
├─ ✓ ظهور إشعار بانتهاء المباراة
├─ ✓ تفعيل نظام التصويت تلقائياً
└─ ✓ حفظ نتيجة المباراة

الخطوة 4: التصويت
├─ ✓ الانتقال إلى تبويب التصويت
├─ ✓ عرض قائمة اللاعبين
├─ ✓ التصويت لأفضل لاعب
└─ ✓ تحديث النتائج في الوقت الفعلي

الخطوة 5: عرض النتائج
├─ ✓ عرض أفضل لاعب (نسر المباراة)
├─ ✓ عرض إحصائيات التصويت
└─ ✓ حفظ البيانات في Firebase
```

---

## 🔧 أدوات الاختبار

### 7. أدوات مساعدة للاختبار

#### استخدام Firebase Emulator:
```bash
# تثبيت Firebase CLI
npm install -g firebase-tools

# بدء Emulator
firebase emulators:start

# اختبار البيانات محلياً
```

#### استخدام Postman لاختبار APIs:
```
1. Football API:
   GET https://api.football-data.org/v4/teams/674/matches
   Headers: X-Auth-Token: 8c16585903c335eb82435488feac3937

2. TheSportDB API:
   GET http://www.thesportsdb.com/api/v1/json/3/eventsnext.php?id=138995
```

#### استخدام Flutter DevTools:
```bash
# بدء DevTools
flutter pub global activate devtools
devtools

# فتح التطبيق مع DevTools
flutter run --observatory-port=8888
```

---

## 📈 معايير النجاح

### 8. معايير التحقق من النجاح

| المعيار | الحالة | الملاحظات |
|--------|--------|----------|
| **جلب البيانات** | ✅ | بيانات دقيقة وحديثة |
| **تحديث الحالة** | ✅ | تحديث كل 30 ثانية |
| **إشعارات** | ✅ | ظهور في الوقت المناسب |
| **التصويت** | ✅ | تسجيل صحيح في Firebase |
| **الأداء** | ✅ | لا تأخير في الاستجابة |
| **الأمان** | ✅ | حماية البيانات الحساسة |

---

## 🐛 معالجة الأخطاء

### 9. سيناريوهات الأخطاء

#### خطأ 1: فشل الاتصال بـ Football API
```dart
// الحل: الرجوع تلقائياً إلى TheSportDB
if (footballMatches.isEmpty) {
  return await _getNextMatchesFromTheSportDB();
}
```

#### خطأ 2: تأخر في تحديث البيانات
```dart
// الحل: زيادة تكرار الفحص
startMatchMonitoring(checkInterval: Duration(seconds: 15));
```

#### خطأ 3: فشل التصويت
```dart
// الحل: إعادة محاولة التصويت مع رسالة خطأ
try {
  await submitVote(playerId, playerName);
} catch (e) {
  showErrorDialog('فشل التصويت. حاول مرة أخرى');
}
```

---

## 📝 قائمة التحقق النهائية

### 10. قائمة التحقق قبل الإطلاق

- [ ] تم اختبار جلب البيانات من Football API
- [ ] تم اختبار جلب البيانات من TheSportDB (كبديل)
- [ ] تم اختبار تحديث حالة المباراة الحية
- [ ] تم اختبار الإشعارات عند انتهاء المباراة
- [ ] تم اختبار نظام التصويت
- [ ] تم اختبار تحديث نتائج التصويت الحية
- [ ] تم اختبار حفظ البيانات في Firebase
- [ ] تم اختبار الأداء والسرعة
- [ ] تم اختبار معالجة الأخطاء
- [ ] تم اختبار على أجهزة حقيقية

---

## 📞 الدعم والمساعدة

### في حالة مواجهة مشاكل:

1. **تحقق من API Keys:**
   - Gemini API Key في `main.dart`
   - Football API Key في `sports_api_service.dart`

2. **تحقق من Firebase:**
   - تفعيل Realtime Database
   - تفعيل Cloud Storage
   - تفعيل Authentication

3. **تحقق من الاتصال:**
   - تأكد من الاتصال بالإنترنت
   - تحقق من حالة APIs الخارجية

4. **راجع السجلات:**
   ```bash
   flutter logs
   ```

---

**✨ تم إعداد جميع أدوات الاختبار والتكامل بنجاح ✨**

🦅 **الأهلي فوق الجميع** 🦅
