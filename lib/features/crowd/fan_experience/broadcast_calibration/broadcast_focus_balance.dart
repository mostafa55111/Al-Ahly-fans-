import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';

/// توازن التركيز — أولوية نظرة المشجع.
class BroadcastFocusBalance {
  const BroadcastFocusBalance({
    required this.selectedEmphasis,
    required this.formationClarity,
    required this.countdownPriority,
    required this.benchWeight,
    required this.atmosphereWeight,
    required this.nonFocusedCardOpacity,
    required this.competingHighlightReduction,
  });

  final double selectedEmphasis;
  final double formationClarity;
  final double countdownPriority;
  final double benchWeight;
  final double atmosphereWeight;
  final double nonFocusedCardOpacity;
  final double competingHighlightReduction;

  static BroadcastFocusBalance forPhase(MatchNightPhase phase, {bool hallTab = false}) {
    if (hallTab) {
      return const BroadcastFocusBalance(
        selectedEmphasis: 0.5,
        formationClarity: 0.4,
        countdownPriority: 0.3,
        benchWeight: 0.45,
        atmosphereWeight: 0.55,
        nonFocusedCardOpacity: 0.9,
        competingHighlightReduction: 0.7,
      );
    }

    return switch (phase) {
      MatchNightPhase.winnerReveal => const BroadcastFocusBalance(
          selectedEmphasis: 1.0,
          formationClarity: 0.72,
          countdownPriority: 0.5,
          benchWeight: 0.55,
          atmosphereWeight: 0.62,
          nonFocusedCardOpacity: 0.62,
          competingHighlightReduction: 0.55,
        ),
      MatchNightPhase.liveVoting || MatchNightPhase.closingSoon =>
        const BroadcastFocusBalance(
          selectedEmphasis: 0.92,
          formationClarity: 0.88,
          countdownPriority: 0.95,
          benchWeight: 0.78,
          atmosphereWeight: 0.7,
          nonFocusedCardOpacity: 0.86,
          competingHighlightReduction: 0.75,
        ),
      MatchNightPhase.finalizing => const BroadcastFocusBalance(
          selectedEmphasis: 0.85,
          formationClarity: 0.8,
          countdownPriority: 1.0,
          benchWeight: 0.7,
          atmosphereWeight: 0.5,
          nonFocusedCardOpacity: 0.8,
          competingHighlightReduction: 0.8,
        ),
      _ => const BroadcastFocusBalance(
          selectedEmphasis: 0.8,
          formationClarity: 0.82,
          countdownPriority: 0.85,
          benchWeight: 0.82,
          atmosphereWeight: 0.75,
          nonFocusedCardOpacity: 0.9,
          competingHighlightReduction: 0.82,
        ),
    };
  }

  double cardOpacityFor({required bool isFocused}) =>
      isFocused ? 1.0 : nonFocusedCardOpacity.clamp(0.58, 0.92);
}
