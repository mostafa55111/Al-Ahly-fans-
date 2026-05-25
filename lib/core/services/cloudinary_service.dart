import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/core/config/bundled_cloudinary_config.dart';

class CloudinaryService {
  CloudinaryService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: AppConfig.connectTimeoutDuration,
                receiveTimeout: AppConfig.receiveTimeoutDuration,
              ),
            );

  final Dio _dio;

  String get _cloudName {
    final fromEnv = AppConfig.cloudinaryCloudName.trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return BundledCloudinaryConfig.cloudName.trim();
  }

  String get _uploadPreset {
    final fromEnv = AppConfig.cloudinaryUploadPreset.trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    final fromBundle = BundledCloudinaryConfig.uploadPreset.trim();
    if (fromBundle.isNotEmpty) return fromBundle;
    return AppConfig.cloudinaryApiKey.trim();
  }

  String get _apiKey {
    final fromEnv = AppConfig.cloudinaryApiKey.trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return BundledCloudinaryConfig.apiKey.trim();
  }

  bool get isReady => _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  String _endpoint({required String resourceType}) {
    return 'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload';
  }

  Future<FormData> _multipartForUpload(File file) async {
    if (!isReady) {
      throw Exception(
        'Cloudinary غير جاهز. تأكد من ملف الأصول أو CLOUDINARY_CLOUD_NAME و CLOUDINARY_UPLOAD_PRESET',
      );
    }
    if (kDebugMode && _apiKey.isEmpty) {
      debugPrint('⚠️ Cloudinary API Key غير مضبوط (اختياري للرفع غير الموقّع)');
    }
    return FormData.fromMap({
      'upload_preset': _uploadPreset,
      'file': await MultipartFile.fromFile(file.path),
    });
  }

  /// [onUploadProgress] يُستدعى بجزء مكتمل بين 0 و 1 أثناء رفع الجسم (Dio).
  Future<String> uploadVideo(
    File file, {
    void Function(double progress01)? onUploadProgress,
  }) async {
    try {
      final form = await _multipartForUpload(file);
      final res = await _dio.post<Map<String, dynamic>>(
        _endpoint(resourceType: 'video'),
        data: form,
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          onUploadProgress?.call(sent / total);
        },
      );
      final data = res.data;
      final url = data?['secure_url']?.toString();
      if (url == null || url.isEmpty) {
        throw Exception('Cloudinary response missing secure_url');
      }
      return url;
    } catch (e) {
      debugPrint('Cloudinary uploadVideo error: $e');
      rethrow;
    }
  }

  Future<String> uploadImage(File file, {String resourceType = 'image'}) async {
    try {
      final rt = resourceType.trim().isEmpty ? 'image' : resourceType.trim();
      final form = await _multipartForUpload(file);
      final res = await _dio.post<Map<String, dynamic>>(
        _endpoint(resourceType: rt),
        data: form,
      );
      final data = res.data;
      final url = data?['secure_url']?.toString();
      return url ?? '';
    } catch (e) {
      debugPrint('Image upload error: $e');
      rethrow;
    }
  }
}
