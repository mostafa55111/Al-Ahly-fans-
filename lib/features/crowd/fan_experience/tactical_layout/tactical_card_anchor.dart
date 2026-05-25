import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_finish_fx.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_hierarchy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_card_focus_state.dart';

/// ربط الكارت بموقعه — توهج قاعدي خفيف وظل عمق واحد.
class TacticalCardAnchor extends StatelessWidget {
  const TacticalCardAnchor({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    required this.accentColor,
    required this.focus,
    this.emphasizeForward = false,
  });

  final Widget child;
  final double width;
  final double height;
  final Color accentColor;
  final TacticalCardFocusKind focus;
  final bool emphasizeForward;

  @override
  Widget build(BuildContext context) {
    final scale = TacticalCardFocusState.scaleFor(
      focus,
      emphasizeForward: emphasizeForward,
    );
    final opacity = TacticalCardFocusState.opacityFor(focus);
    final tier = switch (focus) {
      TacticalCardFocusKind.winner => PremiumCardTier.winner,
      TacticalCardFocusKind.selected => PremiumCardTier.selected,
      TacticalCardFocusKind.locked => PremiumCardTier.locked,
      _ => PremiumCardTier.normal,
    };

    return RepaintBoundary(
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: width + 20,
          height: height + 16,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 0,
                child: PremiumCardFinishFx.fieldSeparation(
                  width: width,
                  accent: accentColor,
                  tier: tier,
                ),
              ),
              Positioned(
                bottom: 4,
                child: Opacity(opacity: opacity, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
