import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_atmosphere_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_motion_profile.dart';

/// عزل بصري خفيف للكارت المختار أثناء التصويت.
class VoteFocusDimLayer extends StatelessWidget {
  const VoteFocusDimLayer({
    super.key,
    required this.focusedPlayerId,
    required this.myVotedPlayerId,
    required this.child,
  });

  final String? focusedPlayerId;
  final String? myVotedPlayerId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final voted = myVotedPlayerId != null && myVotedPlayerId!.isNotEmpty;
    if (!voted) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
            ),
          ),
        ),
      ],
    );
  }
}

/// حلقة توهج ناعمة خلف الكارت — نبض بطيء.
class VoteCardGlowRing extends StatelessWidget {
  const VoteCardGlowRing({
    super.key,
    required this.color,
    required this.width,
    required this.height,
    required this.breathPhase01,
    this.enabled = true,
  });

  final Color color;
  final double width;
  final double height;
  final double breathPhase01;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    final phase = StadiumAtmosphereScope.of(context);
    final motion = StadiumMotionProfile.forPhase(phase);
    if (!motion.allowCardPulse) return const SizedBox.shrink();

    final pulse = 1.0 +
        math.sin(breathPhase01 * math.pi * 2) * motion.glowPulseAmplitude;

    return Positioned(
      bottom: 2,
      child: Transform.scale(
        scale: pulse,
        child: Container(
          width: width * 1.14,
          height: width * 0.24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.38),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
