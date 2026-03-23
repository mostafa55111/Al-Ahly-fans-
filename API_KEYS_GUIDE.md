# 🔑 دليل إدارة مفاتيح API - تطبيق جمهور الأهلي

## ⚠️ تنبيه أمني مهم

**لا تشارك مفاتيح API الخاصة بك مع أحد!** احفظها في مكان آمن وتجنب رفعها على GitHub.

---

## 🔐 المفاتيح المستخدمة في المشروع

### 1. Gemini API Key (مطلوب ✅)

**الموقع:** `lib/main.dart` (السطر 11)

```dart
const String GEMINI_API_KEY = 'AIzaSyCNlqhPN6dkOTjF8DfV9IE4wyEzWjrCgjQ';
```

**الحصول على المفتاح:**
1. اذهب إلى [Google AI Studio](https://makersuite.google.com/app/apikey)
2. انقر على "Create API Key"
3. اختر المشروع أو أنشئ مشروع جديد
4. انسخ المفتاح

**الاستخدام:**
- يتم استخدامه في `AiAssistantService` للإجابات الذكية
- يمكن تهيئته تلقائياً عند بدء التطبيق

---

### 2. Firebase Configuration (مطلوب ✅)

**الملفات المطلوبة:**
- `android/app/google-services.json` (Android)
- `ios/Runner/GoogleService-Info.plist` (iOS - اختياري)

**الحصول على الملفات:**
1. اذهب إلى [Firebase Console](https://console.firebase.google.com)
2. أنشئ مشروع جديد أو اختر مشروع موجود
3. أضف تطبيق Android/iOS
4. حمّل ملفات الإعدادات

**الخدمات المفعلة:**
- ✅ Authentication (تسجيل الدخول)
- ✅ Realtime Database (البيانات الحية)
- ✅ Cloud Storage (تخزين الصور والفيديوهات)
- ✅ Cloud Messaging (الإشعارات)
- ✅ Firestore (قاعدة البيانات)

---

### 3. TheSportDB API (مجاني - لا يحتاج مفتاح)

**الموقع:** `lib/core/services/sports_api_service.dart`

**Base URL:**
```
https://www.thesportsdb.com/api/v1/json/3
```

**معرف النادي الأهلي:** `133912`

**الاستخدام:**
- جلب بيانات المباريات
- جلب إحصائيات الفريق
- جلب معلومات اللاعبين

**ملاحظة:** لا يتطلب مفتاح API - API مجاني وعام

---

### 4. Cloudinary (اختياري - لتخزين الصور والفيديوهات)

**الموقع:** `lib/core/services/cloudinary_service.dart`

**الحصول على المفاتيح:**
1. اذهب إلى [Cloudinary](https://cloudinary.com)
2. أنشئ حساب مجاني
3. احصل على Cloud Name و API Key

**المفاتيح المطلوبة:**
```
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

**الاستخدام:**
- رفع الصور والفيديوهات
- تحسين الصور
- إنشاء روابط مباشرة

---

## 🔒 أفضل الممارسات الأمنية

### 1. عدم مشاركة المفاتيح
```dart
// ❌ خطأ - لا تفعل هذا
const String API_KEY = 'AIzaSyCNlqhPN6dkOTjF8DfV9IE4wyEzWjrCgjQ';
// ثم رفعه على GitHub

// ✅ صحيح - استخدم ملف .env أو متغيرات البيئة
const String API_KEY = String.fromEnvironment('GEMINI_API_KEY');
```

### 2. استخدام متغيرات البيئة
```bash
# عند البناء
flutter run --dart-define=GEMINI_API_KEY=your-key-here
```

### 3. تفعيل Firebase Security Rules
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

### 4. تقييد استخدام API Keys
- في Google Cloud Console: حدد التطبيقات المسموحة
- في Firebase: استخدم Security Rules
- في Cloudinary: استخدم signed URLs

---

## 📋 قائمة التحقق

### قبل الإطلاق
- [ ] تم إضافة `google-services.json` في `android/app/`
- [ ] تم إضافة `GoogleService-Info.plist` في `ios/Runner/` (iOS)
- [ ] تم تفعيل جميع خدمات Firebase
- [ ] تم اختبار Gemini API
- [ ] تم اختبار TheSportDB API
- [ ] تم حماية جميع المفاتيح

### قبل النشر على Google Play
- [ ] تم إزالة جميع المفاتيح من الأكواد
- [ ] تم استخدام متغيرات البيئة
- [ ] تم تفعيل Firebase Security Rules
- [ ] تم اختبار الأمان

### قبل النشر على App Store
- [ ] تم إزالة جميع المفاتيح من الأكواد
- [ ] تم استخدام متغيرات البيئة
- [ ] تم تفعيل Firebase Security Rules
- [ ] تم اختبار الأمان

---

## 🚀 كيفية استخدام المفاتيح في التطوير

### 1. في بيئة التطوير المحلية
```bash
# تشغيل مع متغيرات البيئة
flutter run --dart-define=GEMINI_API_KEY=your-key-here
```

### 2. في ملف build.gradle (Android)
```gradle
buildTypes {
    release {
        buildConfigField "String", "GEMINI_API_KEY", "\"${GEMINI_API_KEY}\""
    }
}
```

### 3. في Xcode (iOS)
```
Build Settings → User-Defined → GEMINI_API_KEY
```

---

## 🔄 تدوير المفاتيح (Key Rotation)

### متى تدوّر المفاتيح؟
- كل 90 يوم (أفضل ممارسة)
- عند الاشتباه في تسرب
- عند تغيير الفريق
- قبل الإطلاق العام

### كيفية التدوير؟
1. أنشئ مفتاح جديد
2. اختبره في بيئة الاختبار
3. حدّث المشروع
4. احذف المفتاح القديم

---

## 📞 الدعم والمساعدة

### إذا واجهت مشاكل

**خطأ: "Invalid API Key"**
- تحقق من صحة المفتاح
- تأكد من تفعيل الخدمة في Google Cloud Console
- تأكد من أن المفتاح لم ينته صلاحيته

**خطأ: "Firebase not initialized"**
- تحقق من وجود `google-services.json`
- تأكد من مسار الملف الصحيح
- جرّب `flutter clean` و `flutter pub get`

**خطأ: "Quota exceeded"**
- تحقق من حد الاستخدام في Google Cloud Console
- ترقّ إلى خطة مدفوعة إذا لزم الأمر
- قلّل عدد الطلبات

---

## 📚 الموارد الإضافية

- [Google AI Documentation](https://ai.google.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [TheSportDB API](https://www.thesportsdb.com/api.php)
- [Cloudinary Documentation](https://cloudinary.com/documentation)

---

**⚠️ تذكر: أمان المفاتيح مسؤوليتك الشخصية!**

🦅 **الأهلي فوق الجميع** 🦅
