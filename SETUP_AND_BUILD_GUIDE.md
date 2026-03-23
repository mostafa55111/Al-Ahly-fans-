# دليل الإعداد والبناء - تطبيق جمهور الأهلي

## 📋 المتطلبات الأساسية

قبل البدء، تأكد من تثبيت:

| الأداة | الإصدار | الرابط |
|-------|---------|--------|
| Flutter | 3.0.0 أو أحدث | https://flutter.dev/docs/get-started/install |
| Dart | 3.0.0 أو أحدث | يتم تثبيته مع Flutter |
| Android Studio | أحدث إصدار | https://developer.android.com/studio |
| Xcode | 14.0 أو أحدث | من App Store (iOS فقط) |
| Git | أحدث إصدار | https://git-scm.com |

## 🔧 خطوات الإعداد الأولي

### 1. التحقق من تثبيت Flutter
```bash
flutter --version
flutter doctor
```

تأكد من أن جميع المتطلبات موجودة (✓ علامات خضراء).

### 2. استنساخ المشروع
```bash
git clone <repository-url>
cd ahly-fans-app
```

### 3. تثبيت الـ Dependencies
```bash
flutter pub get
flutter pub upgrade
```

### 4. إنشاء ملف `.env` (اختياري)
```bash
# في جذر المشروع
GOOGLE_GENERATIVE_AI_API_KEY=your_api_key_here
THESPORTDB_API_KEY=your_api_key_here
```

## 🔐 إعداد Firebase

