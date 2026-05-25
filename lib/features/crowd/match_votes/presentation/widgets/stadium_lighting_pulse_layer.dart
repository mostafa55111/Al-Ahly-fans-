import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';

/// إضاءة ديناميكية خفيفة + نبضة عند التصويت.
class StadiumLightingPulseLayer extends StatelessWidget {
  const StadiumLightingPulseLayer({
    super.key,
    required this.identity,
    required this.phase,
    required this.votePulse,
    required this.leaderGlow,
  });

  final CrowdAppIdentity identity;
  final double phase;
  final double votePulse;
  final double leaderGlow;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _LightingPainter(
          phase: phase,
          identity: identity,
          votePulse: votePulse,
          leaderGlow: leaderGlow,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _LightingPainter extends CustomPainter {
  _LightingPainter({
    required this.phase,
    required this.identity,
    required this.votePulse,
    required this.leaderGlow,
  });

  final double phase;
  final CrowdAppIdentity identity;
  final double votePulse;
  final double leaderGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sweep = 0.18 + 0.06 * math.sin(phase) + votePulse * 0.35 + leaderGlow * 0.12;
    final g = RadialGradient(
      center: Alignment(math.sin(phase * 0.4) * 0.35, -0.55 + math.cos(phase * 0.3) * 0.12),
      radius: 1.05,
      colors: [
        identity.accentGlow.withValues(alpha: 0.09 + sweep * 0.35),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = g.createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  @override
  bool shouldRepaint(covariant _LightingPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.votePulse != votePulse ||
        oldDelegate.leaderGlow != leaderGlow;
  }
}
