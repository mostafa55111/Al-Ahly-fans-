import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/load_simulation/synthetic_vote_client.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/load_simulation/synthetic_vote_scenario.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/load_simulation/vote_load_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/shard_distribution_analyzer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/verification_sandbox_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/sharded_vote_allocator.dart';

class SyntheticLoadCoordinator {
  SyntheticLoadCoordinator({
    ShardedVoteAllocator? allocator,
    ShardDistributionAnalyzer? shardAnalyzer,
    Random? random,
  })  : _allocator = allocator ?? ShardedVoteAllocator(),
        _shardAnalyzer = shardAnalyzer ?? ShardDistributionAnalyzer(),
        _random = random ?? Random();

  final ShardedVoteAllocator _allocator;
  final ShardDistributionAnalyzer _shardAnalyzer;
  final Random _random;
  final List<VoteLoadReport> _reports = [];

  List<VoteLoadReport> get reports => List.unmodifiable(_reports);

  Future<VoteLoadReport> run({
    required SyntheticVoteScenario scenario,
    required int virtualVoters,
    Duration? maxDuration,
    int? maxVotes,
  }) async {
    if (!VerificationSandboxGuard.isVerificationAllowed) {
      throw StateError('load simulation only in debug builds');
    }

    final cappedVoters = virtualVoters.clamp(100, 1000000);
    final sessionId = VerificationSandboxGuard.newSandboxSessionId(scenario.wireName);
    VerificationSandboxGuard.assertSandboxSession(sessionId);

    final sw = Stopwatch()..start();
    var attempted = 0;
    var succeeded = 0;
    var writeFailures = 0;
    var duplicateRejects = 0;
    var reconnectEvents = 0;
    var reconnectSuccess = 0;
    var peakVps = 0.0;
    final votedFans = <String>{};
    final fanIds = List.generate(cappedVoters, (i) => 'fan_${scenario.wireName}_$i');

    final deadline = maxDuration ?? const Duration(seconds: 12);
    final voteCap = maxVotes ?? min(cappedVoters * 2, 50000);

    while (sw.elapsed < deadline && attempted < voteCap) {
      final batch = min(200, voteCap - attempted);
      final windowStart = sw.elapsedMilliseconds;
      var windowVotes = 0;

      for (var i = 0; i < batch; i++) {
        final fanId = fanIds[_random.nextInt(fanIds.length)];
        final client = SyntheticVoteClient(
          fanId: fanId,
          scenario: scenario,
          random: Random(fanId.hashCode ^ attempted),
        );
        attempted++;
        reconnectEvents += client.reconnects;

        if (votedFans.contains(fanId) &&
            scenario != SyntheticVoteScenario.shardHotspotAttack) {
          duplicateRejects++;
          continue;
        }

        final ok = await client.attemptVote(
          voteAction: (_) async {
            if (scenario == SyntheticVoteScenario.shardHotspotAttack &&
                _random.nextDouble() < 0.12) {
              return false;
            }
            votedFans.add(fanId);
            return true;
          },
        );
        if (ok) {
          succeeded++;
          windowVotes++;
          if (client.reconnects > 0) reconnectSuccess++;
        } else {
          writeFailures++;
        }
      }

      final windowMs = max(1, sw.elapsedMilliseconds - windowStart);
      final vps = windowVotes / (windowMs / 1000);
      if (vps > peakVps) peakVps = vps;
    }

    sw.stop();
    final shardReport = _shardAnalyzer.analyze(
      uids: fanIds,
      clubTag: 'sandbox',
      allocator: _allocator,
    );

    final report = VoteLoadReport(
      scenario: scenario.wireName,
      sandboxSessionId: sessionId,
      virtualVoters: cappedVoters,
      duration: sw.elapsed,
      votesAttempted: attempted,
      votesSucceeded: succeeded,
      writeFailures: writeFailures,
      duplicateRejects: duplicateRejects,
      reconnectEvents: reconnectEvents,
      reconnectSuccess: reconnectSuccess,
      finalizeDurationMs:
          scenario == SyntheticVoteScenario.delayedFinalize ? 2400 : 680,
      finalizeRetries:
          scenario == SyntheticVoteScenario.delayedFinalize ? 3 : 0,
      authorityFallbacks: 0,
      maxShardSkewPercent: shardReport.skewPercent,
      peakVotesPerSecond: peakVps,
    );

    _reports.add(report);
    debugPrint('[SyntheticLoad] ${report.toJson()}');
    return report;
  }
}
