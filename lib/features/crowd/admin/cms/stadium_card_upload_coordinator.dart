import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_pending_op.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_repository.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/card_media_optimizer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/card_media_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/card_ownership_registry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/card_upload_protection.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_audit_log.dart';
import 'package:uuid/uuid.dart';

/// رفع كروت مع إعادة محاولة + طابور معلّق عند فشل الشبكة.
class StadiumCardUploadCoordinator {
  StadiumCardUploadCoordinator({
    required CloudinaryService cloudinary,
    required StadiumCardRegistryRepository registry,
    required StadiumCmsRepository cms,
    required Connectivity connectivity,
  })  : _cloudinary = cloudinary,
        _registry = registry,
        _cms = cms,
        _connectivity = connectivity;

  final CloudinaryService _cloudinary;
  final StadiumCardRegistryRepository _registry;
  final StadiumCmsRepository _cms;
  final Connectivity _connectivity;
  final _uuid = const Uuid();

  static const _maxAttempts = 3;
  final CardUploadProtection _uploadGuard = const CardUploadProtection();
  final CardOwnershipRegistry _ownership = CardOwnershipRegistry();

  Future<StadiumCardRegistryEntry> saveCard({
    required String clubTag,
    required String playerName,
    required String rarity,
    required List<String> tags,
    String? imageUrl,
    File? localImage,
  }) async {
    final entry = StadiumCardRegistryEntry(
      id: _uuid.v4(),
      playerName: playerName.trim().isEmpty ? 'لاعب' : playerName.trim(),
      imageUrl: imageUrl?.trim() ?? '',
      rarity: rarity.trim(),
      club: clubTag,
      tags: tags,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final existing = await _registry.watchCards(clubTag).first;
      final resolved = await _resolveImageUrl(imageUrl: entry.imageUrl, localImage: localImage);
      var ready = _ownership.stamp(entry.copyWith(imageUrl: resolved), clubTag);
      final dup = _uploadGuard.validateDuplicate(
        candidate: ready,
        existing: existing.where((e) => !e.isArchived),
      );
      if (!dup.ok) throw StateError(dup.message ?? 'كرت مكرر');
      await _upsertWithRetry(clubTag: clubTag, entry: ready);
      if (getIt.isRegistered<OwnerAuditLog>()) {
        await getIt<OwnerAuditLog>().logCardUpload(ready.id);
      }
      return ready;
    } catch (e) {
      await _enqueueCardUpsert(
        clubTag: clubTag,
        entry: entry,
        localPath: localImage?.path,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<int> flushPending(String clubTag) async {
    final ops = await _cms.readAllPendingOps(clubTag);
    var done = 0;
    for (final op in ops) {
      if (op.kind != StadiumCmsPendingOpKind.cardRegistryUpsert) continue;
      try {
        await _replayCardUpsert(clubTag: clubTag, op: op);
        await _cms.removePendingOp(clubTag, op.id);
        done++;
      } catch (e) {
        await _cms.upsertPendingOp(
          clubTag: clubTag,
          op: op.copyWith(
            attempts: op.attempts + 1,
            lastError: e.toString(),
          ),
        );
      }
    }
    return done;
  }

  Future<void> _replayCardUpsert({
    required String clubTag,
    required StadiumCmsPendingOp op,
  }) async {
    final p = op.payload;
    final localPath = p['localPath']?.toString() ?? '';
    var url = p['imageUrl']?.toString() ?? '';
    if (url.isEmpty && localPath.isNotEmpty) {
      url = await _uploadWithRetry(File(localPath));
    }
    if (url.isEmpty) throw StateError('لا رابط صورة');

    final entry = StadiumCardRegistryEntry(
      id: p['id']?.toString() ?? _uuid.v4(),
      playerName: p['playerName']?.toString() ?? 'لاعب',
      imageUrl: url,
      rarity: p['rarity']?.toString() ?? '',
      club: p['club']?.toString() ?? clubTag,
      tags: (p['tags'] is List) ? List<String>.from((p['tags'] as List).map((e) => e.toString())) : const [],
      createdAt: (p['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
    await _upsertWithRetry(clubTag: clubTag, entry: entry);
  }

  Future<String> _resolveImageUrl({required String imageUrl, File? localImage}) async {
    if (imageUrl.isNotEmpty) return imageUrl;
    if (localImage == null) throw StateError('أضف رابطاً أو ارفع صورة');
    return _uploadWithRetry(localImage);
  }

  Future<String> _uploadWithRetry(File file) async {
    final bytes = await file.length();
    const validator = CardMediaValidator();
    const optimizer = CardMediaOptimizer();
    final check = validator.validate(
      fileNameOrPath: file.path,
      fileSizeBytes: bytes,
    );
    if (!check.passed) {
      final msg = optimizer.adviseBeforeUpload(
            fileNameOrPath: file.path,
            fileSizeBytes: bytes,
          ) ??
          'صورة غير مقبولة للرفع';
      throw StateError(msg);
    }

    Object? last;
    for (var i = 0; i < _maxAttempts; i++) {
      try {
        final connected = await _hasConnection();
        if (!connected) throw StateError('لا اتصال بالإنترنت');
        return await _cloudinary.uploadImage(file);
      } catch (e) {
        last = e;
        if (i < _maxAttempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
        }
      }
    }
    throw StateError('فشل الرفع: $last');
  }

  Future<void> _upsertWithRetry({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  }) async {
    Object? last;
    for (var i = 0; i < _maxAttempts; i++) {
      try {
        final connected = await _hasConnection();
        if (!connected) throw StateError('لا اتصال بالإنترنت');
        await _registry.upsertCard(clubTag: clubTag, entry: entry);
        return;
      } catch (e) {
        last = e;
        if (i < _maxAttempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 350 * (i + 1)));
        }
      }
    }
    throw StateError('فشل الحفظ: $last');
  }

  Future<void> _enqueueCardUpsert({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
    String? localPath,
    required String error,
  }) async {
    await _cms.upsertPendingOp(
      clubTag: clubTag,
      op: StadiumCmsPendingOp(
        id: entry.id,
        kind: StadiumCmsPendingOpKind.cardRegistryUpsert,
        payload: {
          'id': entry.id,
          'playerName': entry.playerName,
          'imageUrl': entry.imageUrl,
          'localPath': localPath ?? '',
          'rarity': entry.rarity,
          'club': entry.club,
          'tags': entry.tags,
          'createdAt': entry.createdAt,
        },
        attempts: 1,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastError: error,
      ),
    );
  }

  Future<bool> _hasConnection() async {
    final dynamic results = await _connectivity.checkConnectivity();
    if (results is List) {
      for (final item in results) {
        if (item != ConnectivityResult.none) return true;
      }
      return false;
    }
    return results != ConnectivityResult.none;
  }
}
