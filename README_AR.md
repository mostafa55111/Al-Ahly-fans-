# 🦅 تطبيق جمهور الأهلي - نادي القرن

تطبيق جوال احترافي وفخم لجمهور نادي الأهلي المصري، يجمع بين أحدث التقنيات والتصميم الراقي.

## 📱 المميزات الرئيسية

### 🎬 ركن الريلز الأهلاوية
- مقاطع فيديو قصيرة بتجربة شبيهة بـ TikTok
- إمكانية الإعجاب والتعليق والمشاركة
- تحميل الفيديوهات
- واجهة احترافية وسلسة

### ⚽ مركز المباريات
- عرض المباريات القادمة والنتائج السابقة
- بيانات حية من TheSportDB API
- معلومات التشكيل الرسمي
- إشعارات لحظية عند تسجيل الأهداف

### 🗳️ نظام التصويت والتفاعل
- تصويت لرجل المباراة
- التنبؤ بالتشكيلة المثالية
- نسر الشهر
- نتائج التصويت الحية

### 👤 الملف الشخصي والجمهور
- نظام تسجيل دخول آمن عبر Firebase
- بطاقة المشجع مع نقاط الولاء
- إحصائيات التفاعل
- الإنجازات والشارات

### 🤖 مساعد ذكي
- إجابات ذكية عن أسئلة النادي
- معلومات عن اللاعبين والإحصائيات
- تحليل الأداء
- يعمل بـ Google Generative AI (Gemini)

### 🛍️ المتجر الرسمي
- بيع قمصان النادي والمنتجات الرسمية
- عرض المنتجات بصور عالية الجودة
- نظام الدفع الآمن

### 🚌 حجز الرحلات
- حجز رحلات للملعب
- معلومات الأسعار والمواعيد
- نظام الحجز الموثوق

---

## 🎨 الهوية البصرية

