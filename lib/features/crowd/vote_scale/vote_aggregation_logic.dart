import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/match_vote_aggregator.dart';

/// منطق تجميع خالٍ من Firebase — للاختبار والإغلاق.
MatchVoteAggregationResult buildAggregationResult({
  required List<MatchPitchPlayer> players,
  required Map<String, int> shardTotals,
  required bool usedShardedSource,
  required bool usedLegacySource,
}) {
  var totals = <String, int>{};
  var usedSharded = false;
  var usedLegacy = false;

  if (usedShardedSource && shardTotals.values.any((v) => v > 0)) {
    totals = Map<String, int>.from(shardTotals);
    usedSharded = true;
  } else {
    for (final p in players) {
      if (p.votes > 0) {
        totals[p.id] = p.votes;
        usedLegacy = true;
      }
    }
  }

  if (usedLegacySource && !usedLegacy && totals.isEmpty) {
    usedLegacy = usedLegacySource;
  }

  final winner = pickWinnerFromTotals(totals);
  final sessionTotal = totals.values.fold<int>(0, (a, b) => a + b);

  return MatchVoteAggregationResult(
    playerTotals: totals,
    sessionTotal: sessionTotal,
    winnerPlayerId: winner?.$1,
    winnerVotes: winner?.$2 ?? 0,
    usedShardedSource: usedSharded,
    usedLegacySource: usedLegacy,
  );
}

(String, int)? pickWinnerFromTotals(Map<String, int> totals) {
  if (totals.isEmpty) return null;
  var bestId = '';
  var bestVotes = 0;
  totals.forEach((id, votes) {
    if (votes > bestVotes) {
      bestVotes = votes;
      bestId = id;
    }
  });
  if (bestVotes <= 0 || bestId.isEmpty) return null;
  return (bestId, bestVotes);
}
