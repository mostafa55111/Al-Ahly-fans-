import 'package:flutter/foundation.dart';

/// ملف إدارة المتغيرات البيئية (Environment Configuration)
/// يتم استخدام هذا الملف لتخزين جميع المفاتيح والإعدادات الحساسة
class EnvConfig {
  // Firebase Configuration
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'ahly-fans-app-prod',
  );

  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  static const String firebaseDatabaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: '',
  );

  // External APIs
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCNlqhPN6dkOTjF8DfV9IE4wyEzWjrCgjQ',
  );

  static const String footballApiKey = String.fromEnvironment(
    'FOOTBALL_API_KEY',
    defaultValue: '8c16585903c335eb82435488feac3937',
  );

  static const String cloudinaryApiKey = String.fromEnvironment(
    'CLOUDINARY_API_KEY',
    defaultValue: '497232166977864',
  );

  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dubc6k1iy',
  );

  // App Configuration
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'gomhor_alahly_clean_new',
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '2.0.0',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  // Feature Flags
  static const bool enableAiFeatures = bool.fromEnvironment(
    'ENABLE_AI_FEATURES',
    defaultValue: true,
  );

  static const bool enableVoiceRooms = bool.fromEnvironment(
    'ENABLE_VOICE_ROOMS',
    defaultValue: true,
  );

  static const bool enableLiveStreaming = bool.fromEnvironment(
    'ENABLE_LIVE_STREAMING',
    defaultValue: true,
  );

  static const bool enableSocialCommerce = bool.fromEnvironment(
    'ENABLE_SOCIAL_COMMERCE',
    defaultValue: true,
  );

  // Utility Methods
  static bool isProduction() => environment == 'production';
  static bool isDevelopment() => environment == 'development';
  static bool isStaging() => environment == 'staging';

  /// طباعة الإعدادات (للاستخدام في التطوير فقط)
  static void printConfig() {
    if (kDebugMode) {
      debugPrint('=== App Configuration ===');
      debugPrint('App Name: $appName');
      debugPrint('App Version: $appVersion');
      debugPrint('Environment: $environment');
      debugPrint('AI Features: $enableAiFeatures');
      debugPrint('Voice Rooms: $enableVoiceRooms');
      debugPrint('Live Streaming: $enableLiveStreaming');
      debugPrint('Social Commerce: $enableSocialCommerce');
    }
  }
}
