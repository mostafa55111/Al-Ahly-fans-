import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/match_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/period_winner_award.dart';

/// تحقق قراءة فقط — لا يعدّل البيانات.
class AwardsConsistencyVerifier {
  AwardsConsistencyVerifier(this._awards);

  final AwardsRepository _awards;

  Future<void> verifyHallOfFame({
    required String clubTag,
    required String? monthKey,
    required String? seasonKey,
    PeriodWinnerAward? monthly,
    PeriodWinnerAward? season,
    List<MatchWinnerAward> timeline = const [],
  }) async {
    for (final m in timeline) {
      if (m.winnerPlayerId.isEmpty) {
        debugPrint(
          '[AwardsConsistency] WARN match ${m.matchId}: missing winnerPlayerId',
        );
      }
      if (m.winnerCardSnapshot.playerId.isEmpty &&
          m.winnerCardSnapshot.displayCardImageUrl.isEmpty) {
        debugPrint(
          '[AwardsConsistency] WARN match ${m.matchId}: empty winnerCardSnapshot',
        );
      }
      if (m.closedAt <= 0) {
        debugPrint(
          '[AwardsConsistency] WARN match ${m.matchId}: invalid closedAt',
        );
      }
    }

    if (monthly != null && monthKey != null && monthKey.isNotEmpty) {
      await _verifyPeriodDoc(
        clubTag: clubTag,
        label: 'monthly:$monthKey',
        stored: monthly,
        monthKey: monthKey,
      );
    }

    if (season != null && seasonKey != null && seasonKey.isNotEmpty) {
      await _verifyPeriodDoc(
        clubTag: clubTag,
        label: 'season:$seasonKey',
        stored: season,
        seasonKey: seasonKey,
      );
    }
  }

  Future<void> _verifyPeriodDoc({
    required String clubTag,
    required String label,
    required PeriodWinnerAward stored,
    String? monthKey,
    String? seasonKey,
  }) async {
    final year = int.tryParse(
      (monthKey ?? seasonKey ?? '').length >= 4
          ? (monthKey ?? seasonKey)!.substring(0, 4)
          : '',
    );
    if (year == null) return;

    final matches = await _awards.listMatchAwardsForYear(
      clubTag: clubTag,
      year: year,
    );
    final filtered = matches.where((m) {
      if (monthKey != null) return m.monthKey == monthKey;
      if (seasonKey != null) return m.seasonKey == seasonKey;
      return false;
    }).toList();

    if (filtered.isEmpty) {
      debugPrint(
        '[AwardsConsistency] WARN $label: stored doc exists but no match snapshots',
      );
      return;
    }

    final voteTotals = <String, int>{};
    for (final m in filtered) {
      m.playerVoteTotals.forEach((pid, v) {
        if (pid.isEmpty || v <= 0) return;
        voteTotals[pid] = (voteTotals[pid] ?? 0) + v;
      });
    }
    if (voteTotals.isEmpty) return;

    var bestId = '';
    var bestVotes = -1;
    voteTotals.forEach((pid, v) {
      if (v > bestVotes) {
        bestVotes = v;
        bestId = pid;
      }
    });

    if (bestId != stored.playerId) {
      debugPrint(
        '[AwardsConsistency] WARN $label: stored=${stored.playerId} '
        'recomputed=$bestId (${stored.totalVotes} vs $bestVotes votes)',
      );
    } else if (bestVotes != stored.totalVotes) {
      debugPrint(
        '[AwardsConsistency] WARN $label: totalVotes stored=${stored.totalVotes} '
        'recomputed=$bestVotes',
      );
    }
  }
}
