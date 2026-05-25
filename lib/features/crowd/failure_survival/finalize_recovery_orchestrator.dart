import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/match_vote_aggregator.dart';

/// خطة استرداد إغلاق — لا تكرار للخطوات المكتملة.
class FinalizeRecoveryPlan {
  const FinalizeRecoveryPlan({
    required this.skipEntirely,
    required this.runAggregation,
    required this.runAwardSnapshot,
    required this.runMonthlyRollup,
    required this.runSeasonRollup,
    required this.claimFinalizedOnly,
    this.reason,
  });

  final bool skipEntirely;
  final bool runAggregation;
  final bool runAwardSnapshot;
  final bool runMonthlyRollup;
  final bool runSeasonRollup;
  final bool claimFinalizedOnly;
  final String? reason;

  static const done = FinalizeRecoveryPlan(
    skipEntirely: true,
    runAggregation: false,
    runAwardSnapshot: false,
    runMonthlyRollup: false,
    runSeasonRollup: false,
    claimFinalizedOnly: false,
    reason: 'already_complete',
  );
}

/// لقطة حالة خارجية قبل استئناف finalize.
class FinalizeRecoverySnapshot {
  const FinalizeRecoverySnapshot({
    required this.sessionFinalized,
    required this.matchAwardExists,
    required this.leaseAcquired,
    required this.aggregationChecksum,
    required this.monthlyDone,
    required this.seasonDone,
  });

  final bool sessionFinalized;
  final bool matchAwardExists;
  final bool leaseAcquired;
  final String? aggregationChecksum;
  final bool monthlyDone;
  final bool seasonDone;
}

/// يحدد الخطوات الناقصة فقط — منع overwrite وازدواجية التجميع.
class FinalizeRecoveryOrchestrator {
  const FinalizeRecoveryOrchestrator();

  FinalizeRecoveryPlan plan({
    required MatchActiveSession session,
    required FinalizeRecoverySnapshot snapshot,
    MatchVoteAggregationResult? existingAggregation,
  }) {
    if (session.awardsFinalized || snapshot.sessionFinalized) {
      return FinalizeRecoveryPlan.done;
    }

    if (!snapshot.leaseAcquired) {
      return const FinalizeRecoveryPlan(
        skipEntirely: true,
        runAggregation: false,
        runAwardSnapshot: false,
        runMonthlyRollup: false,
        runSeasonRollup: false,
        claimFinalizedOnly: false,
        reason: 'lease_not_held',
      );
    }

    if (snapshot.matchAwardExists) {
      return FinalizeRecoveryPlan(
        skipEntirely: false,
        runAggregation: false,
        runAwardSnapshot: false,
        runMonthlyRollup: !snapshot.monthlyDone,
        runSeasonRollup: !snapshot.seasonDone,
        claimFinalizedOnly: true,
        reason: 'award_exists_claim_only',
      );
    }

    final hasAggregation = existingAggregation != null &&
        existingAggregation.sessionTotal > 0 &&
        existingAggregation.winnerPlayerId != null;

    if (hasAggregation && snapshot.aggregationChecksum != null) {
      FailureSurvivalRuntimeReport.instance.recordInterruptedFinalizeRecovered();
      return FinalizeRecoveryPlan(
        skipEntirely: false,
        runAggregation: false,
        runAwardSnapshot: true,
        runMonthlyRollup: !snapshot.monthlyDone,
        runSeasonRollup: !snapshot.seasonDone,
        claimFinalizedOnly: false,
        reason: 'resume_from_aggregation_snapshot',
      );
    }

    FailureSurvivalRuntimeReport.instance.recordInterruptedFinalizeRecovered();
    return FinalizeRecoveryPlan(
      skipEntirely: false,
      runAggregation: true,
      runAwardSnapshot: true,
      runMonthlyRollup: !snapshot.monthlyDone,
      runSeasonRollup: !snapshot.seasonDone,
      claimFinalizedOnly: false,
      reason: 'full_recovery_path',
    );
  }

  bool shouldBlockDuplicateRecovery({
    required String matchId,
    required Set<String> inFlight,
  }) {
    if (inFlight.contains(matchId)) {
      FailureSurvivalRuntimeReport.instance.recordDuplicateRecoveryPrevented();
      return true;
    }
    return false;
  }
}
