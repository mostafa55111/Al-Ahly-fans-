import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_status.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// حكم جلسة منتهية/قديمة — يعتمد على وقت الخادم فقط.
class StaleSessionVerdict {
  const StaleSessionVerdict({
    required this.acceptsVotes,
    required this.isStale,
    this.reason,
  });

  final bool acceptsVotes;
  final bool isStale;
  final String? reason;
}

class StaleSessionGuard {
  const StaleSessionGuard();

  StaleSessionVerdict evaluate({
    required MatchActiveSession? session,
    required int serverNowMs,
    bool recordBlock = true,
  }) {
    if (session == null || session.id.isEmpty) {
      return const StaleSessionVerdict(
        acceptsVotes: false,
        isStale: true,
        reason: 'no_session',
      );
    }

    if (session.awardsFinalized || session.status == 'closed') {
      if (recordBlock) {
        FailureSurvivalRuntimeReport.instance.recordStaleSessionBlocked();
      }
      return StaleSessionVerdict(
        acceptsVotes: false,
        isStale: true,
        reason: 'finalized_or_closed',
      );
    }

    if (session.votingFrozen) {
      if (recordBlock) {
        FailureSurvivalRuntimeReport.instance.recordStaleSessionBlocked();
      }
      return const StaleSessionVerdict(
        acceptsVotes: false,
        isStale: false,
        reason: 'frozen',
      );
    }

    if (!session.votingEnabled) {
      return const StaleSessionVerdict(
        acceptsVotes: false,
        isStale: false,
        reason: 'voting_disabled',
      );
    }

    if (session.isClosedByStatus(serverNowMs)) {
      if (recordBlock) {
        FailureSurvivalRuntimeReport.instance.recordStaleSessionBlocked();
      }
      return StaleSessionVerdict(
        acceptsVotes: false,
        isStale: true,
        reason: 'past_closes_at_server',
      );
    }

    if (!canAcceptVotes(session: session, serverNowMs: serverNowMs)) {
      if (recordBlock) {
        FailureSurvivalRuntimeReport.instance.recordStaleSessionBlocked();
      }
      return const StaleSessionVerdict(
        acceptsVotes: false,
        isStale: true,
        reason: 'window_closed',
      );
    }

    final opened = session.effectiveOpenedAtServer;
    if (opened > 0 && serverNowMs + 120000 < opened) {
      if (recordBlock) {
        FailureSurvivalRuntimeReport.instance.recordStaleSessionBlocked();
      }
      return const StaleSessionVerdict(
        acceptsVotes: false,
        isStale: true,
        reason: 'clock_skew_future_session',
      );
    }

    return const StaleSessionVerdict(acceptsVotes: true, isStale: false);
  }
}
