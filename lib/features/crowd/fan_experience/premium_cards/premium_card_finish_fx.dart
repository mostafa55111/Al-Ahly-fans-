import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_broadcast_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_hierarchy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_identity_system.dart';

/// طبقة تشطيب بث — حواف معدنية خفيفة، بدون توهج ألعاب.
class PremiumCardFinishFx extends StatelessWidget {
  const PremiumCardFinishFx({
    super.key,
    required this.width,
    required this.height,
    required this.tier,
    this.identity,
    this.enabled = true,
  });

  final double width;
  final double height;
  final PremiumCardTier tier;
  final PremiumCardClubIdentity? identity;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    final id = identity ?? PremiumCardClubIdentity.current();
    final sheen = switch (tier) {
      PremiumCardTier.winner => PremiumCardBroadcastTokens.sheenIntensityWinner,
      PremiumCardTier.selected => PremiumCardBroadcastTokens.sheenIntensitySelected,
      PremiumCardTier.captain => PremiumCardBroadcastTokens.sheenIntensitySelected,
      _ => PremiumCardBroadcastTokens.sheenIntensityNormal,
    };

    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PremiumCardBroadcastTokens.innerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    id.edgeHighlight.withValues(alpha: sheen),
                    Colors.transparent,
                    id.ambientWarmth.withValues(alpha: sheen * 0.6),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: sheen * 0.85),
                    width: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// فصل خفيف عن عشب الملعب — بدون دائرة واضحة.
  static Widget fieldSeparation({
    required double width,
    required Color accent,
    PremiumCardTier tier = PremiumCardTier.normal,
  }) {
    final alpha = tier == PremiumCardTier.winner
        ? PremiumCardBroadcastTokens.fieldLiftAlpha + 0.06
        : PremiumCardBroadcastTokens.fieldLiftAlpha;
    return IgnorePointer(
      child: Container(
        width: width * 1.12,
        height: width * 0.22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: RadialGradient(
            colors: [
              accent.withValues(alpha: alpha),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
