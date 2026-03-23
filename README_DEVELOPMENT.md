# 🔴 تطبيق جمهور الأهلي - دليل التطوير

## 📱 نظرة عامة

تطبيق جوال احترافي لمشجعي نادي الأهلي يوفر تجربة اجتماعية متكاملة تضاهي Instagram و TikTok مع مميزات خاصة بمتابعة المباريات والإنجازات.

---

## 🎯 المميزات الرئيسية

### ✅ المكتملة
- **Social Feed**: فيد اجتماعي كامل مع منشورات وتفاعلات
- **Post Management**: إنشاء وتعديل وحذف المنشورات
- **Like & Comment**: نظام الإعجابات والتعليقات
- **Search**: بحث متقدم عن المنشورات والمستخدمين
- **Hashtags**: دعم الهاشتاجات والمنشورات المرتبطة

### 🔄 قيد التطوير
- **Stories**: قصص تختفي بعد 24 ساعة
- **Follow System**: متابعة المستخدمين والاقتراحات
- **Achievements**: نظام الإنجازات والشارات
- **Leaderboard**: لوحة المتصدرين
- **Live Scores**: تحديثات المباريات المباشرة

### ⏳ المخطط
- **Direct Messages**: رسائل مباشرة بين المستخدمين
- **Reels**: فيديوهات قصيرة مثل TikTok
- **Marketplace**: سوق للبيع والشراء
- **Bus Booking**: حجز الحافلات للمباريات

---

## 🏗️ البنية المعمارية

يتبع المشروع **Clean Architecture** مع **Bloc Pattern**:

```
Presentation Layer (UI)
    ↓
Domain Layer (Business Logic)
    ↓
Data Layer (Data Management)
    ↓
External Layer (Firebase, APIs)
```

**اقرأ**: [ARCHITECTURE.md](./ARCHITECTURE.md)

---

## 🚀 البدء السريع

### المتطلبات
- Flutter 3.0+
- Dart 3.0+
- Firebase Account
- Android Studio / Xcode

### التثبيت

```bash
# استنساخ المشروع
git clone https://github.com/your-repo/ahly-fans-app.git
cd ahly-fans-app

# تثبيت الاعتماديات
flutter pub get

# تشغيل التطبيق
flutter run
```

### إعداد Firebase

```bash
# تثبيت Firebase CLI
npm install -g firebase-tools

# تسجيل الدخول
firebase login

# تكوين المشروع
flutterfire configure
```

---

## 📁 هيكل المشروع

```
lib/
├── core/                    # الأساسيات المشتركة
├── features/               # المميزات الرئيسية
│   ├── social_feed/       # ✅ مكتمل
│   ├── stories/           # 🔄 قيد التطوير
│   ├── follow_system/     # 🔄 قيد التطوير
│   ├── achievements/      # 🔄 قيد التطوير
│   ├── leaderboard/       # 🔄 قيد التطوير
│   └── ...
├── shared/                # الموارد المشتركة
└── main.dart             # نقطة الدخول
```

---

## 🔧 الأدوات والتقنيات

### State Management
- **Bloc**: إدارة الحالة
- **Provider**: التوفير والحقن

### Database
- **Firebase Firestore**: قاعدة البيانات
- **Firebase Realtime Database**: البيانات المباشرة
- **Firebase Storage**: تخزين الملفات

### Networking
- **Http**: طلبات HTTP
- **Firebase Cloud Functions**: الدوال السحابية

### UI
- **Flutter Material**: مكونات المادة
- **Cached Network Image**: تخزين الصور مؤقتاً
- **Shimmer**: تأثيرات التحميل

### Testing
- **Mockito**: محاكاة الكائنات
- **Bloc Test**: اختبار Bloc
- **Integration Test**: اختبار التكامل

---

## 📊 معايير الأداء

| المعيار | الهدف | الحالة |
|--------|-------|--------|
| **وقت التحميل** | < 2 ثانية | ✅ |
| **FPS** | 60 FPS | ✅ |
| **استهلاك الذاكرة** | < 256 MB | ✅ |
| **استهلاك البطارية** | < 10% / ساعة | ⏳ |
| **حجم التطبيق** | < 100 MB | ✅ |

