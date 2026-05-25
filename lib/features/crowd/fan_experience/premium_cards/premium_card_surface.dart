import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_broadcast_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_finish_fx.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_hierarchy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_identity_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_readability_guard.dart';

/// سطح كارت بث فاخر — عمق، حافة، ظل واحد.
class PremiumCardSurface extends StatelessWidget {
  const PremiumCardSurface({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    required this.tier,
    this.primary,
    this.secondary,
    this.designedVoteClean = false,
    this.clipChild = true,
  });

  final Widget child;
  final double width;
  final double height;
  final PremiumCardTier tier;
  final Color? primary;
  final Color? secondary;
  final bool designedVoteClean;
  final bool clipChild;

  @override
  Widget build(BuildContext context) {
    final id = PremiumCardClubIdentity.current(primary: primary, secondary: secondary);
    final borderWidth = switch (tier) {
      PremiumCardTier.winner => PremiumCardBroadcastTokens.borderWidthWinner,
      PremiumCardTier.selected => PremiumCardBroadcastTokens.borderWidthSelected,
      PremiumCardTier.captain => PremiumCardBroadcastTokens.borderWidthActive,
      PremiumCardTier.locked => PremiumCardBroadcastTokens.borderWidthNormal,
      _ => PremiumCardBroadcastTokens.borderWidthNormal,
    };
    final borderOpacity = switch (tier) {
      PremiumCardTier.winner => PremiumCardBroadcastTokens.borderOpacityWinner,
      PremiumCardTier.selected => PremiumCardBroadcastTokens.borderOpacitySelected,
      PremiumCardTier.captain => PremiumCardBroadcastTokens.borderOpacityActive,
      _ => PremiumCardBroadcastTokens.borderOpacityNormal,
    };
    final borderColor = Color.lerp(
      Colors.white.withValues(alpha: borderOpacity),
      id.prestigeAccent,
      tier == PremiumCardTier.winner || tier == PremiumCardTier.selected ? 0.55 : 0.25,
    )!;

    final glowReduce = PremiumCardReadabilityGuard.highlightReduction(
      stackedGlow: designedVoteClean,
    );
    final shadowAlpha = designedVoteClean
        ? PremiumCardBroadcastTokens.shadowAlpha * 0.7
        : PremiumCardBroadcastTokens.shadowAlpha * glowReduce;

    Widget content = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumCardBroadcastTokens.cardRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        color: const Color(0xFF111111),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowAlpha),
            blurRadius: PremiumCardBroadcastTokens.shadowBlur,
            offset: PremiumCardBroadcastTokens.shadowOffset,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PremiumCardBroadcastTokens.innerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            PremiumCardFinishFx(
              width: width,
              height: height,
              tier: tier,
              identity: id,
              enabled: !designedVoteClean,
            ),
          ],
        ),
      ),
    );

    return RepaintBoundary(child: content);
  }
}
