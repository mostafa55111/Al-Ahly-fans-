import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/finalize_recovery_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/match_vote_aggregator.dart';

void main() {
  const orchestrator = FinalizeRecoveryOrchestrator();

  final session = MatchActiveSession(
    id: 'm1',
    title: 't',
    votingEnabled: false,
    formation: '4-3-3',
    createdAt: 1,
    closesAtServer: 5000,
    status: 'live',
  );

  setUp(FailureSurvivalRuntimeReport.instance.reset);

  test('skips when award already exists', () {
    final plan = orchestrator.plan(
      session: session,
      snapshot: const FinalizeRecoverySnapshot(
        sessionFinalized: false,
        matchAwardExists: true,
        leaseAcquired: true,
        aggregationChecksum: 'abc',
        monthlyDone: true,
        seasonDone: true,
      ),
    );
    expect(plan.runAggregation, isFalse);
    expect(plan.runAwardSnapshot, isFalse);
    expect(plan.claimFinalizedOnly, isTrue);
  });

  test('runs aggregation only when snapshot missing', () {
    final plan = orchestrator.plan(
      session: session,
      snapshot: const FinalizeRecoverySnapshot(
        sessionFinalized: false,
        matchAwardExists: false,
        leaseAcquired: true,
        aggregationChecksum: null,
        monthlyDone: false,
        seasonDone: false,
      ),
      existingAggregation: null,
    );
    expect(plan.runAggregation, isTrue);
    expect(plan.runAwardSnapshot, isTrue);
    expect(FailureSurvivalRuntimeReport.instance.interruptedFinalizeRecovered, 1);
  });

  test('resumes from aggregation without re-aggregate', () {
    final agg = MatchVoteAggregationResult(
      playerTotals: {'p1': 10},
      sessionTotal: 10,
      winnerPlayerId: 'p1',
      winnerVotes: 10,
      usedShardedSource: true,
    );
    final plan = orchestrator.plan(
      session: session,
      snapshot: const FinalizeRecoverySnapshot(
        sessionFinalized: false,
        matchAwardExists: false,
        leaseAcquired: true,
        aggregationChecksum: 'deadbeef',
        monthlyDone: false,
        seasonDone: false,
      ),
      existingAggregation: agg,
    );
    expect(plan.runAggregation, isFalse);
    expect(plan.runAwardSnapshot, isTrue);
  });
}
