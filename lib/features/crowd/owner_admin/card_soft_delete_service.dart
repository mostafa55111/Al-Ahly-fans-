import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_audit_log.dart';

/// حذف ناعم — أرشفة 7 أيام قبل الإزالة النهائية (يدوياً لاحقاً).
class CardSoftDeleteService {
  CardSoftDeleteService({
    required StadiumCardRegistryRepository registry,
    OwnerAuditLog? audit,
  })  : _registry = registry,
        _audit = audit;

  static const archiveRetentionMs = 7 * 24 * 60 * 60 * 1000;

  final StadiumCardRegistryRepository _registry;
  final OwnerAuditLog? _audit;

  Future<void> archiveCard({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  }) async {
    final archived = entry.copyWith(
      archivedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _registry.upsertCard(clubTag: clubTag, entry: archived);
    await _audit?.logCardDelete(entry.id);
  }

  bool isRecoverable(StadiumCardRegistryEntry entry) {
    if (entry.archivedAt <= 0) return false;
    final age = DateTime.now().millisecondsSinceEpoch - entry.archivedAt;
    return age < archiveRetentionMs;
  }

  Future<void> restoreCard({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  }) async {
    if (!isRecoverable(entry)) {
      throw StateError('انتهت مهلة الاسترجاع (7 أيام)');
    }
    await _registry.upsertCard(
      clubTag: clubTag,
      entry: entry.copyWith(archivedAt: 0),
    );
  }

  /// حذف نهائي — مسموح فقط بعد انتهاء مهلة الاسترجاع.
  Future<void> purgeCard({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  }) async {
    if (isRecoverable(entry)) {
      throw StateError('لا يزال الكرت قابلاً للاسترجاع — أرشف فقط أو انتظر 7 أيام');
    }
    await _registry.removeCard(clubTag, entry.id);
    await _audit?.logCardDelete(entry.id);
  }
}
