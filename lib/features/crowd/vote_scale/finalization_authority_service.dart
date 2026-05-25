import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_time_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/award_card_snapshot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/match_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/awards_aggregation_integrity_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/monthly_aggregation_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/season_aggregation_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/match_vote_aggregator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/match_voting_authority.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/deterministic_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_idempotency_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/aggregation_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_metrics.dart';

/// إغلاق موحّد للجلسة — تجميع شاردات + لقطة جوائز idempotent.
class FinalizationAuthorityService implements MatchVotingAuthority {
  FinalizationAuthorityService({
    required MatchVotesRepository votesRepository,
    required AwardsRepository awardsRepository,
    required MatchVoteAggregator aggregator,
    required String clubTag,
    MonthlyAggregationService? monthlyAggregation,
    SeasonAggregationService? seasonAggregation,
    AwardsAggregationIntegrityService? integrity,
  })  : _votes = votesRepository,
        _awards = awardsRepository,
        _aggregator = aggregator,
        _clubTag = clubTag.trim().toLowerCase(),
        _monthly = monthlyAggregation ??
            MonthlyAggregationService(awardsRepository),
        _season =
            seasonAggregation ?? SeasonAggregationService(awardsRepository),
        _integrity = integrity ??
            AwardsAggregationIntegrityService(awardsRepository);

  final MatchVotesRepository _votes;
  final AwardsRepository _awards;
  final MatchVoteAggregator _aggregator;
  final String _clubTag;
  final MonthlyAggregationService _monthly;
  final SeasonAggregationService _season;
  final AwardsAggregationIntegrityService _integrity;

  final Set<String> _localFinalized = {};

