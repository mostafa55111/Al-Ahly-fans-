import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_broadcast_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_identity_system.dart';

/// زجاج مقيد — sheets وقضبان بث.
class PremiumCardGlass {
  PremiumCardGlass._();

  static BoxDecoration sheetPanel({
    CrowdAppIdentity? identity,
    double radius = 20,
  }) {
    final id = PremiumCardClubIdentity.current(
      primary: identity?.primaryColor,
      secondary: identity?.secondaryColor,
    );
    return BoxDecoration(
      color: const Color(0xFF121418)
          .withValues(alpha: PremiumCardBroadcastTokens.glassMaterialAlpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: PremiumCardBroadcastTokens.glassBorderAlpha),
      ),
      boxShadow: [
        BoxShadow(
          color: id.ambientWarmth.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, -3),
        ),
      ],
    );
  }

  static BoxDecoration benchRailPanel({
    CrowdAppIdentity? identity,
    double? glassAlpha,
    double? borderOpacity,
  }) {
    final id = PremiumCardClubIdentity.current(
      primary: identity?.primaryColor,
      secondary: identity?.secondaryColor,
    );
    final topAlpha = glassAlpha ?? 0.88;
    final bottomAlpha = ((glassAlpha ?? 0.94) * 1.02).clamp(0.86, 0.96);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF16181C).withValues(alpha: topAlpha),
          const Color(0xFF0E1014).withValues(alpha: bottomAlpha),
        ],
      ),
      border: Border.all(
        color: id.edgeHighlight.withValues(alpha: borderOpacity ?? 0.18),
      ),
    );
  }

  static BoxDecoration broadcastChip({Color? accent}) {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: (accent ?? Colors.white).withValues(alpha: 0.2),
      ),
    );
  }
}
