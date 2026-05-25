import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/animation_budget_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_network/crowd_live_atmosphere.dart';

/// طبقة FX موحّدة للملعب: إضاءة + مسح ضوئي + موجة حرارة + وميض المتصدر — [CustomPainter] واحد.
class StadiumFxEngine extends StatelessWidget {
  const StadiumFxEngine({
    super.key,
    required this.identity,
    required this.phase,
    required this.votePulse,
    required this.leaderGlow,
    required this.intensity,
    required this.budget,
    this.fanPulse = 0,
    this.live = CrowdLiveAtmosphere.zero,
  });

  final CrowdAppIdentity identity;
  final double phase;
  final double votePulse;
  final double leaderGlow;
  final double intensity;
  final CrowdAnimationBudget budget;
  /// 0..1 نبض جماعي من طبقة الشعور — يزيد سرعة الإحساس بالضوء والحرارة.
  final double fanPulse;
  final CrowdLiveAtmosphere live;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _StadiumFxPainter(
          phase: phase,
          identity: identity,
          votePulse: votePulse,
          leaderGlow: leaderGlow,
          intensity: intensity,
          budget: budget,
          fanPulse: fanPulse.clamp(0.0, 1.0),
          live: live,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _StadiumFxPainter extends CustomPainter {
  _StadiumFxPainter({
    required this.phase,
    required this.identity,
    required this.votePulse,
    required this.leaderGlow,
    required this.intensity,
    required this.budget,
    required this.fanPulse,
    required this.live,
  });

  final double phase;
  final CrowdAppIdentity identity;
  final double votePulse;
  final double leaderGlow;
  final double intensity;
  final CrowdAnimationBudget budget;
  final double fanPulse;
  final CrowdLiveAtmosphere live;

  double get _fxScale {
    switch (budget) {
      case CrowdAnimationBudget.full:
        return 1.0;
      case CrowdAnimationBudget.reduced:
        return 0.72;
      case CrowdAnimationBudget.minimal:
        return 0.48;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final liveScale = live.runtimeScale;
    final boost = (0.55 + 0.45 * intensity) * _fxScale * liveScale * (1.0 + fanPulse * 0.22 + live.collectiveBreath01 * 0.12);
    final sweep = (0.18 +
            0.06 * math.sin(phase * (1.0 + 0.35 * fanPulse + live.energyWave01 * 0.2)) +
            votePulse * 0.38 +
            leaderGlow * 0.14 +
            live.atmosphereMemory01 * 0.08) *
        boost;

    final g = RadialGradient(
      center: Alignment(
        math.sin(phase * 0.4 + live.crowdDirectionX * 0.25) * 0.35,
        -0.55 + math.cos(phase * 0.3) * 0.12,
      ),
      radius: 1.05,
      colors: [
        identity.accentGlow.withValues(alpha: (0.09 + sweep * 0.38).clamp(0.0, 1.0)),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = g.createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    if (budget != CrowdAnimationBudget.minimal) {
      final sweepX = w * (0.5 + 0.5 * math.sin(phase * 0.55 + live.crowdDirectionX * 0.4));
      final band = Paint()
        ..shader = LinearGradient(
          begin: Alignment(sweepX / w - 0.08, -1),
          end: Alignment(sweepX / w + 0.08, 1),
          colors: [
            Colors.transparent,
            identity.secondaryColor.withValues(alpha: 0.05 + votePulse * 0.12),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawRect(Offset.zero & size, band);
    }

    final heat = 0.04 +
        votePulse * 0.22 +
        leaderGlow * 0.08 +
        fanPulse * 0.05 +
        live.emotionTemperature * 0.06;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = identity.primaryColor.withValues(alpha: heat * boost * 0.35)
        ..blendMode = BlendMode.plus,
    );

    if (votePulse > 0.35 && budget == CrowdAnimationBudget.full) {
      final flash = (votePulse - 0.35) / 0.65;
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04 * flash)
          ..blendMode = BlendMode.screen,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StadiumFxPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.votePulse != votePulse ||
        oldDelegate.leaderGlow != leaderGlow ||
        oldDelegate.intensity != intensity ||
        oldDelegate.budget != budget ||
        oldDelegate.fanPulse != fanPulse ||
        oldDelegate.live != live ||
        oldDelegate.identity.teamType != identity.teamType;
  }
}