---

## 🧪 الاختبار

### تشغيل الاختبارات

```bash
# جميع الاختبارات
flutter test

# اختبار محدد
flutter test test/features/social_feed/bloc_test.dart

# اختبار التكامل
flutter drive --target=test_driver/app.dart
```

### تغطية الاختبارات

```bash
# توليد تقرير التغطية
flutter test --coverage

# عرض التقرير
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📈 الأداء والتحسينات

### تحسينات مطبقة
- ✅ Lazy Loading للقوائم
- ✅ Pagination للبيانات الكبيرة
- ✅ Image Caching والتحسين
- ✅ Debouncing للبحث
- ✅ Memory Management

### تحسينات مخطط
- ⏳ Video Compression
- ⏳ Offline Support
- ⏳ Push Notifications
- ⏳ Analytics

---

## 🔐 الأمان

### أفضل الممارسات المطبقة
- ✅ تشفير البيانات الحساسة
- ✅ Firebase Security Rules
- ✅ Input Validation
- ✅ Rate Limiting
- ✅ Secure Storage

### الخطط المستقبلية
- ⏳ Two-Factor Authentication
- ⏳ Biometric Authentication
- ⏳ End-to-End Encryption
- ⏳ Data Anonymization

---

## 📝 معايير الكود

### Naming Conventions
```dart
// Classes
class PostEntity {}
class SocialFeedBloc {}

// Functions
void loadFeedPosts() {}
Future<List<PostEntity>> getFeedPosts() {}

// Variables
final String userName;
int postsCount;
bool isLoading;

// Constants
static const String appName = 'جمهور الأهلي';
static const int defaultPageSize = 10;
```

### Code Style
```dart
// استخدام Dartfmt
dart format lib/

// استخدام Analyzer
dart analyze lib/

// استخدام Linter
flutter analyze
```

---

## 🐛 تقارير الأخطاء

### كيفية الإبلاغ
1. تحقق من أن المشكلة لم تُبلغ عنها من قبل
2. قدم وصفاً واضحاً للمشكلة
3. أرفق لقطات شاشة أو فيديو
4. حدد خطوات إعادة الإنتاج

### قالب الإبلاغ
```
**الوصف**
[وصف واضح للمشكلة]

**خطوات إعادة الإنتاج**
1. ...
2. ...

**السلوك المتوقع**
[ما يجب أن يحدث]

**السلوك الفعلي**
[ما يحدث فعلاً]

**البيئة**
- الجهاز: [iOS/Android]
- الإصدار: [رقم الإصدار]
- Flutter: [رقم الإصدار]
```

---

## 🤝 المساهمة

### خطوات المساهمة
1. Fork المشروع
2. أنشئ فرع جديد (`git checkout -b feature/amazing-feature`)
3. أضف تغييراتك (`git add .`)
4. اكتب رسالة التزام واضحة (`git commit -m 'Add amazing feature'`)
5. ادفع التغييرات (`git push origin feature/amazing-feature`)
6. افتح Pull Request

### معايير الجودة
- ✅ اتبع معايير الكود
- ✅ أضف اختبارات
- ✅ وثق التغييرات
- ✅ تأكد من عدم وجود أخطاء

---

## 📚 الموارد والمراجع

### التوثيق
- [Flutter Documentation](https://flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Bloc Documentation](https://bloclibrary.dev)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### الدورات والمقالات
- [Flutter Performance](https://flutter.dev/docs/perf)
- [Firebase Best Practices](https://firebase.google.com/docs/best-practices)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)

---

## 📞 التواصل

- **البريد الإلكتروني**: support@ahly-fans-app.com
- **Twitter**: [@AhlyFansApp](https://twitter.com/AhlyFansApp)
- **Facebook**: [Ahly Fans App](https://facebook.com/AhlyFansApp)

---

## 📄 الترخيص

هذا المشروع مرخص تحت [MIT License](./LICENSE)

---

## 🙏 شكر وتقدير

شكراً لجميع المساهمين والداعمين لهذا المشروع!

---

**آخر تحديث**: 6 مارس 2026  
**الإصدار**: 2.0.0  
**الحالة**: 🟢 قيد التطوير النشط
