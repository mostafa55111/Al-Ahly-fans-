import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/card_media_optimizer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/card_media_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/card_repository/crowd_card_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/models/owner_card_record.dart';
import 'package:uuid/uuid.dart';

/// رفع كرت من التطبيق — Cloudinary + مستودع معزول.
class OwnerCardUploadService {
  OwnerCardUploadService({
    required CloudinaryService cloudinary,
    required CrowdCardRepository repository,
  })  : _cloudinary = cloudinary,
        _repository = repository;

  final CloudinaryService _cloudinary;
  final CrowdCardRepository _repository;
  final _uuid = const Uuid();

  Future<OwnerCardRecord> uploadFromFile({
    required File imageFile,
    required String playerName,
    required int playerNumber,
    required String position,
    String? dominantColor,
  }) async {
    final appId = FanAppIdentity.registryAppId;
    final bytes = await imageFile.length();
    const validator = CardMediaValidator();
    const optimizer = CardMediaOptimizer();
    final check = validator.validate(
      fileNameOrPath: imageFile.path,
      fileSizeBytes: bytes,
    );
    if (!check.passed) {
      throw StateError(
        optimizer.adviseBeforeUpload(
              fileNameOrPath: imageFile.path,
              fileSizeBytes: bytes,
            ) ??
            'صورة غير مقبولة',
      );
    }

    final imageUrl = await _cloudinary.uploadImage(imageFile);
    final thumb = _thumbnailUrl(imageUrl);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final card = OwnerCardRecord(
      id: _uuid.v4(),
      playerName: playerName.trim().isEmpty ? 'لاعب' : playerName.trim(),
      playerNumber: playerNumber,
      position: position.trim().toUpperCase(),
      imageUrl: imageUrl,
      thumbnailUrl: thumb,
      dominantColor: dominantColor ?? '',
      createdAtServer: DateTime.now().millisecondsSinceEpoch,
      ownerUid: uid,
      appId: appId,
    );

    await _repository.upsertCard(appId: appId, card: card);
    return card;
  }

  static String _thumbnailUrl(String fullUrl) {
    if (!fullUrl.contains('cloudinary.com') || !fullUrl.contains('/upload/')) {
      return fullUrl;
    }
    return fullUrl.replaceFirst('/upload/', '/upload/c_scale,w_320/');
  }
}
