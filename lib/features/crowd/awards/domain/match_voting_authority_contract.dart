import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/match_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/period_winner_award.dart';

/// عقود السلطة من الخادم — بدون تنفيذ Cloud Functions بعد.
abstract class MatchVotingAuthorityService {
  Future<void> finalizeVoting({
    required String clubTag,
    required String matchId,
  });

  Future<void> aggregateVotes({
    required String clubTag,
    required String matchId,
  });

  Future<void> publishAwards({
    required String clubTag,
    required MatchWinnerAward matchAward,
    PeriodWinnerAward? monthly,
    PeriodWinnerAward? season,
  });
}
