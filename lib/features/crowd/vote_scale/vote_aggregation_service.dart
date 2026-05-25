import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/deterministic_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/aggregation_determinism_verifier.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/match_vote_aggregator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/sharded_vote_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_aggregation_logic.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/aggregation_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_metrics.dart';

/// تجميع الأصوات عند الإغلاق فقط — لا يُستدعى أثناء التصويت الحي.
class VoteAggregationService implements MatchVoteAggregator {
  VoteAggregationService({
    required ShardedVoteRepository shardedVotes,
    AggregationDeterminismVerifier? verifier,
  })  : _sharded = shardedVotes,
        _verifier = verifier ?? const AggregationDeterminismVerifier();

  final ShardedVoteRepository _sharded;
  final AggregationDeterminismVerifier _verifier;

  @override
  Future<MatchVoteAggregationResult> aggregateMatch({
    required String clubTag,
    required String matchId,
    required List<MatchPitchPlayer> players,
    required bool preferShardedSource,
  }) {
    return AggregationCostGuard.instance.runBounded(
      matchId: matchId,
      work: () => _aggregateMatchBody(
        clubTag: clubTag,
        matchId: matchId,
        players: players,
        preferShardedSource: preferShardedSource,
      ),
    );
  }

  Future<MatchVoteAggregationResult> _aggregateMatchBody({
    required String clubTag,
    required String matchId,
    required List<MatchPitchPlayer> players,
    required bool preferShardedSource,
  }) async {
    final sw = Stopwatch()..start();
    final club = clubTag.trim().toLowerCase();

    var usedSharded = false;
    var usedLegacy = false;
    Map<String, int> totals = {};

    final hasShards = preferShardedSource &&
        await _sharded.hasAnyShardData(clubTag: club, matchId: matchId);

    if (preferShardedSource && hasShards) {
      totals = await _sharded.aggregateMatchShards(
        clubTag: club,
        matchId: matchId,
        playerIds: players.map((p) => p.id),
      );
      usedSharded = true;
    } else if (!preferShardedSource) {
      final legacy = <String, int>{};
      for (final p in players) {
        if (p.votes > 0) legacy[p.id] = p.votes;
      }
      if (legacy.isNotEmpty) {
        totals = legacy;
        usedLegacy = true;
      }
    }

    if (kDebugMode && usedSharded && totals.isNotEmpty) {
      final report = _verifier.verifyTwice(
        shardsByPlayer: {
          for (final pid in players.map((p) => p.id))
            pid: <String, int>{'_sum': totals[pid] ?? 0},
        },
        playerIds: players.map((p) => p.id),
      );
      DeterministicRuntimeReport.instance
          .recordAggregationChecksum(report.checksum);
      if (!report.deterministic) {
        DeterministicRuntimeReport.instance.recordAggregationMismatch(
          detail: report.toJson().toString(),
        );
      }
    }

    sw.stop();
    VoteScaleMetrics.instance.recordAggregation(sw.elapsed);

    return buildAggregationResult(
      players: players,
      shardTotals: totals,
      usedShardedSource: usedSharded,
      usedLegacySource: usedLegacy,
    );
  }
}
