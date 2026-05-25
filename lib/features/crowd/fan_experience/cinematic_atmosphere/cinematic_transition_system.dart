import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_motion_tokens.dart';

/// انتقالات ناعمة — fade + scale طفيف فقط.
class CinematicTransitionSystem extends StatelessWidget {
  const CinematicTransitionSystem({
    super.key,
    required this.transitionKey,
    required this.child,
  });

  final Object transitionKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: CinematicMotionTokens.maxTransition,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(
          begin: CinematicMotionTokens.transitionScaleIn,
          end: 1.0,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: scale,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(transitionKey),
        child: child,
      ),
    );
  }
}
