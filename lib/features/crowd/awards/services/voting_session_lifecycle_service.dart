import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/monthly_aggregation_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/season_aggregation_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_recovery/dead_session_recovery_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/aggregation_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_finalize_pipeline.dart';

/// مراقبة إغلاق الجلسة — يستقبل الجلسة من MatchVotingCubit (بث واحد).
class VotingSessionLifecycleService {
  VotingSessionLifecycleService({
    required EgyptServerTimeService serverTime,
    required AwardsRepository awardsRepository,
    required ProductionFinalizePipeline finalizePipeline,
    required String clubTag,
    DeadSessionRecoveryService? deadSessionRecovery,
    MonthlyAggregationService? monthlyAggregation,
    SeasonAggregationService? seasonAggregation,
  })  : _serverTime = serverTime,
        _awards = awardsRepository,
        _pipeline = finalizePipeline,
        _clubTag = clubTag.trim().toLowerCase(),
        _deadRecovery = deadSessionRecovery,
        _monthly = monthlyAggregation ??
            MonthlyAggregationService(awardsRepository),
        _season = seasonAggregation ?? SeasonAggregationService(awardsRepository);

  final EgyptServerTimeService _serverTime;
  final AwardsRepository _awards;
  final ProductionFinalizePipeline _pipeline;
  final String _clubTag;
  final DeadSessionRecoveryService? _deadRecovery;
  final MonthlyAggregationService _monthly;
  final SeasonAggregationService _season;

  bool _finalizeInFlight = false;
  final Set<String> _localCompletedMatchIds = {};

  void start() {
    unawaited(_pipeline.replayQueuedTasks());
  }

  void dispose() {
    _finalizeInFlight = false;
  }

  /// يُستدعى من CrowdScreen عند تغيّر جلسة MatchVotingCubit — بدون بث مكرر.
  void notifyActiveSession(MatchActiveSession? session) {
    if (session == null || session.id.isEmpty) return;

    if (session.awardsFinalized || session.status == 'closed') {
      _localCompletedMatchIds.add(session.id);
      return;
    }

    final closes = session.effectiveClosesAtServer;
    if (closes > 0 && _serverTime.serverNowMs >= closes) {
      if (_finalizeInFlight) return;
      if (_localCompletedMatchIds.contains(session.id)) return;
      unawaited(_runFinalize(session));
    }
  }

  Future<void> _runFinalize(MatchActiveSession session) async {
    _finalizeInFlight = true;
    try {
      final ok = await _pipeline.run(
        session: session,
        trigger: 'lifecycle',
        enableRetry: true,
      );
      if (ok) {
        _localCompletedMatchIds.add(session.id);
      } else {
        await _deadRecovery?.recoverIfNeeded(session);
      }
    } catch (e, st) {
      debugPrint('[VotingLifecycle] finalize: $e\n$st');
      await _deadRecovery?.recoverIfNeeded(session);
    } finally {
      _finalizeInFlight = false;
    }
  }

  Future<void> refreshPeriodAwardsIfNeeded({
    required String monthKey,
    required String seasonKey,
    required int anchorClosedAtServerMs,
  }) async {
    if (monthKey.isEmpty || seasonKey.isEmpty || anchorClosedAtServerMs <= 0) {
      return;
    }

    final monthly = await _awards.getMonthly(
      clubTag: _clubTag,
      monthKey: monthKey,
    );
    if (monthly == null &&
        !AggregationCostGuard.instance.shouldSkipMonthlyRecompute(
          clubTag: _clubTag,
          monthKey: monthKey,
        )) {
      await _monthly.computeAndPersist(
        clubTag: _clubTag,
        monthKey: monthKey,
        closedAtServerMs: anchorClosedAtServerMs,
      );
    }

    final season = await _awards.getSeason(
      clubTag: _clubTag,
      seasonKey: seasonKey,
    );
    if (season == null &&
        !AggregationCostGuard.instance.shouldSkipSeasonRecompute(
          clubTag: _clubTag,
          seasonKey: seasonKey,
        )) {
      await _season.computeAndPersist(
        clubTag: _clubTag,
        seasonKey: seasonKey,
        closedAtServerMs: anchorClosedAtServerMs,
      );
    }
  }
}
