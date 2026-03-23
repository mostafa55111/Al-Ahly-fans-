import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/utils/reels_search_utils.dart';

/// رفع فيديوهات الريلز عبر Cloudinary (Unsigned preset) مع مسار Dio أولاً
/// لتفادي أخطاء 400 وتوضيح رسائل Cloudinary.
class CloudinaryService {
  static const String cloudName = 'dubc6k1iy';
  static const String uploadPreset = 'ahly_video_final';
  static const String reelsPath = 'reels';
  static const String legacyReelsPath = 'Reels';

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    cloudName,
    uploadPreset,
    cache: false,
  );

  final FirebaseDatabase _firebaseDatabase = FirebaseDatabase.instance;

  Dio _buildDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(minutes: 6),
        receiveTimeout: const Duration(minutes: 6),
        sendTimeout: const Duration(minutes: 6),
        // نقرأ جسم خطأ 400 من Cloudinary بدل رمي DioException مبكراً
        validateStatus: (s) => s != null && s < 500,
        headers: <String, dynamic>{
          'Accept': 'application/json',
        },
      ),
    );
  }

  String _parseCloudinaryError(dynamic data) {
    if (data == null) return 'خطأ غير معروف من الخادم';
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        final msg = err['message']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      return data.toString();
    }
    return data.toString();
  }

  Future<MultipartFile> _multipartFromVideoFile(File videoFile) async {
    final fileName = videoFile.path.split(Platform.pathSeparator).last;
    if (fileName.isEmpty) {
      throw 'اسم ملف الفيديو غير صالح';
    }
    try {
      return await MultipartFile.fromFile(
        videoFile.path,
        filename: fileName,
      );
    } catch (e) {
      debugPrint('[Cloudinary] fromFile فشل، جاري القراءة كبايتات: $e');
      final bytes = await videoFile.readAsBytes();
      if (bytes.isEmpty) throw 'ملف الفيديو فارغ';
      return MultipartFile.fromBytes(bytes, filename: fileName);
    }
  }

  /// رفع عبر REST الرسمي (multipart) — Unsigned preset `ahly_video_final`.
  Future<Map<String, String>> _uploadVideoViaDio({
    required File videoFile,
    String? folder,
    int attempt = 1,
  }) async {
    final dio = _buildDio();
    final multipart = await _multipartFromVideoFile(videoFile);
    final map = <String, dynamic>{
      'upload_preset': uploadPreset,
      'file': multipart,
    };
    if (folder != null && folder.isNotEmpty) {
      map['folder'] = folder;
    }

    final formData = FormData.fromMap(map);
    const url = 'https://api.cloudinary.com/v1_1/$cloudName/video/upload';

    try {
      final response = await dio.post<Map<String, dynamic>>(
        url,
        data: formData,
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data != null) {
        final secure = data['secure_url']?.toString();
        final publicId = data['public_id']?.toString();
        if (secure != null &&
            secure.isNotEmpty &&
            publicId != null &&
            publicId.isNotEmpty) {
          return {'secureUrl': secure, 'publicId': publicId};
        }
      }

      final errText = _parseCloudinaryError(data);
      // Preset قد يمنع مجلداً معيّناً — إعادة بدون folder تلقائياً
      if (folder != null &&
          folder.isNotEmpty &&
          (status == 400 || status == 401) &&
          attempt == 1) {
        debugPrint('[Cloudinary] إعادة الرفع بدون folder بسبب: $errText');
        return _uploadVideoViaDio(
          videoFile: videoFile,
          folder: null,
          attempt: 2,
        );
      }

      throw errText;
    } on DioException catch (e) {
      if (attempt == 1 &&
          folder != null &&
          folder.isNotEmpty &&
          (e.type == DioExceptionType.badResponse ||
              e.response?.statusCode == 400)) {
        debugPrint('[Cloudinary] Dio 400، إعادة بدون folder');
        return _uploadVideoViaDio(
          videoFile: videoFile,
          folder: null,
          attempt: 2,
        );
      }
      final body = e.response?.data;
      final msg = _parseCloudinaryError(body);
      debugPrint('Cloudinary DioException: ${e.type} — $msg');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw 'تعذر الاتصال بـ Cloudinary — تحقق من الشبكة وحاول مجدداً ($msg)';
      }
      throw 'Cloudinary (${e.response?.statusCode}): $msg';
    }
  }

  /// رفع احتياطي عبر الحزمة cloudinary_public.
  Future<Map<String, String>> _uploadVideoViaPackage({
    required File videoFile,
    String? folder,
  }) async {
    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        videoFile.path,
        resourceType: CloudinaryResourceType.Video,
        folder: folder,
      ),
    );
    final secure = response.secureUrl;
    final pid = response.publicId;
    if (secure.isEmpty) throw 'لم يُرجع Cloudinary رابط الفيديو';
    return {'secureUrl': secure, 'publicId': pid};
  }

  /// رفع فيديو إلى Cloudinary وحفظ البيانات في Firebase
  Future<Map<String, dynamic>?> uploadVideo({
    required File videoFile,
    required String userId,
    required String caption,
    required String userName,
    String? folder = 'reels',
  }) async {
    try {
      debugPrint('[Cloudinary] بدء الرفع — preset=$uploadPreset cloud=$cloudName');

      if (!videoFile.existsSync()) {
        throw 'ملف الفيديو غير موجود';
      }

      final int videoBytes = await videoFile.length();
      const int maxBytes = 100 * 1024 * 1024;
      if (videoBytes > maxBytes) {
        throw 'حجم الفيديو كبير جداً (الحد 100 ميجا)';
      }

      Map<String, String> uploaded;
      try {
        uploaded = await _uploadVideoViaDio(
          videoFile: videoFile,
          folder: folder,
        );
      } catch (dioErr) {
        debugPrint('[Cloudinary] Dio فشل، جاري المحاولة بالحزمة: $dioErr');
        try {
          uploaded = await _uploadVideoViaPackage(
            videoFile: videoFile,
            folder: folder,
          );
        } catch (pkgErr) {
          debugPrint('[Cloudinary] الحزمة فشلت بدون folder: $pkgErr');
          uploaded = await _uploadVideoViaPackage(
            videoFile: videoFile,
            folder: null,
          );
        }
      }

      final videoUrl = uploaded['secureUrl']!;
      final publicId = uploaded['publicId']!;

      final DatabaseReference reelRef = _firebaseDatabase.ref(reelsPath).push();
      final reelId = reelRef.key ?? DateTime.now().millisecondsSinceEpoch.toString();

      final searchText = buildReelSearchText(
        caption: caption,
        userName: userName,
        userId: userId,
        reelId: reelId,
        publicId: publicId,
      );

      final Map<String, dynamic> reelData = {
        'videoUrl': videoUrl,
        'publicId': publicId,
        'userId': userId,
        'userName': userName,
        'caption': caption,
        'searchText': searchText,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'saves': 0,
        'views': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'userProfilePic': '',
        'thumbnail': _generateThumbnailUrl(videoUrl),
        'duration': 0,
        'status': 'published',
      };

      await reelRef.set(reelData);
      await _firebaseDatabase.ref('$legacyReelsPath/$reelId').set(reelData);

      debugPrint('[Cloudinary] تم الحفظ في Firebase: $reelId');

      return {
        'success': true,
        'videoUrl': videoUrl,
        'publicId': publicId,
        'reelId': reelId,
        'message': 'تم رفع الفيديو وحفظه بنجاح',
      };
    } catch (e, st) {
      debugPrint('خطأ الرفع: $e\n$st');
      return {
        'success': false,
        'error':
            'فشل الرفع: $e — تأكد: Cloud Name=$cloudName، Preset=$uploadPreset (Unsigned)، ونوع المورد video.',
      };
    }
  }

  String _generateThumbnailUrl(String videoUrl) {
    try {
      if (videoUrl.contains('.mp4')) {
        return videoUrl
            .replaceAll('.mp4', '.jpg')
            .replaceFirst('/upload/', '/upload/so_0/');
      }
      if (videoUrl.contains('.mov')) {
        return videoUrl
            .replaceAll('.mov', '.jpg')
            .replaceFirst('/upload/', '/upload/so_0/');
      }
      return videoUrl;
    } catch (_) {
      return '';
    }
  }

  Stream<List<Map<String, dynamic>>> getReelsStream() {
    return _firebaseDatabase.ref(reelsPath).onValue.asyncMap((event) async {
      dynamic rawData = event.snapshot.value;

      if (rawData == null) {
        final legacySnapshot = await _firebaseDatabase.ref(legacyReelsPath).get();
        rawData = legacySnapshot.value;
      }

      if (rawData == null) return <Map<String, dynamic>>[];

      List<Map<String, dynamic>> reels = [];

      if (rawData is Map) {
        reels = rawData.entries.map((e) {
          final data = Map<String, dynamic>.from(e.value as Map);
          data['id'] = e.key;
          return data;
        }).toList();
      } else if (rawData is List) {
        reels = rawData
            .asMap()
            .entries
            .where((e) => e.value != null)
            .map((e) {
              final data = Map<String, dynamic>.from(e.value as Map);
              data['id'] = e.key.toString();
              return data;
            })
            .toList();
      }

      reels.sort((a, b) {
        final dateA = a['createdAt'] ?? '';
        final dateB = b['createdAt'] ?? '';
        return dateB.compareTo(dateA);
      });

      return reels;
    });
  }

  /// رفع صورة إلى Cloudinary (لصورة البروفايل)
  Future<Map<String, dynamic>?> uploadImage({
    required File imageFile,
    required String userId,
    required String userName,
    String? folder = 'profile_pics',
  }) async {
    try {
      debugPrint('[Cloudinary] بدء رفع الصورة — preset=$uploadPreset cloud=$cloudName');

      if (!imageFile.existsSync()) {
        throw 'ملف الصورة غير موجود';
      }

      final int imageBytes = await imageFile.length();
      const int maxBytes = 10 * 1024 * 1024; // 10MB limit for images
      if (imageBytes > maxBytes) {
        throw 'حجم الصورة كبير جداً (الحد 10 ميجا)';
      }

      // Use the cloudinary_public package for image upload
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
        ),
      );

      final imageUrl = response.secureUrl;
      final publicId = response.publicId;

      if (imageUrl.isEmpty) {
        throw 'لم يُرجع Cloudinary رابط الصورة';
      }

      debugPrint('[Cloudinary] تم رفع الصورة: $imageUrl');

      return {
        'success': true,
        'url': imageUrl,
        'publicId': publicId,
        'message': 'تم رفع الصورة بنجاح',
      };
    } catch (e, st) {
      debugPrint('خطأ رفع الصورة: $e\n$st');
      return {
        'success': false,
        'error': 'فشل رفع الصورة: $e',
      };
    }
  }

  /// فيديوهات مستخدم واحد (للبروفايل بتصميم تيك توك).
  Stream<List<Map<String, dynamic>>> getUserReelsStream(String userId) {
    return getReelsStream().map(
      (list) => list.where((r) => r['userId']?.toString() == userId).toList(),
    );
  }
}
