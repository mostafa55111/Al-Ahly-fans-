import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_status.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/infrastructure_degradation_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/socket_pressure_guard.dart';

/// حالة تشغيل الجمهور المدمجة — تقليل if-chaos عبر reducer واحد.
enum CrowdRuntimePhase {
  idle,
  votingOpen,
  votingClosedPendingFinalize,
  finalizing,
  finalized,
  degradedLightweight,
  recovery,
}

class CrowdRuntimePolicyInput {
  const CrowdRuntimePolicyInput({
    this.session,
    this.serverNowMs = 0,
    this.infrastructureMode = CrowdInfrastructureRuntimeMode.normal,
    this.appBackgrounded = false,
    this.recoveryQueueDepth = 0,
    this.finalizeInFlight = false,
  });

  final MatchActiveSession? session;
  final int serverNowMs;
  final CrowdInfrastructureRuntimeMode infrastructureMode;
  final bool appBackgrounded;
  final int recoveryQueueDepth;
  final bool finalizeInFlight;
}

/// مصفوفة انتقالات حتمية — مصدر قرار واحد للخدمات.
class RuntimePolicyMatrix {
  const RuntimePolicyMatrix();

  CrowdRuntimePhase reduce(CrowdRuntimePolicyInput input) {
    if (input.finalizeInFlight ||
        input.infrastructureMode ==
            CrowdInfrastructureRuntimeMode.recoveryMode) {
      return CrowdRuntimePhase.recovery;
    }
    if (input.appBackgrounded ||
        input.infrastructureMode ==
            CrowdInfrastructureRuntimeMode.lightweightRuntime ||
        SocketPressureGuard.instance.shouldDeferHeavyStreams) {
      return CrowdRuntimePhase.degradedLightweight;
    }

    final session = input.session;
    if (session == null || session.id.isEmpty) {
      return CrowdRuntimePhase.idle;
    }

    if (session.awardsFinalized || session.status == 'closed') {
      return CrowdRuntimePhase.finalized;
    }

    final closes = session.effectiveClosesAtServer;
    if (closes > 0 &&
        input.serverNowMs >= closes &&
        !session.awardsFinalized) {
      return CrowdRuntimePhase.votingClosedPendingFinalize;
    }

    if (session.status == 'finalizing') {
      return CrowdRuntimePhase.finalizing;
    }

    if (session.votingEnabled &&
        canAcceptVotes(
          session: session,
          serverNowMs: input.serverNowMs,
        )) {
      return CrowdRuntimePhase.votingOpen;
    }

    return CrowdRuntimePhase.votingClosedPendingFinalize;
  }

  bool allowHeavySubscriptions(CrowdRuntimePhase phase) =>
      phase == CrowdRuntimePhase.votingOpen ||
      phase == CrowdRuntimePhase.votingClosedPendingFinalize;

  bool allowPhasedRestoreOnly(CrowdRuntimePhase phase) =>
      phase == CrowdRuntimePhase.degradedLightweight ||
      phase == CrowdRuntimePhase.recovery;
}
