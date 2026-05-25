import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_recovery/dead_session_recovery_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_audit_log.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_finalize_pipeline.dart';

/// ضوابط طوارئ — سلامة النظام أولاً.
class MatchdayEmergencyControls {
  MatchdayEmergencyControls({
    required MatchVotesRepository votes,
    required ProductionFinalizePipeline pipeline,
    required DeadSessionRecoveryService recovery,
    OwnerAuditLog? audit,
  })  : _votes = votes,
        _pipeline = pipeline,
        _recovery = recovery,
        _audit = audit;

  final MatchVotesRepository _votes;
  final ProductionFinalizePipeline _pipeline;
  final DeadSessionRecoveryService _recovery;
  final OwnerAuditLog? _audit;

  static MatchdayEmergencyControls get instance {
    return MatchdayEmergencyControls(
      votes: getIt<MatchVotesRepository>(),
      pipeline: getIt<ProductionFinalizePipeline>(),
      recovery: getIt<DeadSessionRecoveryService>(),
      audit: getIt.isRegistered<OwnerAuditLog>() ? getIt<OwnerAuditLog>() : null,
    );
  }

  /// إغلاق آمن — يوقف التصويت فقط؛ finalize عبر المسار الطبيعي.
  Future<void> safeCloseSession({
    required MatchActiveSession session,
  }) async {
    final club = FanAppIdentity.registryAppId;
    await _votes.adminSetVotingEnabled(club, false);
    await _audit?.logEmergencyRollback('safe_close:${session.id}');
  }

  /// إعادة finalize — مسار الإنتاج الوحيد.
  Future<bool> retryFinalize({required MatchActiveSession session}) async {
    final server = getIt<EgyptServerTimeService>();
    if (session.awardsFinalized) return true;
    final closes = session.effectiveClosesAtServer;
    if (closes > 0 && server.serverNowMs < closes) return false;

    await _audit?.logEmergencyRollback('retry_finalize:${session.id}');
    return _pipeline.run(
      session: session,
      trigger: 'owner_retry',
      enableRetry: false,
    );
  }

  /// فحص استرداد — بدون finalize متوازٍ.
  Future<void> forceRecoveryCheck({required MatchActiveSession session}) async {
    await _audit?.logEmergencyRollback('recovery_check:${session.id}');
    await _recovery.recoverIfNeeded(session);
    await _recovery.replayQueuedTasks();
  }
}
