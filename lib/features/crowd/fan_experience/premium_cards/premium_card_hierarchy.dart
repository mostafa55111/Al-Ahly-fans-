import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_broadcast_tokens.dart';

/// مستويات بصرية للكروت على الملعب والبدلاء.
enum PremiumCardTier {
  normal,
  selected,
  locked,
  captain,
  winner,
  substitute,
}

abstract final class PremiumCardHierarchy {
  static PremiumCardTier fromStadiumFlags({
    required bool selected,
    required bool highlighted,
    required bool isVoteLeader,
    required bool isVotingMode,
    required bool voteLocked,
    required bool maskLiveCompetitive,
    bool isSubstitute = false,
  }) {
    if (isSubstitute) return PremiumCardTier.substitute;
    if (selected && voteLocked) return PremiumCardTier.locked;
    if (selected) return PremiumCardTier.selected;
    if (!maskLiveCompetitive && isVoteLeader) return PremiumCardTier.winner;
    if (isVoteLeader && isVotingMode) return PremiumCardTier.captain;
    if (highlighted && isVotingMode) return PremiumCardTier.normal;
    return PremiumCardTier.normal;
  }

  static double scaleFor(PremiumCardTier tier) {
    return switch (tier) {
      PremiumCardTier.winner => PremiumCardBroadcastTokens.winnerScale,
      PremiumCardTier.substitute => PremiumCardBroadcastTokens.substituteScale,
      PremiumCardTier.selected => 1.02,
      PremiumCardTier.captain => 1.02,
      PremiumCardTier.locked => 0.96,
      PremiumCardTier.normal => 1.0,
    };
  }

  static double opacityFor(PremiumCardTier tier) {
    return switch (tier) {
      PremiumCardTier.substitute => PremiumCardBroadcastTokens.benchQuietOpacity,
      PremiumCardTier.locked => 0.74,
      PremiumCardTier.normal => 0.92,
      _ => 1.0,
    };
  }
}
