import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/animation_budget_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_network/crowd_live_atmosphere.dart';

/// نبض جماعي وموجات ضوء متزامنة — [CustomPainter] فقط.
class CrowdCollectivePulseLayer extends StatelessWidget {
  const CrowdCollectivePulseLayer({
    super.key,
    required this.identity,
    required this.phase,
    required this.live,
    required this.budget,
  });

  final CrowdAppIdentity identity;
  final double phase;
  final CrowdLiveAtmosphere live;
  final CrowdAnimationBudget budget;

  @override
  Widget build(BuildContext context) {
    if (budget == CrowdAnimationBudget.minimal && live.runtimeScale < 0.45) {
      return const SizedBox.expand();
    }
    return RepaintBoundary(
      child: CustomPaint(
        painter: _CollectivePulsePainter(
          phase: phase,
          identity: identity,
          live: live,
          budget: budget,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CollectivePulsePainter extends CustomPainter {
  _CollectivePulsePainter({
    required this.phase,
    required this.identity,
    required this.live,
    required this.budget,
  });

  final double phase;
  final CrowdAppIdentity identity;
  final CrowdLiveAtmosphere live;
  final CrowdAnimationBudget budget;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final breath = live.collectiveBreath01;
    final wave = live.energyWave01;
    final dir = live.crowdDirectionX;
    final mem = live.atmosphereMemory01;
    final scale = live.runtimeScale;

    if (budget != CrowdAnimationBudget.minimal) {
      final sweepX = w * (0.5 + 0.5 * math.sin(phase * 0.42 + dir * 0.35));
      final band = Paint()
        ..shader = LinearGradient(
          begin: Alignment(sweepX / w - 0.12, 0),
          end: Alignment(sweepX / w + 0.12, 1),
          colors: [
            Colors.transparent,
            identity.accentGlow.withValues(alpha: (0.04 + breath * 0.1) * scale),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawRect(Offset.zero & size, band);
    }

    final gx = live.gravityNx * w;
    final grav = RadialGradient(
      center: Alignment(
        (live.gravityNx - 0.5) * 1.6,
        (live.gravityNy - 0.5) * 1.2,
      ),
      radius: 0.55 + wave * 0.35,
      colors: [
        identity.primaryColor.withValues(alpha: (0.06 + wave * 0.14 + mem * 0.08) * scale),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = grav.createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    final waveCount = budget == CrowdAnimationBudget.full ? 3 : 2;
    for (var i = 0; i < waveCount; i++) {
      final ph = phase + i * 0.9;
      final y = h * (0.22 + i * 0.28) + math.sin(ph) * 6 * breath;
      final alpha = (0.03 + breath * 0.06 + mem * 0.04) * scale;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(gx * 0.35 + w * 0.32, y), width: w * 0.92, height: 28 + breath * 18),
        Paint()
          ..color = identity.secondaryColor.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }

    final inhale = lerpDouble(0.98, 1.02, breath)!;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.012 * inhale * scale)
        ..blendMode = BlendMode.softLight,
    );
  }

  @override
  bool shouldRepaint(covariant _CollectivePulsePainter old) {
    return old.phase != phase ||
        old.live != live ||
        old.budget != budget;
  }
}
