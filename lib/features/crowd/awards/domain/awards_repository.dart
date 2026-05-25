import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/match_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/period_winner_award.dart';

abstract class AwardsRepository {
  /// يكتب اللقطة إن لم تكن موجودة — يعيد false إذا كانت موجودة مسبقاً.
  Future<bool> tryWriteMatchAward({
    required String clubTag,
    required int year,
    required MatchWinnerAward award,
  });

  /// إنشاء لقطة المباراة داخل transaction — append-only.
  Future<bool> tryWriteMatchAwardTransaction({
    required String clubTag,
    required int year,
    required MatchWinnerAward award,
  });

  /// يضبط [awardsFinalized] مرة واحدة فقط داخل transaction.
  Future<bool> claimSessionFinalized({
    required String clubTag,
    required String matchId,
    required int closedAtServer,
  });

  Future<MatchWinnerAward?> getMatchAward({
    required String clubTag,
    required int year,
    required String matchId,
  });

  Future<List<MatchWinnerAward>> listMatchAwardsForYear({
    required String clubTag,
    required int year,
  });

  Future<List<MatchWinnerAward>> listRecentMatchAwards({
    required String clubTag,
    int limit = 10,
    int? anchorClosedAtServerMs,
  });

  Future<PeriodWinnerAward?> getMonthly({
    required String clubTag,
    required String monthKey,
  });

  Future<void> setMonthly({
    required String clubTag,
    required String monthKey,
    required PeriodWinnerAward award,
  });

  Future<PeriodWinnerAward?> getSeason({
    required String clubTag,
    required String seasonKey,
  });

  Future<void> setSeason({
    required String clubTag,
    required String seasonKey,
    required PeriodWinnerAward award,
  });

  Future<void> upsertPlayerAwardRollup({
    required String clubTag,
    required String playerId,
    required Map<String, dynamic> patch,
  });

  /// قراءة `player_awards/{club}` — للإرث الشخصي والتحقق.
  Future<Map<String, Map<String, dynamic>>> listPlayerAwardRollups({
    required String clubTag,
  });
}
