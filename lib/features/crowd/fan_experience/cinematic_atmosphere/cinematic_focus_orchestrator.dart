import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';

/// أولوية تركيز المشجع — تقليل الفوضى البصرية.
enum CinematicFocusTarget {
  winnerReveal,
  selectedVote,
  liveFormation,
  substitutes,
  background,
}

class CinematicFocusSnapshot {
  const CinematicFocusSnapshot({
    required this.target,
    required this.focusedPlayerId,
    required this.priority,
  });

  final CinematicFocusTarget target;
  final String? focusedPlayerId;
  final int priority;

  bool isPlayerFocused(String playerId) =>
      focusedPlayerId != null && focusedPlayerId == playerId;
}

abstract final class CinematicFocusOrchestrator {
  static CinematicFocusSnapshot resolve({
    required MatchNightPhase phase,
    String? myVotedPlayerId,
    String? leadingPlayerId,
    required bool maskLiveCompetitive,
    bool hallTabActive = false,
  }) {
    if (hallTabActive || phase == MatchNightPhase.hallOfFame) {
      return const CinematicFocusSnapshot(
        target: CinematicFocusTarget.background,
        focusedPlayerId: null,
        priority: 0,
      );
    }

    if (phase == MatchNightPhase.winnerReveal &&
        !maskLiveCompetitive &&
        leadingPlayerId != null &&
        leadingPlayerId.isNotEmpty) {
      return CinematicFocusSnapshot(
        target: CinematicFocusTarget.winnerReveal,
        focusedPlayerId: leadingPlayerId,
        priority: 5,
      );
    }

    if (myVotedPlayerId != null && myVotedPlayerId.isNotEmpty) {
      return CinematicFocusSnapshot(
        target: CinematicFocusTarget.selectedVote,
        focusedPlayerId: myVotedPlayerId,
        priority: 4,
      );
    }

    if (phase == MatchNightPhase.liveVoting ||
        phase == MatchNightPhase.closingSoon) {
      return const CinematicFocusSnapshot(
        target: CinematicFocusTarget.liveFormation,
        focusedPlayerId: null,
        priority: 3,
      );
    }

    if (phase == MatchNightPhase.finalizing) {
      return const CinematicFocusSnapshot(
        target: CinematicFocusTarget.background,
        focusedPlayerId: null,
        priority: 2,
      );
    }

    return const CinematicFocusSnapshot(
      target: CinematicFocusTarget.background,
      focusedPlayerId: null,
      priority: 1,
    );
  }
}
