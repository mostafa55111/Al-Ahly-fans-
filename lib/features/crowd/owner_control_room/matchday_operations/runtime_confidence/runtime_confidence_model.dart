import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_execution_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/socket_pressure_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';

/// لقطة ثقة تشغيل — بدون spam هندسي.
class RuntimeConfidenceSnapshot {
  const RuntimeConfidenceSnapshot({
    required this.sessionHealth,
    required this.finalizeHealth,
    required this.uploadsReady,
    required this.authorityMode,
    required this.reconnectStable,
    required this.phase,
  });

  final String sessionHealth;
  final String finalizeHealth;
  final String uploadsReady;
  final String authorityMode;
  final String reconnectStable;
  final MatchdayTimelinePhase phase;
}

abstract final class RuntimeConfidenceModel {
  static RuntimeConfidenceSnapshot compose({
    required MatchActiveSession? session,
    required MatchdayTimelinePhase phase,
    required String? operatorWarning,
    required int playerCount,
  }) {
    final authority = getIt.isRegistered<AuthorityOrchestrator>()
        ? getIt<AuthorityOrchestrator>().activeMode.wireName
        : 'local';

    final pressure = SocketPressureGuard.instance;
    final reconnect = pressure.isAppBackgrounded
        ? 'خلفية'
        : pressure.runtimePressureHigh
            ? 'ضغط'
            : 'مستقر';

    var sessionHealth = 'لا جلسة';
    if (session != null && session.id.isNotEmpty) {
      sessionHealth = operatorWarning != null && operatorWarning.isNotEmpty
          ? 'تنبيه'
          : playerCount >= 11
              ? 'سليم'
              : 'ناقص';
    }

    var finalizeHealth = '—';
    if (session != null && session.id.isNotEmpty) {
      if (session.awardsFinalized) {
        finalizeHealth = 'مكتمل';
      } else if (phase == MatchdayTimelinePhase.finalizing) {
        finalizeHealth = 'قيد التنفيذ';
      } else if (phase == MatchdayTimelinePhase.completed) {
        finalizeHealth = 'مكتمل';
      } else {
        finalizeHealth = 'جاهز';
      }
    }

    return RuntimeConfidenceSnapshot(
      sessionHealth: sessionHealth,
      finalizeHealth: finalizeHealth,
      uploadsReady: 'Cloudinary',
      authorityMode: authority,
      reconnectStable: reconnect,
      phase: phase,
    );
  }
}
