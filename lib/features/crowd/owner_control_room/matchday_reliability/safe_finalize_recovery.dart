import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/emergency_controls/matchday_emergency_controls.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/live_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_finalize_pipeline.dart';

/// توصية استرداد finalize — بدون إجبار تلقائي.
class SafeFinalizeRecoveryAdvice {
  const SafeFinalizeRecoveryAdvice({
    required this.canRetry,
    required this.canRecoveryCheck,
    required this.stuckFinalizeSuspected,
    required this.messageAr,
  });

  final bool canRetry;
  final bool canRecoveryCheck;
  final bool stuckFinalizeSuspected;
  final String messageAr;
}

/// استرداد آمن عبر المسارات الإنتاجية الوحيدة.
class SafeFinalizeRecovery {
  SafeFinalizeRecovery({
    ProductionFinalizePipeline? pipeline,
    MatchdayEmergencyControls? emergency,
    EgyptServerTimeService? serverTime,
  })  : _pipeline = pipeline ??
            (getIt.isRegistered<ProductionFinalizePipeline>()
                ? getIt<ProductionFinalizePipeline>()
                : null),
        _emergency = emergency ?? MatchdayEmergencyControls.instance,
        _serverTime = serverTime ?? getIt<EgyptServerTimeService>();

  final ProductionFinalizePipeline? _pipeline;
  final MatchdayEmergencyControls _emergency;
  final EgyptServerTimeService _serverTime;

  SafeFinalizeRecoveryAdvice advise({
    required MatchActiveSession session,
    required bool finalizeInFlight,
  }) {
    if (session.awardsFinalized) {
      return const SafeFinalizeRecoveryAdvice(
        canRetry: false,
        canRecoveryCheck: false,
        stuckFinalizeSuspected: false,
        messageAr: 'الجلسة مُنهية بالفعل',
      );
    }
    final guard = LiveSessionGuard.canFinalize(
      session: session,
      phase: MatchdayTimelinePhase.finalizing,
      finalizeInFlight: finalizeInFlight,
    );
    final closes = session.effectiveClosesAtServer;
    final pastClose =
        closes > 0 && _serverTime.serverNowMs >= closes;
    final stuck = pastClose && !finalizeInFlight && !session.awardsFinalized;

    return SafeFinalizeRecoveryAdvice(
      canRetry: guard.allowed && pastClose && !finalizeInFlight,
      canRecoveryCheck: !finalizeInFlight,
      stuckFinalizeSuspected: stuck,
      messageAr: stuck
          ? 'Finalize متوقف — جرّب إعادة Finalize أو فحص الاسترداد'
          : guard.reason ?? 'جاهز عند انتهاء التصويت',
    );
  }

  Future<bool> retryFinalizeSafely(MatchActiveSession session) async {
    if (_pipeline == null) return false;
    if (_pipeline!.isFinalizeInFlight(session.id)) return false;
    if (_pipeline!.isFinalizeInFlight(session.id)) return false;
    return _emergency.retryFinalize(session: session);
  }

  Future<void> runRecoveryCheck(MatchActiveSession session) async {
    if (_pipeline != null && _pipeline!.isFinalizeInFlight(session.id)) {
      return;
    }
    await _emergency.forceRecoveryCheck(session: session);
  }
}
