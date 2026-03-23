# مشروع جمهور الأهلي - قائمة المهام

## المرحلة 1: إصلاح الأخطاء الحرجة
- [x] إزالة dependency openai واستبدالها بـ google_generative_ai
- [x] تحديث pubspec.yaml مع جميع الـ dependencies
- [x] إصلاح ai_assistant_service.dart
- [x] تحديث main.dart مع Theme صحيح
- [x] إنشاء app_theme.dart مع الهوية البصرية الفخمة

## المرحلة 2: بناء الهيكل المعماري
- [ ] تحديث firebase_options.dart لجميع المنصات
- [ ] إنشاء service_locator.dart مع Dependency Injection
- [ ] بناء Base Classes للـ Bloc و Repository
- [ ] إنشاء Error Handling و Exception Classes
- [ ] بناء Network و Local Data Sources

## المرحلة 3: بناء نظام Authentication
- [ ] تطوير login_screen.dart بشكل احترافي
- [ ] تطوير register_screen.dart
- [ ] بناء password_reset_screen.dart
- [ ] بناء profile_screen.dart مع تفاصيل المستخدم
- [ ] تطبيق Bloc للـ Authentication

## المرحلة 4: بناء مركز المباريات
- [ ] تطوير match_center_screen.dart
- [ ] ربط TheSportDB API لجلب المباريات
- [ ] بناء match_details_screen.dart
- [ ] تطبيق Bloc للـ Match Center
- [ ] إضافة Push Notifications للمباريات

## المرحلة 5: بناء نظام التصويت
- [ ] تطوير voting_screen.dart
- [ ] بناء man_of_match_voting.dart
- [ ] بناء formation_prediction.dart
- [ ] تطبيق Bloc للـ Voting System
- [ ] ربط Firebase Firestore للتصويتات

## المرحلة 6: بناء ركن الريلز
- [ ] تطوير reels_screen.dart بشكل احترافي
- [ ] بناء video_player_widget.dart
- [ ] تطبيق Like و Comment و Share
- [ ] بناء reels_upload_screen.dart
- [ ] تطبيق Bloc للـ Reels

## المرحلة 7: بناء الملف الشخصي والإحصائيات
- [ ] تطوير user_profile_screen.dart
- [ ] بناء loyalty_points_widget.dart
- [ ] تطوير statistics_screen.dart
- [ ] بناء achievements_screen.dart
- [ ] تطبيق Bloc للـ Profile

## المرحلة 8: بناء الميزات الإضافية
- [ ] تطوير marketplace_screen.dart
- [ ] بناء product_details_screen.dart
- [ ] تطوير bus_booking_screen.dart
- [ ] بناء admin_dashboard_screen.dart
- [ ] تطوير ai_chat_screen.dart

## المرحلة 9: تطوير الهوية البصرية والـ UI/UX
- [ ] إنشاء Custom Widgets (Cards, Buttons, etc.)
- [ ] بناء Animations و Transitions
- [ ] تطبيق Design System
- [ ] إضافة Shimmer Loading Effects
- [ ] تطبيق RTL Support للعربية

## المرحلة 10: الاختبار والتحسين
- [ ] اختبار جميع الشاشات
- [ ] اختبار الـ APIs والـ Integrations
- [ ] اختبار Performance والـ Memory
- [ ] إصلاح الأخطاء والـ Bugs
- [ ] تحسين User Experience

## المرحلة 11: التجهيز للبناء والنشر
- [ ] تحديث gradle.properties للـ Android
- [ ] تحديث Info.plist للـ iOS
- [ ] إنشاء App Icons و Splash Screens
- [ ] تجهيز Firebase Configuration
- [ ] إنشاء Build Scripts والـ CI/CD

## المرحلة 12: التوثيق والتسليم
- [ ] كتابة README شامل
- [ ] توثيق API Endpoints
- [ ] توثيق Firebase Setup
- [ ] إنشاء Installation Guide
- [ ] تجهيز Release Notes

## ملاحظات مهمة
- التطبيق يستخدم Flutter مع Firebase و TheSportDB API
- الهوية البصرية: أسود فاحم + ذهبي ساطع + أحمر ملكي
- جميع النصوص بالعربية مع دعم RTL
- يجب اتباع Clean Architecture في جميع الأكواد
- استخدام Bloc للـ State Management
