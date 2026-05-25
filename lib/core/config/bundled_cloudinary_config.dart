import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// قراءة إعدادات Cloudinary من أصول تطبيق الأهلي.
///
/// أولوية القيم في [CloudinaryService]: `--dart-define` ثم هذا الملف.
class BundledCloudinaryConfig {
  BundledCloudinaryConfig._();

  static String cloudName = '';
  static String uploadPreset = '';
  static String apiKey = '';

  static bool get isReady =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  static Future<void> loadBundledOverrides() async {
    cloudName = '';
    uploadPreset = '';
    apiKey = '';
    try {
      final raw = await rootBundle
          .loadString('assets/config/cloudinary_gomhor_ahly.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        cloudName = '${decoded['cloud_name'] ?? ''}'.trim();
        uploadPreset = '${decoded['upload_preset'] ?? ''}'.trim();
        apiKey = '${decoded['api_key'] ?? ''}'.trim();
      }
      if (kDebugMode && isReady) {
        debugPrint('✅ Cloudinary (الأهلي): الملف مُحمّل — cloud=$cloudName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BundledCloudinaryConfig: تعذّر تحميل cloudinary_gomhor_ahly.json — $e');
      }
    }
  }
}
