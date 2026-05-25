import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// نتيجة تجميع أصوات جلسة واحدة.
class MatchVoteAggregationResult {
  const MatchVoteAggregationResult({
    required this.playerTotals,
    required this.sessionTotal,
    this.winnerPlayerId,
    this.winnerVotes = 0,
    this.usedShardedSource = false,
    this.usedLegacySource = false,
  });

  final Map<String, int> playerTotals;
  final int sessionTotal;
  final String? winnerPlayerId;
  final int winnerVotes;
  final bool usedShardedSource;
  final bool usedLegacySource;
}

/// تجميع الأصوات — يُنفَّذ عند الإغلاق فقط (جاهز للـ Cloud Functions).
abstract class MatchVoteAggregator {
  Future<MatchVoteAggregationResult> aggregateMatch({
    required String clubTag,
    required String matchId,
    required List<MatchPitchPlayer> players,
    required bool preferShardedSource,
  });
}