### الألوان الفخمة
- **الأسود الفاحم** (#0A0A0A) - الخلفية الأساسية
- **الذهبي الساطع** (#D4AF37) - الزخارف والتفاصيل
- **الأحمر الملكي** (#D32F2F) - العناصر التفاعلية والشعارات

### الخطوط
- **Cairo** - خط عربي فخم وحديث
- **Tajawal** - خط عربي بديل

### النمط الهندسي
- زخارف إسلامية/عربية مع نسور مدمجة
- تصميم تجريدي يعطي شعوراً بالأصالة

---

## 🛠️ المتطلبات التقنية

### البيئة
- **Flutter**: 3.0.0 أو أحدث
- **Dart**: 3.0.0 أو أحدث
- **Android SDK**: API 21 أو أحدث
- **Xcode**: 14.0 أو أحدث (iOS)

### الخدمات الخارجية
- **Firebase**: للمستخدمين والبيانات
- **TheSportDB**: لبيانات المباريات
- **Google Generative AI**: للمساعد الذكي
- **Cloudinary**: لتخزين الصور والفيديوهات

---

## 🚀 البدء السريع

### 1. استنساخ المشروع
```bash
git clone <repository-url>
cd ahly-fans-app
```

### 2. تثبيت الـ Dependencies
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### 3. إعداد Firebase
1. أنشئ مشروع في [Firebase Console](https://console.firebase.google.com)
2. حمّل `google-services.json` وضعه في `android/app/`
3. فعّل الخدمات المطلوبة (Auth, Firestore, Storage, Messaging)

### 4. إضافة Google Generative AI API Key
1. اذهب إلى [Google AI Studio](https://makersuite.google.com/app/apikey)
2. انسخ المفتاح
3. أضفه في `main.dart` أو ملف `.env`

### 5. تشغيل التطبيق
```bash
flutter run
```

---

## 📁 هيكل المشروع

```
ahly-fans-app/
├── lib/
│   ├── main.dart                          # نقطة البداية
│   ├── firebase_options.dart              # إعدادات Firebase
│   ├── core/
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Theme الفخم
│   │   ├── services/
│   │   │   ├── firebase_service.dart
│   │   │   ├── sports_api_service.dart
│   │   │   ├── ai_assistant_service.dart
│   │   │   ├── cloudinary_service.dart
│   │   │   └── firebase_notification_service.dart
│   │   ├── navigation/
│   │   │   └── main_navigation.dart
│   │   ├── di/
│   │   │   └── service_locator.dart
│   │   ├── models/
│   │   │   └── badge_model.dart
│   │   └── animations/
│   │       └── advanced_animations.dart
│   └── features/
│       ├── profile/
│       │   ├── data/
│       │   │   └── models/
│       │   │       └── user_model.dart
│       │   └── presentation/
│       │       └── pages/
│       │           ├── splash_screen.dart
│       │           ├── login_screen.dart
│       │           └── profile_screen.dart
│       ├── reels/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │       └── pages/
│       │           └── reels_screen.dart
│       ├── voting_match_center/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │       └── pages/
│       │           ├── match_center_screen.dart
│       │           └── predict_win_screen.dart
│       ├── marketplace/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │       └── pages/
│       │           └── marketplace_screen.dart
│       ├── bus_booking/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │       └── pages/
│       │           └── bus_booking_screen.dart
│       ├── admin_panel/
│       │   └── presentation/
│       │       └── pages/
│       │           └── admin_dashboard_screen.dart
│       └── search/
│           └── presentation/
│               └── pages/
│                   └── ai_chat_screen.dart
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── gold_pattern.png
│   │   └── eagle_watermark.png
│   ├── icons/
│   ├── animations/
│   └── fonts/
├── android/
├── ios/
├── web/
├── windows/
├── linux/
├── macos/
├── pubspec.yaml
├── pubspec.lock
├── SETUP_AND_BUILD_GUIDE.md
├── ERRORS_AND_FIXES.md
└── todo.md
```

---

## 🔧 الأوامر المهمة

### تطوير
```bash
# تشغيل التطبيق
flutter run

# تشغيل مع تحليل الأداء
flutter run --profile

# تشغيل مع تتبع الأداء
flutter run --trace-startup
```

### الاختبار
```bash
# تشغيل الاختبارات
flutter test

# تشغيل الاختبارات مع التغطية
flutter test --coverage
```

### البناء
```bash
# بناء APK
flutter build apk --release

# بناء App Bundle
flutter build appbundle --release

# بناء iOS
flutter build ios --release

# بناء الويب
flutter build web --release
```

### الصيانة
```bash
# تنظيف المشروع
flutter clean

# تحديث الـ Dependencies
flutter pub upgrade

# فحص الأخطاء
flutter analyze

# تنسيق الأكواد
dart format lib/
```

---

## 📊 معلومات المشروع

| المعلومة | القيمة |
|---------|--------|
| اسم التطبيق | جمهور الأهلي - نادي القرن |
| الإصدار | 1.0.0 |
| الحالة | قيد التطوير |
| اللغة الأساسية | Dart/Flutter |
| المعمارية | Clean Architecture |
| إدارة الحالة | Bloc/Provider |
| قاعدة البيانات | Firebase |
| API الخارجية | TheSportDB, Google Generative AI |

---

## 🎯 الأهداف المستقبلية

### المرحلة القادمة
- [ ] دعم اللغة الإنجليزية
- [ ] تحسين الأداء والسرعة
- [ ] إضافة المزيد من الميزات الاجتماعية
- [ ] نظام التعليقات المتقدم
- [ ] غرف الدردشة المباشرة

### المرحلة البعيدة
- [ ] تطبيق ويب كامل
- [ ] تطبيق سطح المكتب
- [ ] نظام الدفع المتقدم
- [ ] التكامل مع وسائل التواصل الاجتماعي
- [ ] نظام الإشعارات المتقدم

---

## 🐛 الأخطاء المعروفة والحلول

### خطأ: "Firebase not initialized"
**الحل:** تأكد من وجود `google-services.json` في `android/app/`

### خطأ: "Assets not found"
**الحل:** تشغيل `flutter clean` و `flutter pub get`

### خطأ: "Build failed"
**الحل:** تشغيل `flutter clean` ثم `flutter run`

للمزيد من الأخطاء والحلول، اطلع على [ERRORS_AND_FIXES.md](ERRORS_AND_FIXES.md)

---

## 📚 الموارد والمراجع

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [TheSportDB API](https://www.thesportsdb.com/api.php)
- [Google Generative AI](https://ai.google.dev/)

---

## 📝 الترخيص

هذا المشروع مملوك لنادي الأهلي المصري.

---

## 👥 الفريق

- **التطوير:** فريق تطوير التطبيقات
- **التصميم:** فريق التصميم
- **الاختبار:** فريق الجودة

---

## 📞 التواصل والدعم

للإبلاغ عن الأخطاء أو الاقتراحات:
- البريد الإلكتروني: support@ahly.com
- الموقع الرسمي: https://www.alahly.com
- وسائل التواصل: @AlAhlyOfficial

---

## ✨ شكر وتقدير

شكراً لجميع المساهمين والمختبرين الذين ساعدوا في تطوير هذا التطبيق.

---

**تم تطوير هذا التطبيق بـ ❤️ لجمهور الأهلي الوفي**

🦅 **الأهلي فوق الجميع** 🦅