### 1. إنشاء مشروع Firebase
1. اذهب إلى [Firebase Console](https://console.firebase.google.com)
2. انقر على "Create Project"
3. أدخل اسم المشروع: `gomhor-al-ahly`
4. اتبع الخطوات

### 2. إضافة تطبيق Android
1. في Firebase Console، انقر على "Add App" → Android
2. أدخل Package Name: `com.example.gomhor_alahly_clean_new`
3. حمّل `google-services.json`
4. ضع الملف في `android/app/`

### 3. إضافة تطبيق iOS (اختياري)
1. في Firebase Console، انقر على "Add App" → iOS
2. أدخل Bundle ID: `com.example.gomhorAlahly`
3. حمّل `GoogleService-Info.plist`
4. ضع الملف في `ios/Runner/`

### 4. تفعيل الخدمات في Firebase
- **Authentication**: Email/Password
- **Firestore Database**: في وضع Production
- **Realtime Database**: للمباريات والتصويتات
- **Cloud Storage**: للصور والفيديوهات
- **Cloud Messaging**: للإشعارات

## 📱 البناء والتشغيل

### تشغيل على Android
```bash
# تشغيل في وضع Debug
flutter run

# أو تحديد جهاز معين
flutter devices
flutter run -d <device-id>

# بناء APK للإصدار
flutter build apk --release

# بناء App Bundle للـ Google Play
flutter build appbundle --release
```

### تشغيل على iOS
```bash
# تشغيل في وضع Debug
flutter run -d ios

# بناء IPA للإصدار
flutter build ios --release
```

### تشغيل على الويب
```bash
flutter run -d chrome
```

## 🏗️ البناء على Visual Studio Code

### 1. فتح المشروع
```bash
code .
```

### 2. تثبيت الإضافات
- Flutter (Dart Code)
- Dart
- Firebase Explorer (اختياري)

### 3. تشغيل التطبيق
- اضغط `F5` أو انقر على "Run" في الشريط العلوي
- اختر جهازك من القائمة

### 4. الـ Debugging
- استخدم `Debug Console` لعرض السجلات
- استخدم `Breakpoints` لإيقاف التنفيذ
- استخدم `Watch` لمراقبة المتغيرات

## 🏗️ البناء على Visual Studio (Windows)

### 1. تثبيت Visual Studio
- قم بتثبيت Visual Studio Community 2022 أو أحدث
- تثبيت "Desktop development with C++"

### 2. تثبيت Flutter و Android SDK
```bash
# في PowerShell كـ Administrator
choco install flutter
choco install android-sdk
```

### 3. إعداد Android SDK
```bash
# تعيين متغيرات البيئة
setx ANDROID_HOME "C:\Users\YourUsername\AppData\Local\Android\Sdk"
setx PATH "%PATH%;%ANDROID_HOME%\tools;%ANDROID_HOME%\platform-tools"
```

### 4. فتح المشروع في Visual Studio
1. File → Open → Folder
2. اختر مجلد `ahly-fans-app`
3. انتظر تحميل المشروع

### 5. تشغيل التطبيق
- اختر جهازك من القائمة العلوية
- اضغط على زر "Run" (أو F5)

## 📦 إنشاء Build للإصدار

### Android Release Build
```bash
# بناء APK
flutter build apk --release

# الملف الناتج: build/app/outputs/flutter-apk/app-release.apk

# أو بناء App Bundle
flutter build appbundle --release

# الملف الناتج: build/app/outputs/bundle/release/app-release.aab
```

### iOS Release Build
```bash
flutter build ios --release

# ثم فتح Xcode لإنهاء البناء
open ios/Runner.xcworkspace
```

## 🔍 استكشاف الأخطاء

### خطأ: "Could not find gradle"
```bash
flutter doctor --android-licenses
# قبول جميع الرخص
```

### خطأ: "Firebase not initialized"
تأكد من وجود `google-services.json` في `android/app/`

### خطأ: "Assets not found"
```bash
flutter clean
flutter pub get
flutter run
```

### خطأ: "Build failed"
```bash
# تنظيف البناء السابق
flutter clean

# إعادة تثبيت الـ Dependencies
flutter pub get

# محاولة البناء مرة أخرى
flutter run
```

## 📊 اختبار الأداء

```bash
# تشغيل مع تحليل الأداء
flutter run --profile

# أو مع تتبع الأداء الكامل
flutter run --trace-startup
```

## 🚀 نشر على Google Play

### 1. إنشاء حساب Google Play Developer
- اذهب إلى [Google Play Console](https://play.google.com/console)
- ادفع رسوم التسجيل ($25)

### 2. إنشاء تطبيق جديد
- اختر "Create app"
- أدخل اسم التطبيق: "جمهور الأهلي"
- اختر الفئة: "Sports"

### 3. بناء App Bundle
```bash
flutter build appbundle --release
```

### 4. التوقيع على الـ Bundle
يتم هذا تلقائياً إذا كان لديك `keystore` مُعد

### 5. رفع على Google Play Console
- اذهب إلى "Release" → "Production"
- اضغط "Create new release"
- اختر الـ Bundle
- أضف وصف الإصدار
- اضغط "Review release"

## 🍎 نشر على App Store

### 1. إنشاء حساب Apple Developer
- اذهب إلى [Apple Developer](https://developer.apple.com)
- ادفع رسوم العضوية ($99/سنة)

### 2. إنشاء تطبيق جديد
- اذهب إلى App Store Connect
- اختر "My Apps" → "+"
- أدخل بيانات التطبيق

### 3. بناء IPA
```bash
flutter build ios --release
```

### 4. استخدام Xcode للنشر
```bash
open ios/Runner.xcworkspace
```

## 📝 ملاحظات مهمة

- تأكد من أن جميع الـ Assets موجودة في مجلد `assets/`
- تحقق من أن Firebase مُهيأ بشكل صحيح قبل البناء
- استخدم `flutter clean` عند مواجهة مشاكل غريبة
- احفظ نسخة احتياطية من `keystore` و `provisioning profiles`
- اختبر التطبيق على أجهزة حقيقية قبل النشر

## 📚 موارد إضافية

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Android Development](https://developer.android.com)
- [iOS Development](https://developer.apple.com/ios)

## 💬 الدعم والمساعدة

في حالة مواجهة مشاكل:
1. تحقق من السجلات في Console
2. ابحث عن الخطأ على [Stack Overflow](https://stackoverflow.com)
3. تحقق من [Flutter Issues](https://github.com/flutter/flutter/issues)
4. اطلب المساعدة في [Flutter Community](https://flutter.dev/community)
