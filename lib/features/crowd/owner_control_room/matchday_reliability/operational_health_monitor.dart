import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_execution_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_network_resilience.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_finalize_pipeline.dart';

enum OperationalHealthVerdict { healthy, degraded, critical }

/// ملخص صحة يوم المباراة — للمالك فقط.
class OperationalHealthSnapshot {
  const OperationalHealthSnapshot({
    required this.verdict,
    required this.firebaseConnectivity,
    required this.sessionHealth,
    required this.finalizePipeline,
    required this.uploadReadiness,
    required this.authorityRuntime,
    required this.reconnectPressure,
    required this.summaryAr,
  });

  final OperationalHealthVerdict verdict;
  final String firebaseConnectivity;
  final String sessionHealth;
  final String finalizePipeline;
  final String uploadReadiness;
  final String authorityRuntime;
  final String reconnectPressure;
  final String summaryAr;
}

abstract final class OperationalHealthMonitor {
  static Future<OperationalHealthSnapshot> evaluate({
    required MatchActiveSession? session,
    required MatchdayTimelinePhase phase,
    required MatchdayNetworkState network,
    required bool finalizeInFlight,
    required int playerCount,
    String? operatorWarning,
  }) async {
    final authority = getIt.isRegistered<AuthorityOrchestrator>()
        ? getIt<AuthorityOrchestrator>().activeMode.wireName
        : 'local';

    var sessionHealth = 'لا جلسة';
    if (session != null && session.id.isNotEmpty) {
      if (operatorWarning != null && operatorWarning.isNotEmpty) {
        sessionHealth = 'تنبيه';
      } else if (session.awardsFinalized) {
        sessionHealth = 'مكتمل';
      } else if (playerCount >= 11) {
        sessionHealth = 'سليم';
      } else {
        sessionHealth = 'ناقص';
      }
    }

    var finalizePipeline = '—';
    if (session != null && session.id.isNotEmpty) {
      if (session.awardsFinalized) {
        finalizePipeline = 'مكتمل';
      } else if (finalizeInFlight) {
        finalizePipeline = 'قيد التنفيذ';
      } else if (phase == MatchdayTimelinePhase.finalizing) {
        finalizePipeline = 'مطلوب';
      } else {
        finalizePipeline = 'جاهز';
      }
    }

    final firebase = MatchdayNetworkResilience.labelAr(network);
    final reconnect = network == MatchdayNetworkState.unstable ||
            network == MatchdayNetworkState.reconnecting
        ? 'مرتفع'
        : 'منخفض';

    var verdict = OperationalHealthVerdict.healthy;
    if (network == MatchdayNetworkState.offline ||
        (session != null &&
            phase == MatchdayTimelinePhase.finalizing &&
            !session.awardsFinalized &&
            finalizeInFlight == false &&
            network == MatchdayNetworkState.degraded)) {
      verdict = OperationalHealthVerdict.critical;
    } else if (network != MatchdayNetworkState.healthy ||
        sessionHealth == 'تنبيه' ||
        sessionHealth == 'ناقص') {
      verdict = OperationalHealthVerdict.degraded;
    }

    final summary = switch (verdict) {
      OperationalHealthVerdict.healthy => 'التشغيل مستقر',
      OperationalHealthVerdict.degraded => 'راقب الاتصال والجلسة',
      OperationalHealthVerdict.critical => 'يتطلب تدخلاً قبل المتابعة',
    };

    return OperationalHealthSnapshot(
      verdict: verdict,
      firebaseConnectivity: firebase,
      sessionHealth: sessionHealth,
      finalizePipeline: finalizePipeline,
      uploadReadiness: 'Cloudinary',
      authorityRuntime: authority,
      reconnectPressure: reconnect,
      summaryAr: summary,
    );
  }

  static bool finalizeInFlightFor(MatchActiveSession? session) {
    if (session == null || session.id.isEmpty) return false;
    if (!getIt.isRegistered<ProductionFinalizePipeline>()) return false;
    return getIt<ProductionFinalizePipeline>().isFinalizeInFlight(session.id);
  }
}
