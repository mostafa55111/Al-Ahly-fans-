import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';

/// حالات إحساس ليلة المباراة — مشتقة من الجلسة الحالية فقط (بدون stream جديد).
enum MatchNightPhase {
  preMatch,
  liveVoting,
  closingSoon,
  finalizing,
  winnerReveal,
  hallOfFame,
}

class MatchNightAtmosphere {
  MatchNightAtmosphere._();

  static MatchNightPhase resolve({
    required MatchVotingState? votingState,
    bool hallTabActive = false,
    int? serverNowMs,
  }) {
    if (hallTabActive) return MatchNightPhase.hallOfFame;

    final session = votingState?.match;
    if (session == null || session.id.isEmpty) {
      return MatchNightPhase.preMatch;
    }
    if (session.awardsFinalized) {
      return MatchNightPhase.winnerReveal;
    }
    if (!session.votingEnabled || session.votingFrozen) {
      return MatchNightPhase.finalizing;
    }
    if (_isClosingSoon(session, serverNowMs: serverNowMs)) {
      return MatchNightPhase.closingSoon;
    }
    return MatchNightPhase.liveVoting;
  }

  static bool _isClosingSoon(
    MatchActiveSession session, {
    int? serverNowMs,
  }) {
    final status = session.status.trim().toLowerCase();
    if (status == 'closing' || status == 'closing_soon') {
      return true;
    }
    final close = session.effectiveClosesAtServer;
    if (close <= 0 || serverNowMs == null || serverNowMs <= 0) {
      return false;
    }
    final remaining = close - serverNowMs;
    return remaining > 0 &&
        remaining <= const Duration(minutes: 8).inMilliseconds;
  }

  static double lightingIntensity(MatchNightPhase phase) {
    switch (phase) {
      case MatchNightPhase.preMatch:
        return 0.72;
      case MatchNightPhase.liveVoting:
        return 0.88;
      case MatchNightPhase.closingSoon:
        return 0.94;
      case MatchNightPhase.finalizing:
        return 0.78;
      case MatchNightPhase.winnerReveal:
        return 1.0;
      case MatchNightPhase.hallOfFame:
        return 0.68;
    }
  }

  static double motionIntensity(MatchNightPhase phase) {
    switch (phase) {
      case MatchNightPhase.preMatch:
        return 0.55;
      case MatchNightPhase.liveVoting:
        return 0.75;
      case MatchNightPhase.closingSoon:
        return 0.85;
      case MatchNightPhase.finalizing:
        return 0.5;
      case MatchNightPhase.winnerReveal:
        return 0.65;
      case MatchNightPhase.hallOfFame:
        return 0.4;
    }
  }
}
