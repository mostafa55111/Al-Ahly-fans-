import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_motion_profile.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_visual_tokens.dart';

/// عمق بصري: vignette + إضاءة مركزية + نبض ملعب خفيف.
class StadiumDepthSystem extends StatelessWidget {
  const StadiumDepthSystem({
    super.key,
    required this.phase,
    required this.breathPhase01,
    this.identity,
  });

  final MatchNightPhase phase;
  final double breathPhase01;
  final CrowdAppIdentity? identity;

  @override
  Widget build(BuildContext context) {
    final tokens = StadiumVisualTokens.of(identity);
    final motion = StadiumMotionProfile.forPhase(phase);
    final light = MatchNightAtmosphere.lightingIntensity(phase);
    final breath = math.sin(breathPhase01 * math.pi * 2) * motion.breathAmplitude;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.08),
                radius: 0.92 + breath,
                colors: [
                  tokens.primary.withValues(alpha: 0.06 * light),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.72],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.08,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: tokens.vignetteEdgeAlpha * light),
                ],
                stops: const [0.58, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.38 + tokens.pitchDimAlpha * 0.5),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
