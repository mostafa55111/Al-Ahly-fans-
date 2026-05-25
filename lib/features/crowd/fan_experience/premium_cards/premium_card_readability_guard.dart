import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_broadcast_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_identity_system.dart';

/// ضمان قراءة النص فوق أي فن كارت.
abstract final class PremiumCardReadabilityGuard {
  static double bottomScrimAlpha({
    required bool hasDesignedArt,
    required bool brightArtHint,
    PremiumCardClubIdentity? identity,
  }) {
    var alpha = PremiumCardBroadcastTokens.scrimBottomAlpha;
    if (hasDesignedArt) alpha += PremiumCardBroadcastTokens.scrimBoostForArt;
    if (brightArtHint) alpha += 0.06;
    return alpha.clamp(0.72, 0.92);
  }

  static List<Color> bottomScrimGradient({
    required double alpha,
    PremiumCardClubIdentity? identity,
  }) {
    final tint = identity?.scrimTint ?? Colors.black;
    return [
      Colors.transparent,
      tint.withValues(alpha: alpha * 0.35),
      Colors.black.withValues(alpha: alpha),
    ];
  }

  static Color nameColor({double luminanceHint = 0.2}) {
    return luminanceHint > 0.55
        ? Colors.white.withValues(alpha: 0.98)
        : Colors.white;
  }

  static double ratingOpacity({required bool lowContrast}) =>
      lowContrast ? 1.0 : 0.95;

  static double highlightReduction({required bool stackedGlow}) =>
      stackedGlow ? 0.65 : 1.0;
}