  @override
  Future<bool> finalizeMatch({
    required String clubTag,
    required MatchVotesBundle bundle,
    required int closedAtServerMs,
  }) async {
    if (clubTag.trim().toLowerCase() != _clubTag) {
      debugPrint('[FinalizeAuthority] club mismatch');
      return false;
    }

    final m = bundle.match;
    if (m == null || m.id.isEmpty) return false;
    if (m.awardsFinalized) {
      _localFinalized.add(m.id);
      return true;
    }
    if (_localFinalized.contains(m.id)) {
      VoteScaleMetrics.instance.recordDuplicateFinalize();
      DeterministicRuntimeReport.instance.recordFinalizeRacePrevented();
      return true;
    }

    final finalizeFp = VoteOperationFingerprint(
      uid: _clubTag,
      playerId: '',
      matchId: m.id,
      clubTag: _clubTag,
      operationType: VoteOperationType.finalize,
      createdAtBucket: VoteOperationFingerprint.bucketFromMs(closedAtServerMs),
    );
    if (!VoteIdempotencyGuard.finalize.tryAcquire(finalizeFp)) {
      VoteScaleMetrics.instance.recordDuplicateFinalize();
      DeterministicRuntimeReport.instance.recordFinalizeRacePrevented();
      _localFinalized.add(m.id);
      return true;
    }

    final sw = Stopwatch()..start();
    var ok = false;
    try {
      await _votes.adminUpdateSessionStatus(
        clubTag: _clubTag,
        status: 'finalizing',
        votingEnabled: false,
      );

      final time = AwardsTimeResolver.fromClosedAtServer(closedAtServerMs);

      final existing = await _awards.getMatchAward(
        clubTag: _clubTag,
        year: time.calendarYear,
        matchId: m.id,
      );
      if (existing != null) {
        await _awards.claimSessionFinalized(
          clubTag: _clubTag,
          matchId: m.id,
          closedAtServer: closedAtServerMs,
        );
        _localFinalized.add(m.id);
        ok = true;
        return true;
      }

      final agg = await _aggregator.aggregateMatch(
        clubTag: _clubTag,
        matchId: m.id,
        players: bundle.players,
        preferShardedSource: m.usesShardedVotes,
      );

      if (agg.winnerPlayerId == null || agg.winnerVotes <= 0) {
        await _awards.claimSessionFinalized(
          clubTag: _clubTag,
          matchId: m.id,
          closedAtServer: closedAtServerMs,
        );
        _localFinalized.add(m.id);
        ok = true;
        return true;
      }

      final winnerId = agg.winnerPlayerId!;
      MatchPitchPlayer? winnerPlayer;
      for (final p in bundle.players) {
        if (p.id == winnerId) {
          winnerPlayer = p;
          break;
        }
      }
      winnerPlayer ??= MatchPitchPlayer(
        id: winnerId,
        name: winnerId,
        imageUrl: '',
        rating: 0,
        position: '',
        x: 0.5,
        y: 0.5,
        votes: agg.winnerVotes,
        team: '',
        glowColor: 'gold',
      );

      final cardSnaps = <String, AwardCardSnapshot>{};
      for (final e in agg.playerTotals.entries) {
        if (e.value <= 0) continue;
        for (final p in bundle.players) {
          if (p.id == e.key) {
            cardSnaps[e.key] = AwardCardSnapshot.fromPlayer(p);
            break;
          }
        }
      }

      final award = MatchWinnerAward(
        matchId: m.id,
        title: m.title,
        opponent: m.opponent,
        sessionType: m.sessionType,
        winnerPlayerId: winnerId,
        winnerName: winnerPlayer.name,
        winnerCardSnapshot: AwardCardSnapshot.fromPlayer(winnerPlayer),
        totalVotes: agg.winnerVotes,
        closedAt: closedAtServerMs,
        finalizedAtServer: closedAtServerMs,
        monthKey: time.monthKey,
        seasonKey: time.seasonKey,
        playerVoteTotals: agg.playerTotals,
        playerCardSnapshots: cardSnaps,
      );

      final snapshotCreated = await _awards.tryWriteMatchAwardTransaction(
        clubTag: _clubTag,
        year: time.calendarYear,
        award: award,
      );

      if (snapshotCreated) {
        await _awards.upsertPlayerAwardRollup(
          clubTag: _clubTag,
          playerId: winnerId,
          patch: {
            'playerId': winnerId,
            'playerName': winnerPlayer.name,
            'lastMatchWinAt': closedAtServerMs,
            'matchWins': ServerValue.increment(1),
            'totalMatchVotes': ServerValue.increment(agg.winnerVotes),
            'cardSnapshot': award.winnerCardSnapshot.toMap(),
          },
        );

        if (!AggregationCostGuard.instance.shouldSkipMonthlyRecompute(
          clubTag: _clubTag,
          monthKey: time.monthKey,
        )) {
          await _monthly.computeAndPersist(
            clubTag: _clubTag,
            monthKey: time.monthKey,
            closedAtServerMs: closedAtServerMs,
          );
        }
        if (!AggregationCostGuard.instance.shouldSkipSeasonRecompute(
          clubTag: _clubTag,
          seasonKey: time.seasonKey,
        )) {
          await _season.computeAndPersist(
            clubTag: _clubTag,
            seasonKey: time.seasonKey,
            closedAtServerMs: closedAtServerMs,
          );
        }
        await _integrity.onSessionFinalized(
          clubTag: _clubTag,
          monthKey: time.monthKey,
          seasonKey: time.seasonKey,
          closedAtServerMs: closedAtServerMs,
        );
      }

      final claimed = await _awards.claimSessionFinalized(
        clubTag: _clubTag,
        matchId: m.id,
        closedAtServer: closedAtServerMs,
      );

      ok = snapshotCreated || claimed;
      if (ok) _localFinalized.add(m.id);
      return ok;
    } catch (e, st) {
      debugPrint('[FinalizeAuthority] error: $e\n$st');
      VoteScaleMetrics.instance.recordFailedWrite(e);
      return false;
    } finally {
      sw.stop();
      VoteScaleMetrics.instance.recordFinalize(sw.elapsed, success: ok);
    }
  }
}
