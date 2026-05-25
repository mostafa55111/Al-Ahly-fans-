import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/animation_budget_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_network/crowd_live_atmosphere.dart';

/// ضباب + جزيئات متحركة — يُرسم مرة واحدة مع [RepaintBoundary].
class StadiumCrowdAtmosphereLayer extends StatefulWidget {
  const StadiumCrowdAtmosphereLayer({
    super.key,
    required this.identity,
    required this.momentum,
    required this.votePulse,
    this.intensity = 0.35,
    this.budget = CrowdAnimationBudget.full,
    this.fanPulse = 0,
    this.live = CrowdLiveAtmosphere.zero,
  });

  final CrowdAppIdentity identity;
  final CrowdMomentumTier momentum;
  /// 0..1 نبضة بعد التصويت.
  final double votePulse;
  /// 0..1 شدة الجو (صوت/FX) — تؤثر على كثافة الجزيئات.
  final double intensity;
  final CrowdAnimationBudget budget;
  /// 0..1 نبض جماعي — يزيد كثافة الجزيئات والضباب دون منطق تصويت جديد.
  final double fanPulse;
  final CrowdLiveAtmosphere live;

  @override
  State<StadiumCrowdAtmosphereLayer> createState() => _StadiumCrowdAtmosphereLayerState();
}

class _StadiumCrowdAtmosphereLayerState extends State<StadiumCrowdAtmosphereLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.identity.particlesFor(widget.momentum);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _CrowdFxPainter(
              phase: _ctrl.value * math.pi * 2,
              identity: widget.identity,
              momentum: widget.momentum,
              particles: style,
              votePulse: widget.votePulse,
              intensity: widget.intensity,
              budget: widget.budget,
              fanPulse: widget.fanPulse.clamp(0.0, 1.0),
              live: widget.live,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _CrowdFxPainter extends CustomPainter {
  _CrowdFxPainter({
    required this.phase,
    required this.identity,
    required this.momentum,
    required this.particles,
    required this.votePulse,
    required this.intensity,
    required this.budget,
    required this.fanPulse,
    required this.live,
  });

  final double phase;
  final CrowdAppIdentity identity;
  final CrowdMomentumTier momentum;
  final CrowdParticlesStyle particles;
  final double votePulse;
  final double intensity;
  final CrowdAnimationBudget budget;
  final double fanPulse;
  final CrowdLiveAtmosphere live;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tint = identity.momentumTint(momentum);
    final fog = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          identity.pitchGradientTop.withValues(alpha: 0.45),
          identity.pitchGradientBottom.withValues(alpha: 0.55),
          Colors.black.withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Offset.zero & size, fog);

    if (tint.a > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = tint);
    }

    final pulseBoost = 1 + votePulse * 0.85 + fanPulse * 0.55 + live.collectiveBreath01 * 0.35;
    final inten = (0.55 + 0.45 * intensity);
    final budgetMul = switch (budget) {
      CrowdAnimationBudget.full => 1.0,
      CrowdAnimationBudget.reduced => 0.72,
      CrowdAnimationBudget.minimal => 0.48,
    };
    final densityMul = 0.75 + live.density01 * 0.55;
    final count = (w * h / 4200 * particles.baseDensity * pulseBoost * inten * budgetMul * densityMul * live.runtimeScale)
        .round()
        .clamp(12, 120);
    final rnd = math.Random(7);
    for (var i = 0; i < count; i++) {
      final gx = (i * 97 % 1000) / 1000.0;
      final gy = (i * 53 % 1000) / 1000.0;
      final gravPull = 0.15 * live.crowdPressure;
      final ox = gx * w +
          math.sin(phase * 0.7 + i) * particles.maxDrift +
          (live.gravityNx - 0.5) * gravPull * w;
      final oy = gy * h +
          math.cos(phase * 0.55 + i * 0.3) * (particles.maxDrift * 0.6) +
          (live.gravityNy - 0.5) * gravPull * h * 0.5;
      final sz = particles.minSize + rnd.nextDouble() * (particles.maxSize - particles.minSize);
      final a = 0.04 + rnd.nextDouble() * 0.07 + (momentum.index * 0.02);
      final c = i.isEven ? identity.glowPrimary : identity.secondaryColor;
      canvas.drawCircle(
        Offset(ox, oy),
        sz,
        Paint()..color = c.withValues(alpha: a),
      );
    }

    if (budget != CrowdAnimationBudget.minimal) {
      final blur = budget == CrowdAnimationBudget.reduced ? 18.0 : 28.0;
      final mist = Paint()
        ..color = Colors.white.withValues(alpha: 0.03 + votePulse * 0.06)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawRect(Offset.zero & size, mist);
    }
  }

  @override
  bool shouldRepaint(covariant _CrowdFxPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.momentum != momentum ||
        oldDelegate.votePulse != votePulse ||
        oldDelegate.intensity != intensity ||
        oldDelegate.budget != budget ||
        oldDelegate.fanPulse != fanPulse ||
        oldDelegate.live != live ||
        oldDelegate.identity.teamType != identity.teamType;
  }
}
