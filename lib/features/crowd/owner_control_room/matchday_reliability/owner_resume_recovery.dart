import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/live_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/live_session_persistence.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_network_resilience.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/operational_health_monitor.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/safe_finalize_recovery.dart';

/// نتيجة استئناف التطبيق — توصيات فقط.
class OwnerResumeRecoveryReport {
  const OwnerResumeRecoveryReport({
    required this.runtimeValid,
    required this.restoreTabIndex,
    required this.persistence,
    required this.health,
    required this.finalizeAdvice,
    required this.recommendationAr,
  });

  final LiveSessionGuardVerdict runtimeValid;
  final int restoreTabIndex;
  final LiveSessionPersistenceSnapshot persistence;
  final OperationalHealthSnapshot health;
  final SafeFinalizeRecoveryAdvice finalizeAdvice;
  final String recommendationAr;
}

/// استرداد عند resume — لا finalize إجباري.
class OwnerResumeRecovery {
  OwnerResumeRecovery({
    MatchVotesRepository? votes,
    LiveSessionPersistence? persistence,
    SafeFinalizeRecovery? finalizeRecovery,
    EgyptServerTimeService? serverTime,
  })  : _votes = votes ?? getIt<MatchVotesRepository>(),
        _persistence = persistence ??
            LiveSessionPersistence(getIt<SharedPreferences>()),
        _finalizeRecovery = finalizeRecovery ?? SafeFinalizeRecovery(),
        _serverTime = serverTime ?? getIt<EgyptServerTimeService>();

  final MatchVotesRepository _votes;
  final LiveSessionPersistence _persistence;
  final SafeFinalizeRecovery _finalizeRecovery;
  final EgyptServerTimeService _serverTime;

  Future<OwnerResumeRecoveryReport> onAppResumed({
    required MatchdayNetworkState network,
    MatchActiveSession? adminSession,
    int playerCount = 0,
    String? operatorWarning,
  }) async {
    final club = FanAppIdentity.registryAppId;
    final snap = _persistence.load(club);

    MatchActiveSession? session = adminSession;
    session ??= await _loadRemoteSession(club);

    final now = _serverTime.serverNowMs;
    final phase = session != null
        ? MatchdayTimelineResolver.resolve(session: session, serverNowMs: now)
        : MatchdayTimelinePhase.idle;
    final inFlight = OperationalHealthMonitor.finalizeInFlightFor(session);

    final runtimeValid = LiveSessionGuard.validateRuntimeState(
      session: session,
      phase: phase,
      finalizeInFlight: inFlight,
    );

    final health = await OperationalHealthMonitor.evaluate(
      session: session,
      phase: phase,
      network: network,
      finalizeInFlight: inFlight,
      playerCount: playerCount,
      operatorWarning: operatorWarning,
    );

    final finalizeAdvice = session != null
        ? _finalizeRecovery.advise(
            session: session,
            finalizeInFlight: inFlight,
          )
        : const SafeFinalizeRecoveryAdvice(
            canRetry: false,
            canRecoveryCheck: false,
            stuckFinalizeSuspected: false,
            messageAr: 'لا جلسة',
          );

    var tab = snap.operationalTabIndex.clamp(0, 1);
    if (session != null &&
        session.id.isNotEmpty &&
        !session.awardsFinalized &&
        (session.votingEnabled || phase == MatchdayTimelinePhase.finalizing)) {
      tab = 1;
    }

    final recommendation = !runtimeValid.allowed
        ? (runtimeValid.reason ?? 'تحقق من حالة الجلسة')
        : finalizeAdvice.stuckFinalizeSuspected
            ? finalizeAdvice.messageAr
            : health.summaryAr;

    return OwnerResumeRecoveryReport(
      runtimeValid: runtimeValid,
      restoreTabIndex: tab,
      persistence: snap,
      health: health,
      finalizeAdvice: finalizeAdvice,
      recommendationAr: recommendation,
    );
  }

  Future<MatchActiveSession?> _loadRemoteSession(String club) async {
    final bundle = await _votes.getBundle(club);
    final m = bundle.match;
    if (m == null || m.id.isEmpty) return null;
    return m;
  }
}
