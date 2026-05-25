import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/match_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/period_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/awards_consistency_verifier.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/monthly_aggregation_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/season_aggregation_service.dart';

/// تحقق سلامة التجميع — إعادة حساب فقط إذا المستند ناقص، بدون overwrite.
class AwardsAggregationIntegrityService {
  AwardsAggregationIntegrityService(
    this._awards, {
    AwardsConsistencyVerifier? verifier,
    MonthlyAggregationService? monthly,
    SeasonAggregationService? season,
  })  : _verifier = verifier ?? AwardsConsistencyVerifier(_awards),
        _monthly = monthly ?? MonthlyAggregationService(_awards),
        _season = season ?? SeasonAggregationService(_awards);

  final AwardsRepository _awards;
  final AwardsConsistencyVerifier _verifier;
  final MonthlyAggregationService _monthly;
  final SeasonAggregationService _season;

  Future<void> onHallOfFameOpen({
    required String clubTag,
    required String? monthKey,
    required String? seasonKey,
    required int anchorClosedAtServerMs,
    PeriodWinnerAward? monthly,
    PeriodWinnerAward? season,
    List<MatchWinnerAward> timeline = const [],
  }) async {
    await _verifier.verifyHallOfFame(
      clubTag: clubTag,
      monthKey: monthKey,
      seasonKey: seasonKey,
      monthly: monthly,
      season: season,
      timeline: timeline,
    );

    if (monthKey != null &&
        monthKey.isNotEmpty &&
        monthly == null &&
        anchorClosedAtServerMs > 0) {
      debugPrint(
        '[AwardsIntegrity] recompute missing monthly:$monthKey for $clubTag',
      );
      await _monthly.computeAndPersist(
        clubTag: clubTag,
        monthKey: monthKey,
        closedAtServerMs: anchorClosedAtServerMs,
      );
    }

    if (seasonKey != null &&
        seasonKey.isNotEmpty &&
        season == null &&
        anchorClosedAtServerMs > 0) {
      debugPrint(
        '[AwardsIntegrity] recompute missing season:$seasonKey for $clubTag',
      );
      await _season.computeAndPersist(
        clubTag: clubTag,
        seasonKey: seasonKey,
        closedAtServerMs: anchorClosedAtServerMs,
      );
    }

    await _verifyPlayerRollups(clubTag);
  }

  Future<void> onSessionFinalized({
    required String clubTag,
    required String monthKey,
    required String seasonKey,
    required int closedAtServerMs,
  }) async {
    final monthly = await _awards.getMonthly(clubTag: clubTag, monthKey: monthKey);
    if (monthly == null) {
      await _monthly.computeAndPersist(
        clubTag: clubTag,
        monthKey: monthKey,
        closedAtServerMs: closedAtServerMs,
      );
    }
    final season = await _awards.getSeason(clubTag: clubTag, seasonKey: seasonKey);
    if (season == null) {
      await _season.computeAndPersist(
        clubTag: clubTag,
        seasonKey: seasonKey,
        closedAtServerMs: closedAtServerMs,
      );
    }
  }

  Future<void> _verifyPlayerRollups(String clubTag) async {
    final rollups = await _awards.listPlayerAwardRollups(clubTag: clubTag);
    for (final e in rollups.entries) {
      final m = e.value;
      final wins = m['matchWins'];
      if (wins is num && wins < 0) {
        debugPrint(
          '[AwardsIntegrity] WARN player ${e.key}: negative matchWins',
        );
      }
    }
  }
}
