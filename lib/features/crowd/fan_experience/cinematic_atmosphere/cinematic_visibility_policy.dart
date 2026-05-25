import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_focus_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';

/// سياسة إظهار/إخفاء الطبقات — الكروت تبقى البطل.
class CinematicVisibilityPolicy {
  const CinematicVisibilityPolicy({
    required this.showCrowdAtmosphereFx,
    required this.showCollectivePulse,
    required this.showStadiumFxEngine,
    required this.benchProminence,
    required this.nonFocusedCardOpacity,
    required this.allowCardBreathing,
    required this.keepCountdownReadable,
    required this.atmosphereFxMultiplier,
  });

  final bool showCrowdAtmosphereFx;
  final bool showCollectivePulse;
  final bool showStadiumFxEngine;
  final double benchProminence;
  final double nonFocusedCardOpacity;
  final bool allowCardBreathing;
  final bool keepCountdownReadable;
  final double atmosphereFxMultiplier;

  static CinematicVisibilityPolicy forContext({
    required MatchNightPhase phase,
    required CinematicFocusSnapshot focus,
  }) {
    final isFinalizing = phase == MatchNightPhase.finalizing;
    final isWinner = phase == MatchNightPhase.winnerReveal;
    final isHall = phase == MatchNightPhase.hallOfFame;

    return CinematicVisibilityPolicy(
      showCrowdAtmosphereFx: !isFinalizing && !isHall,
      showCollectivePulse:
          phase == MatchNightPhase.liveVoting ||
          phase == MatchNightPhase.closingSoon,
      showStadiumFxEngine: !isFinalizing && !isHall,
      benchProminence: isWinner ? 0.55 : (isFinalizing ? 0.65 : 1.0),
      nonFocusedCardOpacity: _dimForFocus(focus),
      allowCardBreathing: focus.target == CinematicFocusTarget.selectedVote ||
          focus.target == CinematicFocusTarget.winnerReveal,
      keepCountdownReadable: true,
      atmosphereFxMultiplier: isFinalizing ? 0.35 : (isWinner ? 0.55 : 0.85),
    );
  }

  static double _dimForFocus(CinematicFocusSnapshot focus) {
    return switch (focus.target) {
      CinematicFocusTarget.winnerReveal => 0.62,
      CinematicFocusTarget.selectedVote => 0.78,
      CinematicFocusTarget.liveFormation => 0.9,
      CinematicFocusTarget.substitutes => 0.88,
      CinematicFocusTarget.background => 0.92,
    };
  }

  double cardOpacityFor(String playerId, CinematicFocusSnapshot focus) {
    if (focus.focusedPlayerId == null) return nonFocusedCardOpacity;
    if (focus.isPlayerFocused(playerId)) return 1.0;
    return nonFocusedCardOpacity;
  }
}
