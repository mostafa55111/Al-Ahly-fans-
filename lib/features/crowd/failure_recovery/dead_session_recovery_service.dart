import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_finalize_pipeline.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_health_report.dart';

/// يستأنف إغلاق جلسات منتهية — يفوّض إلى [ProductionFinalizePipeline] فقط.
class DeadSessionRecoveryService {
  DeadSessionRecoveryService({
    required ProductionFinalizePipeline finalizePipeline,
    required EgyptServerTimeService serverTime,
  })  : _pipeline = finalizePipeline,
        _serverTime = serverTime;

  final ProductionFinalizePipeline _pipeline;
  final EgyptServerTimeService _serverTime;

  Future<void> recoverIfNeeded(MatchActiveSession session) async {
    if (session.id.isEmpty || session.awardsFinalized) return;
    final closes = session.effectiveClosesAtServer;
    if (closes <= 0 || _serverTime.serverNowMs < closes) return;

    try {
      RuntimeHealthReport.instance.recordDeadSessionRecovery();
      await _pipeline.run(
        session: session,
        trigger: 'recovery',
        enableRetry: false,
      );
    } catch (e, st) {
      debugPrint('[DeadSessionRecovery] $e\n$st');
    }
  }

  Future<void> replayQueuedTasks() => _pipeline.replayQueuedTasks();
}
