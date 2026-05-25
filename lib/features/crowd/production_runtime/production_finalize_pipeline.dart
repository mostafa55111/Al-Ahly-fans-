import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_time_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/finalization_lease_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/finalize_retry_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_recovery/crowd_recovery_queue.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/finalize_recovery_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/infrastructure_degradation_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/runtime_owner_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/finalization_audit_trail.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_health_report.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مسار إغلاق الإنتاج الوحيد:
/// lease → authority finalize (aggregation → award → rollups → claim) → cleanup.
///
/// lifecycle / recovery / replay يمرّون هنا فقط — بدون orchestrator مباشر خارجاً.
class ProductionFinalizePipeline {
  ProductionFinalizePipeline({
    required AuthorityOrchestrator orchestrator,
    required MatchVotesRepository votes,
    required AwardsRepository awards,
    required EgyptServerTimeService serverTime,
    required FinalizationLeaseService lease,
    required FinalizeRetryCoordinator retry,
    required SharedPreferences prefs,
    required String clubTag,
    required String leaseOwnerId,
    FinalizeRecoveryOrchestrator? recoveryPlan,
  })  : _orchestrator = orchestrator,
        _votes = votes,
        _awards = awards,
        _serverTime = serverTime,
        _lease = lease,
        _retry = retry,
        _queue = CrowdRecoveryQueue(prefs),
        _clubTag = clubTag.trim().toLowerCase(),
        _leaseOwnerId = leaseOwnerId,
        _recoveryPlan = recoveryPlan ?? const FinalizeRecoveryOrchestrator();

  final AuthorityOrchestrator _orchestrator;
  final MatchVotesRepository _votes;
  final AwardsRepository _awards;
  final EgyptServerTimeService _serverTime;
  final FinalizationLeaseService _lease;
  final FinalizeRetryCoordinator _retry;
  final CrowdRecoveryQueue _queue;
  final String _clubTag;
  final String _leaseOwnerId;
  final FinalizeRecoveryOrchestrator _recoveryPlan;

  final Set<String> _inFlight = {};
  final Set<String> _completed = {};

  /// للمالك فقط — هل finalize قيد التنفيذ لهذه الجلسة.
  bool isFinalizeInFlight(String matchId) =>
      matchId.isNotEmpty && _inFlight.contains(matchId);

  bool isSessionMarkedComplete(String matchId) =>
      matchId.isNotEmpty && _completed.contains(matchId);

  /// إعادة تشغيل مهام الاسترداد المؤجلة فقط (بدون بث جلسة).
  Future<void> replayQueuedTasks() async {
    final tasks = await _queue.dueTasks(_serverTime.serverNowMs);
    for (final task in tasks) {
      if (task.kind != 'finalize') continue;
      final matchId = task.payload['matchId']?.toString() ?? '';
      final closedAt = (task.payload['closedAtServerMs'] as num?)?.toInt() ?? 0;
      if (matchId.isEmpty || closedAt <= 0) continue;
      final bundle = await _votes.getBundle(_clubTag);
      final session = bundle.match;
      if (session == null || session.id != matchId) {
        await _queue.remove(task.id);
        continue;
      }
      await run(
        session: session,
        trigger: 'replay',
        enableRetry: false,
      );
    }
  }

