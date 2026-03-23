# 🖼️ دليل إعداد Cloudinary - تطبيق جمهور الأهلي

## 📋 معلومات Cloudinary

| المعلومة | القيمة |
|---------|--------|
| **API Key** | 497232166977864 |
| **Cloud Name** | dubc6k1iy |
| **Upload Preset** | ahly_fans_preset |
| **المنطقة** | MENA (Middle East & North Africa) |

---

## 🔧 خطوات الإعداد الأولي

### 1. إنشاء حساب Cloudinary

1. اذهب إلى [Cloudinary.com](https://cloudinary.com)
2. انقر على "Sign Up"
3. أنشئ حساب مجاني
4. تحقق من بريدك الإلكتروني

### 2. الحصول على Cloud Name

1. بعد تسجيل الدخول، اذهب إلى Dashboard
2. ستجد **Cloud Name** في الأعلى
3. انسخه واستبدل `ahly-fans` به في:
   - `lib/main.dart` (السطر 18)
   - `lib/core/services/cloudinary_service.dart` (السطر 5)

### 3. إنشاء Upload Preset

#### الخطوات:
1. اذهب إلى **Settings** → **Upload**
2. انقر على **Add upload preset**
3. أدخل الاسم: `ahly_fans_preset`
4. اختر **Unsigned** (بدون توقيع)
5. حفظ الإعدادات

#### الإعدادات الموصى بها:
```
- Folder: ahly-fans/
- Auto-tag: true
- Eager transformations: 
  - e_scale,w_300,h_300,c_thumb,q_80 (للصور المصغرة)
  - e_scale,w_640,h_480,c_fill,q_80 (للعرض الكامل)
```

### 4. تفعيل المجلدات

1. اذهب إلى **Settings** → **Upload**
2. تأكد من تفعيل **Use filename or public ID of uploaded file**
3. تأكد من تفعيل **Auto-create folders**

---

## 📁 هيكل المجلدات الموصى به

```
ahly-fans/
├── reels/           # الفيديوهات القصيرة
│   ├── 2026-03/
│   ├── 2026-02/
│   └── ...
├── images/          # الصور العامة
│   ├── profile/     # صور الملفات الشخصية
│   ├── posts/       # صور المنشورات
│   └── assets/      # الصور الثابتة
├── videos/          # الفيديوهات الطويلة
│   ├── matches/     # فيديوهات المباريات
│   └── tutorials/   # فيديوهات تعليمية
└── thumbnails/      # الصور المصغرة
```

---

## 🎬 استخدام Cloudinary في التطبيق

### 1. رفع فيديو (Reel)

```dart
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';

final cloudinaryService = CloudinaryService();

// رفع فيديو من المعرض
final result = await cloudinaryService.pickAndUploadVideo(
  userId: 'user123',
  caption: 'أهداف الأهلي اليوم',
  userName: 'أحمد محمد',
);

if (result?['success'] == true) {
  print('تم رفع الفيديو: ${result?['videoUrl']}');
  print('معرّف الريل: ${result?['reelId']}');
}
```

### 2. رفع صورة

```dart
// رفع صورة من المعرض
final result = await cloudinaryService.pickAndUploadImage(
  userId: 'user123',
);

if (result?['success'] == true) {
  print('تم رفع الصورة: ${result?['imageUrl']}');
}
```

### 3. تسجيل فيديو مباشرة

```dart
// تسجيل فيديو من الكاميرا ورفعه
final result = await cloudinaryService.recordAndUploadVideo(
  userId: 'user123',
  caption: 'لحظة مشجعة من الملعب',
  userName: 'أحمد محمد',
);
```

### 4. جلب الريلز

```dart
// الاستماع إلى جميع الريلز
cloudinaryService.getReels().listen((reels) {
  print('عدد الريلز: ${reels.length}');
  for (final reel in reels) {
    print('${reel['userName']}: ${reel['caption']}');
  }
});

// جلب ريلز مستخدم معين
cloudinaryService.getUserReels('user123').listen((reels) {
  print('ريلز المستخدم: ${reels.length}');
});
```

### 5. التفاعل مع الريلز

```dart
// إضافة إعجاب
await cloudinaryService.likeReel('reel123');

// إزالة إعجاب
await cloudinaryService.unlikeReel('reel123');

// إضافة تعليق
await cloudinaryService.addComment(
  'reel123',
  'user123',
  'فيديو رائع جداً!',
);

// مشاركة الريل
await cloudinaryService.shareReel('reel123');

// تحديث المشاهدات
await cloudinaryService.incrementViews('reel123');
```

### 6. البحث والترتيب

```dart
// البحث عن الريلز
final results = await cloudinaryService.searchReels('أهداف');

// جلب الريلز الشهيرة
final trending = await cloudinaryService.getTrendingReels();
```

---

## 🖼️ تحسين الصور والفيديوهات

### تحسين الصور تلقائياً

```dart
// الحصول على صورة محسّنة
final optimizedUrl = cloudinaryService.getOptimizedImageUrl(
  imageUrl,
  width: 600,
  height: 400,
);
```

### إنشاء صور مصغرة للفيديوهات

```dart
// يتم إنشاء الصور المصغرة تلقائياً عند رفع الفيديو
// الرابط يكون متاح في حقل 'thumbnail' في Firebase
```

---

## 📊 مراقبة الاستخدام

### حدود الخطة المجانية

| الميزة | الحد |
|--------|------|
| **التخزين** | 10 GB |
| **النطاق الترددي** | 20 GB/شهر |
| **عمليات التحويل** | محدودة |
| **المجلدات** | غير محدود |
| **الملفات** | غير محدود |

### مراقبة الاستخدام

1. اذهب إلى Dashboard
2. انقر على **Usage**
3. شاهد إحصائيات الاستخدام الحالية

---

## 🔐 الأمان والخصوصية

### 1. حماية المفاتيح

```dart
// لا تشارك API Key في الأكواد العامة
// استخدم متغيرات البيئة بدلاً من ذلك

// ❌ خطأ
const String API_KEY = '497232166977864';

// ✅ صحيح
const String API_KEY = String.fromEnvironment('CLOUDINARY_API_KEY');
```

### 2. تفعيل التوقيع

للملفات الحساسة، استخدم التوقيع:

```dart
// توقيع الطلب (يتطلب API Secret)
// يجب تنفيذه من Backend فقط
```

### 3. تحديد الأنواع المسموحة

في Upload Preset:
```
Allowed file types:
- Images: jpg, png, gif, webp
- Videos: mp4, mov, avi, mkv
```

### 4. تحديد حجم الملفات

```
Max file size: 100 MB (للفيديوهات)
Max file size: 10 MB (للصور)
```

---

## 🐛 معالجة الأخطاء الشائعة

### خطأ 1: "Invalid upload preset"
```
السبب: اسم Upload Preset غير صحيح
الحل: تحقق من اسم Preset في Cloudinary Dashboard
```

### خطأ 2: "Upload failed"
```
السبب: مشكلة في الاتصال أو حجم الملف
الحل: تحقق من الاتصال بالإنترنت وحجم الملف
```

### خطأ 3: "Invalid API key"
```
السبب: API Key غير صحيح
الحل: انسخ API Key من Cloudinary Dashboard مرة أخرى
```

### خطأ 4: "Quota exceeded"
```
السبب: تجاوز حد الاستخدام
الحل: ترقّ إلى خطة مدفوعة أو انتظر تجديد الحد الشهري
```

---

## 📱 التكامل مع Reels Screen

### الملف: `lib/features/reels/presentation/pages/reels_screen.dart`

```dart
// استخدام CloudinaryService لرفع الريلز
final cloudinaryService = CloudinaryService();

// زر رفع فيديو جديد
ElevatedButton(
  onPressed: () async {
    final result = await cloudinaryService.pickAndUploadVideo(
      userId: currentUser.id,
      caption: captionController.text,
      userName: currentUser.name,
    );
    
    if (result?['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم رفع الفيديو بنجاح')),
      );
    }
  },
  child: Text('رفع فيديو'),
)
```

---

## 🚀 الخطوات التالية

### 1. الإعداد الأولي
- [ ] إنشاء حساب Cloudinary
- [ ] الحصول على Cloud Name
- [ ] إنشاء Upload Preset
- [ ] تحديث المفاتيح في التطبيق

### 2. الاختبار
- [ ] اختبار رفع صورة
- [ ] اختبار رفع فيديو
- [ ] اختبار جلب الريلز
- [ ] اختبار التفاعلات (إعجاب، تعليق، مشاركة)

### 3. التحسينات
- [ ] تفعيل التوقيع للملفات الحساسة
- [ ] إضافة ضغط الصور والفيديوهات
- [ ] إضافة معالجة الأخطاء المتقدمة
- [ ] إضافة شريط تقدم الرفع

### 4. النشر
- [ ] اختبار على جهاز حقيقي
- [ ] التحقق من الأداء
- [ ] النشر على Google Play و App Store

---

## 📞 الدعم والمساعدة

### موارد مفيدة

- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Cloudinary API Reference](https://cloudinary.com/documentation/cloudinary_api)
- [Flutter Cloudinary Package](https://pub.dev/packages/cloudinary_public)

### في حالة مواجهة مشاكل

1. تحقق من API Key والـ Cloud Name
2. تحقق من اتصال الإنترنت
3. تحقق من حد الاستخدام
4. راجع السجلات في Cloudinary Dashboard

---

## 📊 إحصائيات الاستخدام

### الملفات المرفوعة
```
إجمالي الملفات: 0
إجمالي الصور: 0
إجمالي الفيديوهات: 0
التخزين المستخدم: 0 GB
```

### الأداء
```
متوسط سرعة الرفع: -
متوسط سرعة التحميل: -
معدل النجاح: -%
```

---

**✨ تم إعداد Cloudinary بنجاح! ✨**

🦅 **الأهلي فوق الجميع** 🦅
