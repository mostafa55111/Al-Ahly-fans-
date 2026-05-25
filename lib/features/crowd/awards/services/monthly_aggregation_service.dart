import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_time_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/award_card_snapshot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/match_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/period_winner_award.dart';

/// تجميع نسر/فارس الشهر من مجموع أصوات الجلسات (وليس عدد مرات الفوز).
class MonthlyAggregationService {
  MonthlyAggregationService(this._awards);

  final AwardsRepository _awards;

  Future<PeriodWinnerAward?> computeAndPersist({
    required String clubTag,
    required String monthKey,
    required int closedAtServerMs,
  }) async {
    final year = int.tryParse(monthKey.substring(0, 4)) ??
        AwardsTimeResolver.calendarYear(closedAtServerMs);
    final matches = await _awards.listMatchAwardsForYear(
      clubTag: clubTag,
      year: year,
    );
    final inMonth =
        matches.where((m) => m.monthKey == monthKey).toList(growable: false);
    if (inMonth.isEmpty) return null;

    final winner = _aggregateFromMatches(inMonth, closedAtServerMs);
    if (winner == null) return null;

    await _awards.setMonthly(
      clubTag: clubTag,
      monthKey: monthKey,
      award: winner,
    );
    return winner;
  }

  PeriodWinnerAward? _aggregateFromMatches(
    List<MatchWinnerAward> matches,
    int finalizedAt,
  ) {
    final voteTotals = <String, int>{};
    final winCounts = <String, int>{};
    final names = <String, String>{};
    final cards = <String, AwardCardSnapshot>{};

    for (final m in matches) {
      winCounts[m.winnerPlayerId] = (winCounts[m.winnerPlayerId] ?? 0) + 1;
      names[m.winnerPlayerId] = m.winnerName;
      cards[m.winnerPlayerId] = m.winnerCardSnapshot;

      m.playerVoteTotals.forEach((pid, votes) {
        if (pid.isEmpty || votes <= 0) return;
        voteTotals[pid] = (voteTotals[pid] ?? 0) + votes;
        final snap = m.playerCardSnapshots[pid];
        if (snap != null) cards[pid] = snap;
        if (snap != null && snap.name.isNotEmpty) names[pid] = snap.name;
      });
    }

    if (voteTotals.isEmpty) return null;

    var bestId = '';
    var bestVotes = -1;
    voteTotals.forEach((pid, v) {
      if (v > bestVotes) {
        bestVotes = v;
        bestId = pid;
      }
    });
    if (bestId.isEmpty) return null;

    final card = cards[bestId] ??
        AwardCardSnapshot(playerId: bestId, name: names[bestId] ?? '');

    return PeriodWinnerAward(
      playerId: bestId,
      playerName: names[bestId] ?? card.name,
      totalVotes: bestVotes,
      winsCount: winCounts[bestId] ?? 0,
      cardSnapshot: card,
      finalizedAt: finalizedAt,
    );
  }
}
