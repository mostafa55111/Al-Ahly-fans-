/// تكوين التطبيق الآمن
///
/// هذا الملف يدير جميع إعدادات التطبيق والمفاتيح الحساسة بشكل آمن
/// يتم تحميل المفاتيح من متغيرات البيئة أو Firebase Remote Config
/// وليس من الكود المصدري مباشرة
library;

import 'package:flutter/foundation.dart';

/// فئة تكوين التطبيق الرئيسية
class AppConfig {
  // ===== API Keys (من متغيرات البيئة أو Firebase Remote Config) =====

  /// مفتاح Gemini API
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // سيتم تحميله من Firebase Remote Config في الإنتاج
  );

  /// مفتاح Football API
  static const String footballApiKey = String.fromEnvironment(
    'FOOTBALL_API_KEY',
    defaultValue: '', // سيتم تحميله من Firebase Remote Config في الإنتاج
  );

  /// مفتاح Cloudinary API
  static const String cloudinaryApiKey = String.fromEnvironment(
    'CLOUDINARY_API_KEY',
    defaultValue: '', // سيتم تحميله من Firebase Remote Config في الإنتاج
  );

  /// اسم السحابة في Cloudinary
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: '',
  );

  /// Upload preset (Unsigned) في Cloudinary
  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: '',
  );

  // ===== API Endpoints =====

  /// Base URL لخدمات الباك-إند الخاصة بالتطبيق (إن وجدت)
  static const String appApiBaseUrl = String.fromEnvironment(
    'APP_API_BASE_URL',
    defaultValue: 'https://api.ahly-fans-app.com',
  );

  /// نقطة نهاية Football API
  static const String footballApiBaseUrl = 'https://api.football-data.org/v4';

  /// نقطة نهاية TheSportDB API (بديل آمن)
  static const String theSportDbBaseUrl =
      'https://www.thesportsdb.com/api/v1/json';

  /// مفتاح TheSportsDB (الافتراضي العام المجاني "3")
  static const String theSportDbApiKey = String.fromEnvironment(
    'THE_SPORT_DB_API_KEY',
    defaultValue: '3',
  );

  /// نقطة نهاية Gemini API
  static const String geminiApiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// اسم موديل Gemini الافتراضي
  static const String geminiModelName = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.0-flash',
  );

  // ===== Firebase Configuration =====

  /// معرف مشروع Firebase
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  /// معرف التطبيق في Firebase
  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  /// قيمة حقل `app_source` في مستندات Firestore — لعزل بيانات الأهلي داخل مشروع Firebase المشترك.
  static const String firestoreAppSource = 'gomhor_ahly';

  /// علامة النادي لمجموعة ريلز Firestore للخوارزمية — يجب أن تكون `ahly` أو `zamalek`.
  static const String reelsFirestoreClubTag = 'ahly';

  /// مسار عقدة ريلز Firebase Realtime Database لهذا التطبيق.
  static const String rtdbReelsPath = 'reels';

  /// افتراض فيد «لك»: محلي بنادي التطبيق (`app_source` = الأهلي).
  static const bool reelsDefaultGlobalAudience = false;

  /// معرّف النادي المنظّم للترحال والحجوزات في هذا التطبيق.
  static const String travelOrganizerClubId = 'ahly';

  // ===== App Configuration =====

  /// اسم التطبيق
  static const String appName = 'جمهور الأهلي';

  /// إصدار التطبيق
  static const String appVersion = '1.0.0';

  /// رقم البناء
  static const int buildNumber = 1;

  // ===== Feature Flags =====

  /// تفعيل وضع التطوير (Debug Mode)
  static bool get isDebugMode => kDebugMode;

  /// تفعيل وضع الإنتاج
  static bool get isProduction => !kDebugMode;

  /// تفعيل Firebase Remote Config
  static const bool enableRemoteConfig = true;

  /// تفعيل Analytics
  static const bool enableAnalytics = true;

  /// تفعيل Crash Reporting
  static const bool enableCrashReporting = true;

  // ===== Timeouts =====

  /// مهلة الاتصال (بالثواني)
  static const int connectionTimeout = 30;

  /// مهلة الاستجابة (بالثواني)
  static const int receiveTimeout = 30;

  /// مهلة المراقبة (بالثواني)
  static const int monitoringTimeout = 30;

  static const Duration connectTimeoutDuration =
      Duration(seconds: connectionTimeout);
  static const Duration receiveTimeoutDuration =
      Duration(seconds: receiveTimeout);

  // ===== Pagination =====

  /// عدد العناصر في كل صفحة
  static const int pageSize = 20;

  /// الحد الأقصى للصفحات المخزنة مؤقتاً
  static const int maxCachedPages = 5;

  // ===== Cache Configuration =====

  /// مدة صلاحية الكاش (بالدقائق)
  static const int cacheExpirationMinutes = 60;

  /// الحد الأقصى لحجم الكاش (بالميجابايت)
  static const int maxCacheSizeMB = 100;

  // ===== Notification Configuration =====

  /// تفعيل الإشعارات
  static const bool enableNotifications = true;

  /// تفعيل الإشعارات الفورية
  static const bool enablePushNotifications = true;

  /// تفعيل الإشعارات المحلية
  static const bool enableLocalNotifications = true;

  // ===== Logging Configuration =====

  /// تفعيل السجلات (Logging)
  static const bool enableLogging = true;

  /// تفعيل سجلات الشبكة
  static const bool enableNetworkLogging = true;

  /// تفعيل سجلات قاعدة البيانات
  static const bool enableDatabaseLogging = true;

  // ===== Security Configuration =====

  /// تفعيل SSL Pinning
  static const bool enableSSLPinning = true;

  /// تفعيل تشفير البيانات المحلية
  static const bool enableLocalEncryption = true;

  /// تفعيل التحقق من التوقيع
  static const bool enableSignatureVerification = true;

  // ===== Methods =====

  /// التحقق من صحة تكوين التطبيق
  static bool validateConfig() {
    if (isProduction) {
      // في الإنتاج، يجب أن تكون جميع المفاتيح موجودة
      return geminiApiKey.isNotEmpty &&
          footballApiKey.isNotEmpty &&
          cloudinaryApiKey.isNotEmpty &&
          cloudinaryCloudName.isNotEmpty;
    }
    return true;
  }

  /// الحصول على رسالة خطأ التكوين
  static String? getConfigError() {
    if (isProduction) {
      if (geminiApiKey.isEmpty) return 'Gemini API Key غير موجود';
      if (footballApiKey.isEmpty) return 'Football API Key غير موجود';
      if (cloudinaryApiKey.isEmpty) return 'Cloudinary API Key غير موجود';
      if (cloudinaryCloudName.isEmpty) return 'Cloudinary Cloud Name غير موجود';
    }
    return null;
  }

  /// طباعة معلومات التكوين (للتطوير فقط)
  static void printConfigInfo() {
    if (kDebugMode) {
      debugPrint('=== App Configuration ===');
      debugPrint('App Name: $appName');
      debugPrint('App Version: $appVersion');
      debugPrint('Build Number: $buildNumber');
      debugPrint('Debug Mode: $isDebugMode');
      debugPrint('Firebase Project: $firebaseProjectId');
      debugPrint('Football API Base URL: $footballApiBaseUrl');
      debugPrint('Cloudinary Cloud Name: $cloudinaryCloudName');
      debugPrint('========================');
    }
  }
}
