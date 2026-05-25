import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/models/owner_card_record.dart';

class OwnerSessionValidation {
  const OwnerSessionValidation({required this.ok, this.message});

  final bool ok;
  final String? message;
}

/// قواعد تشغيل المالك — جلسة واحدة، تشكيلة صالحة.
abstract final class OwnerSessionRules {
  static const int minStarters = 11;
  static const int maxDurationMinutes = 180;
  static const int minDurationMinutes = 5;

  static OwnerSessionValidation validateNewSession({
    MatchActiveSession? existing,
    required String formation,
    required List<String> starterIds,
    required List<String> benchIds,
    required int durationMinutes,
  }) {
    if (existing != null &&
        existing.id.isNotEmpty &&
        existing.votingEnabled) {
      return const OwnerSessionValidation(
        ok: false,
        message: 'يوجد جلسة نشطة — أغلقها قبل إنشاء جلسة جديدة',
      );
    }

    if (!_supportedFormations.contains(formation)) {
      return const OwnerSessionValidation(
        ok: false,
        message: 'تشكيلة غير مدعومة',
      );
    }

    if (starterIds.length < minStarters) {
      return OwnerSessionValidation(
        ok: false,
        message: 'يلزم $minStarters لاعباً أساسياً على الأقل',
      );
    }

    final dup = _duplicatePlayer(starterIds, benchIds);
    if (dup != null) {
      return OwnerSessionValidation(
        ok: false,
        message: 'لاعب مكرر في التشكيلة: $dup',
      );
    }

    if (durationMinutes < minDurationMinutes ||
        durationMinutes > maxDurationMinutes) {
      return OwnerSessionValidation(
        ok: false,
        message:
            'مدة الجلسة بين $minDurationMinutes و $maxDurationMinutes دقيقة',
      );
    }

    return const OwnerSessionValidation(ok: true);
  }

  static OwnerSessionValidation validateCardForLineup(OwnerCardRecord card) {
    if (card.imageUrl.trim().isEmpty) {
      return const OwnerSessionValidation(
        ok: false,
        message: 'الكرت بلا صورة',
      );
    }
    if (card.isArchived) {
      return const OwnerSessionValidation(
        ok: false,
        message: 'الكرت مؤرشف',
      );
    }
    return const OwnerSessionValidation(ok: true);
  }

  static const _supportedFormations = [
    '4-3-3',
    '4-2-3-1',
    '4-4-2',
    '3-4-3',
    '3-5-2',
  ];

  static String? _duplicatePlayer(List<String> starters, List<String> bench) {
    final seen = <String>{};
    for (final id in [...starters, ...bench]) {
      if (id.isEmpty) continue;
      if (seen.contains(id)) return id;
      seen.add(id);
    }
    return null;
  }
}