  /// نقطة الدخول الوحيدة لإغلاق الجلسة في runtime الإنتاج.
  Future<bool> run({
    required MatchActiveSession session,
    required String trigger,
    bool enableRetry = true,
  }) async {
    if (session.id.isEmpty || session.awardsFinalized) return true;
    if (_completed.contains(session.id)) return true;
    if (_recoveryPlan.shouldBlockDuplicateRecovery(
      matchId: session.id,
      inFlight: _inFlight,
    )) {
      return false;
    }

    final closes = session.effectiveClosesAtServer;
    if (closes <= 0 || _serverTime.serverNowMs < closes) return false;

    final degradation = InfrastructureDegradationResolver.instance;
    if (!degradation.tryEnterRecovery('finalize:${session.id}')) return false;

    _inFlight.add(session.id);
    RuntimeOwnerGuard.instance.recordFinalizeAttempt();
    RuntimeOwnerGuard.instance.claim(
      RuntimeOwnershipDomain.finalize,
      'ProductionFinalizePipeline',
    );
    final dedupeKey = '$_clubTag:${session.id}';
    try {
      Future<bool> attempt() => _runSteps(
        session: session,
        closedAt: closes,
        dedupeKey: dedupeKey,
        trigger: trigger,
      );

      final ok = enableRetry
          ? await _retry.runWithRetry(
              dedupeKey: dedupeKey,
              shouldAbort: () {
                final closedAt = session.effectiveClosesAtServer;
                return closedAt <= 0 || _serverTime.serverNowMs < closedAt;
              },
              attempt: attempt,
            )
          : await attempt();

      if (ok) {
        _completed.add(session.id);
        await _queue.remove('finalize:${session.id}');
      } else {
        await _queue.enqueue(
          CrowdRecoveryTask(
            id: 'finalize:${session.id}',
            kind: 'finalize',
            payload: {
              'clubTag': _clubTag,
              'matchId': session.id,
              'closedAtServerMs': closes,
            },
            createdAtMs: _serverTime.serverNowMs,
          ),
        );
      }
      return ok;
    } catch (e, st) {
      debugPrint('[ProductionFinalizePipeline] $trigger: $e\n$st');
      return false;
    } finally {
      _inFlight.remove(session.id);
      RuntimeOwnerGuard.instance.recordFinalizeComplete();
      degradation.leaveRecovery();
    }
  }

  Future<bool> _runSteps({
    required MatchActiveSession session,
    required int closedAt,
    required String dedupeKey,
    required String trigger,
  }) async {
    await _serverTime.refreshOffset();
    if (_serverTime.serverNowMs < closedAt) return false;

    final bundle = await _votes.getBundle(_clubTag);
    if (bundle.match?.id != session.id) return false;
    if (bundle.match!.awardsFinalized) {
      _completed.add(session.id);
      return true;
    }

    final acquired = await _lease.tryAcquire(
      clubTag: _clubTag,
      matchId: session.id,
      ownerId: _leaseOwnerId,
    );
    if (!acquired) return false;

    final time = AwardsTimeResolver.fromClosedAtServer(closedAt);
    final existingAward = await _awards.getMatchAward(
      clubTag: _clubTag,
      year: time.calendarYear,
      matchId: session.id,
    );
    final plan = _recoveryPlan.plan(
      session: session,
      snapshot: FinalizeRecoverySnapshot(
        sessionFinalized: bundle.match!.awardsFinalized,
        matchAwardExists: existingAward != null,
        leaseAcquired: true,
        aggregationChecksum: null,
        monthlyDone: false,
        seasonDone: false,
      ),
    );
    if (plan.skipEntirely) {
      _completed.add(session.id);
      return true;
    }

    if (kDebugMode) {
      debugPrint(
        '[ProductionFinalizePipeline] trigger=$trigger match=${session.id} '
        'plan=${plan.reason}',
      );
    }

    final response = await _orchestrator.finalizeSession(
      FinalizeSessionRequest(
        clubTag: _clubTag,
        matchId: session.id,
        closedAtServerMs: closedAt,
        idempotencyKey: dedupeKey,
      ),
      bundleHint: bundle,
    );

    RuntimeHealthReport.instance.recordFinalizeAttempt(success: response.success);

    if (response.success) {
      await _lease.markFinalized(clubTag: _clubTag, matchId: session.id);
      if (kDebugMode) {
        FinalizationAuditTrail.instance.recordRemoteFinalize(
          matchId: session.id,
          success: true,
          shadow: false,
          message: trigger,
        );
      }
    }
    return response.success;
  }
}
