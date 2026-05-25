import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_runtime/owner_session_rules.dart';

/// تحقق شامل قبل إطلاق الجلسة — يمنع جلسات مكسورة.
abstract final class LaunchValidator {
  static const double starterPitchYThreshold = 0.88;
  static const int maxBench = 12;

  static OwnerSessionValidation validateLaunch({
    MatchActiveSession? existing,
    required String formation,
    required List<MatchPitchPlayer> players,
    required int durationMinutes,
  }) {
    final starters = players.where((p) => p.y < starterPitchYThreshold).toList();
    final bench = players.where((p) => p.y >= starterPitchYThreshold).toList();

  final base = OwnerSessionRules.validateNewSession(
      existing: existing,
      formation: formation,
      starterIds: starters.map((p) => p.id).toList(),
      benchIds: bench.map((p) => p.id).toList(),
      durationMinutes: durationMinutes,
    );
    if (!base.ok) return base;

    if (starters.length != OwnerSessionRules.minStarters) {
      return OwnerSessionValidation(
        ok: false,
        message: 'يلزم ${OwnerSessionRules.minStarters} أساسيين بالضبط',
      );
    }

    if (bench.length > maxBench) {
      return OwnerSessionValidation(
        ok: false,
        message: 'عدد البدلاء يتجاوز $maxBench',
      );
    }

    final gk = starters.any((p) => _isGoalkeeper(p));
    if (!gk) {
      return const OwnerSessionValidation(
        ok: false,
        message: 'حارس المرمى غير موجود في الأساسي',
      );
    }

    final nameDup = _duplicateNames(starters, bench);
    if (nameDup != null) {
      return OwnerSessionValidation(
        ok: false,
        message: 'اسم لاعب مكرر: $nameDup',
      );
    }

    for (final p in players) {
      if (p.name.trim().isEmpty) {
        return OwnerSessionValidation(
          ok: false,
          message: 'لاعب بلا اسم',
        );
      }
      final img = p.cardImageUrl.trim().isNotEmpty
          ? p.cardImageUrl.trim()
          : p.imageUrl.trim();
      if (img.isEmpty) {
        return OwnerSessionValidation(
          ok: false,
          message: 'صورة الكرت مفقودة: ${p.name}',
        );
      }
    }

    return const OwnerSessionValidation(ok: true);
  }

  static bool _isGoalkeeper(MatchPitchPlayer p) {
    final pos = p.position.trim().toUpperCase();
    return pos == 'GK' || pos == 'G' || pos.contains('GOAL');
  }

  static String? _duplicateNames(
    List<MatchPitchPlayer> starters,
    List<MatchPitchPlayer> bench,
  ) {
    final seen = <String>{};
    for (final p in [...starters, ...bench]) {
      final n = p.name.trim().toLowerCase();
      if (n.isEmpty) continue;
      if (seen.contains(n)) return p.name;
      seen.add(n);
    }
    return null;
  }
}
