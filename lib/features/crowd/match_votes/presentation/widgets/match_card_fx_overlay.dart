import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_overlay_type.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/animation_budget_controller.dart';

/// طبقة FX فوق صورة الكرت الجاهزة — لا تعدّل أصل الصورة؛ [CustomPainter] فقط.
class MatchCardFxOverlay extends StatelessWidget {
  const MatchCardFxOverlay({
    super.key,
    required this.rarity,
    required this.theme,
    required this.style,
    required this.animatedOverlay,
    this.phase01 = 0,
    this.crowdIntensity = 0.32,
    this.isVoteLeader = false,
    this.isVoteSelected = false,
    this.liveVotePercent,
    this.isAhlyClub = true,
    this.primaryAccent,
    this.secondaryAccent,
    this.fxBudget = CrowdAnimationBudget.full,
    this.particleSeed = 0,
  });

  final String rarity;
  final String theme;
  final String style;
  final String animatedOverlay;

  /// 0..1 طور حركة مشترك من الملعب.
  final double phase01;

  /// 0..1 من [CrowdIntensityController].
  final double crowdIntensity;

  final bool isVoteLeader;
  final bool isVoteSelected;
  final double? liveVotePercent;
  final bool isAhlyClub;
  final Color? primaryAccent;
  final Color? secondaryAccent;
  final CrowdAnimationBudget fxBudget;
  final int particleSeed;

  @override
  Widget build(BuildContext context) {
    final p1 = primaryAccent ?? (isAhlyClub ? const Color(0xFFC8102E) : const Color(0xFF1565C0));
    final p2 = secondaryAccent ?? (isAhlyClub ? const Color(0xFFFFD700) : Colors.white);

    final resolved = resolveMatchCardOverlayType(
      animatedOverlayRaw: animatedOverlay,
      rarity: rarity,
      style: style,
      theme: theme,
    );

    final ci = crowdIntensity.clamp(0.0, 1.0);
    final vote01 = ((liveVotePercent ?? 0) / 100).clamp(0.0, 1.0);
    final leaderMul = 1.0 + (isVoteLeader ? 0.42 : 0.0) * (0.45 + 0.55 * ci);
    final selMul = 1.0 + (isVoteSelected ? 0.12 : 0.0);

    final speed = 1.0 + ci * 0.95 + vote01 * 0.22 + (isVoteLeader ? 0.18 : 0.0);
    final phase = phase01 * math.pi * 2 * speed;

    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _MatchCardRuntimeFxPainter(
            overlayType: resolved,
            rarityWire: rarity,
            styleWire: style,
            themeWire: theme,
            phase: phase,
            crowdIntensity: ci,
            leaderMul: leaderMul * selMul,
            votePct01: vote01,
            isVoteLeader: isVoteLeader,
            isAhlyClub: isAhlyClub,
            c1: p1,
            c2: p2,
            budget: fxBudget,
            seed: particleSeed,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MatchCardRuntimeFxPainter extends CustomPainter {
  _MatchCardRuntimeFxPainter({
    required this.overlayType,
    required this.rarityWire,
    required this.styleWire,
    required this.themeWire,
    required this.phase,
    required this.crowdIntensity,
    required this.leaderMul,
    required this.votePct01,
    required this.isVoteLeader,
    required this.isAhlyClub,
    required this.c1,
    required this.c2,
    required this.budget,
    required this.seed,
  });

  final MatchCardOverlayType overlayType;
  final String rarityWire;
  final String styleWire;
  final String themeWire;
  final double phase;
  final double crowdIntensity;
  final double leaderMul;
  final double votePct01;
  final bool isVoteLeader;
  final bool isAhlyClub;
  final Color c1;
  final Color c2;
  final CrowdAnimationBudget budget;
  final int seed;

  bool get _minimal => budget == CrowdAnimationBudget.minimal;
  bool get _reduced => budget == CrowdAnimationBudget.reduced;

  double _amp(double base) => (base * leaderMul * (0.75 + 0.25 * crowdIntensity)).clamp(0.04, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w < 4 || h < 4) return;

    final rnd = math.Random(seed ^ 0x9e3779b9);

    switch (overlayType) {
      case MatchCardOverlayType.none:
        _paintLegacyRarityAura(canvas, w, h);
        break;
      case MatchCardOverlayType.redLightning:
        _paintRedLightning(canvas, w, h);
        break;
      case MatchCardOverlayType.goldenAura:
        _paintGoldenAura(canvas, w, h);
        break;
      case MatchCardOverlayType.royalGlow:
        _paintRoyalGlow(canvas, w, h);
        break;
      case MatchCardOverlayType.fireBurst:
        _paintFireBurst(canvas, w, h, rnd);
        break;
      case MatchCardOverlayType.ultraPulse:
        _paintUltraPulse(canvas, w, h);
        break;
      case MatchCardOverlayType.neonWave:
        _paintNeonWave(canvas, w, h);
        break;
      case MatchCardOverlayType.eagleEnergy:
        _paintEagleEnergy(canvas, w, h);
        break;
      case MatchCardOverlayType.knightEnergy:
        _paintKnightEnergy(canvas, w, h);
        _paintRoyalGlow(canvas, w, h, strength: 0.55);
        break;
      case MatchCardOverlayType.glitchEnergy:
        if (!_minimal) _paintGlitchEnergy(canvas, w, h);
        break;
      case MatchCardOverlayType.legendaryStorm:
        _paintGoldenAura(canvas, w, h, strength: 0.95);
        if (!_minimal) _paintEnergySweep(canvas, w, h);
        if (!_minimal && !_reduced) _paintRedLightning(canvas, w, h, bolts: 2, alphaScale: 0.55);
        _paintLeaderRays(canvas, w, h);
        break;
    }

    if (isVoteLeader && overlayType != MatchCardOverlayType.legendaryStorm) {
      _paintLeaderRays(canvas, w, h);
    }
  }

  /// هالة خفيفة من rarity/style (مسار قديم) — عندما يكون النوع [none] فقط.
  void _paintLegacyRarityAura(Canvas canvas, double w, double h, {double strength = 1.0}) {
    final r = rarityWire.toLowerCase().trim();
    final s = styleWire.toLowerCase().trim();
    final t = themeWire.toLowerCase().trim();

    Color a = Colors.transparent;
    Color b = Colors.transparent;
    var blend = BlendMode.screen;

    if (r == 'legendary' || r == 'mythic') {
      a = const Color(0x55FFD700);
      b = const Color(0x11FF8C00);
    } else if (s == 'ultra_red' || t == 'ahly_fire') {
      a = const Color(0x44C8102E);
      b = const Color(0x11800000);
    } else if (s == 'royal_white' || t == 'zamalek_royal') {
      a = const Color(0x331565C0);
      b = const Color(0x11FFFFFF);
      blend = BlendMode.plus;
    } else if (r == 'epic') {
      a = const Color(0x449C27B0);
      b = const Color(0x118000FF);
    } else {
      return;
    }

    final pulse = 0.85 + 0.15 * math.sin(phase * 0.9);
    final alpha = (_amp(0.22) * pulse * strength).clamp(0.06, 0.38);
    final g = RadialGradient(
      center: Alignment(0.12 * math.sin(phase * 0.6), -0.38 + 0.08 * math.cos(phase * 0.45)),
      radius: 1.05,
      colors: [
        a.withValues(alpha: alpha),
        b,
        Colors.transparent,
      ],
      stops: const [0.0, 0.42, 1.0],
    );
    final paint = Paint()
      ..shader = g.createShader(Rect.fromLTWH(0, 0, w, h))
      ..blendMode = blend;
    canvas.drawRect(Offset.zero & Size(w, h), paint);
  }

  void _paintRedLightning(Canvas canvas, double w, double h, {int bolts = 4, double alphaScale = 1.0}) {
    final n = _minimal ? 2 : (_reduced ? 3 : bolts);
    for (var b = 0; b < n; b++) {
      final ox = (b + 0.35) / n * w;
      final path = Path()..moveTo(ox, h * 0.08);
      var y = h * 0.08;
      final zig = 6 + b;
      for (var i = 0; i < zig; i++) {
        y += h * 0.11;
        final jx = 3.5 * math.sin(phase * 1.2 + i * 1.7 + b) * leaderMul;
        path.lineTo(ox + jx, y);
      }
      path.lineTo(ox + 2 * math.sin(phase + b), h * 0.92);
      final a = (0.28 * alphaScale * _amp(1.0)).clamp(0.05, 0.55);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (_minimal ? 1.0 : 1.35) * leaderMul
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(c1, c2, 0.35)!.withValues(alpha: a),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.45
          ..color = Colors.white.withValues(alpha: a * 0.55),
      );
    }
  }

  void _paintGoldenAura(Canvas canvas, double w, double h, {double strength = 1.0}) {
    final pulse = 0.82 + 0.18 * math.sin(phase * 0.85);
    final alpha = (_amp(0.26) * pulse * strength).clamp(0.05, 0.48);
    final g = RadialGradient(
      center: const Alignment(0, -0.55),
      radius: 1.15,
      colors: [
        c2.withValues(alpha: alpha),
        c1.withValues(alpha: alpha * 0.35),
        Colors.transparent,
      ],
      stops: const [0.0, 0.38, 1.0],
    );
    canvas.drawRect(
      Offset.zero & Size(w, h),
      Paint()
        ..shader = g.createShader(Rect.fromLTWH(0, 0, w, h))
        ..blendMode = BlendMode.screen,
    );
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * leaderMul
      ..color = c2.withValues(alpha: 0.12 * _amp(1.0));
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.22), width: w * 0.9, height: h * 0.38),
      phase * 0.08,
      math.pi * 1.1,
      false,
      arcPaint,
    );
  }

  void _paintRoyalGlow(Canvas canvas, double w, double h, {double strength = 1.0}) {
    final pulse = 0.78 + 0.22 * math.sin(phase * 0.65);
    final a = (_amp(0.2) * pulse * strength).clamp(0.04, 0.42);
    final top = RadialGradient(
      center: const Alignment(0, -1),
      radius: 1.05,
      colors: [
        Color.lerp(c1, Colors.white, 0.48)!.withValues(alpha: a),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Offset.zero & Size(w, h),
      Paint()
        ..shader = top.createShader(Rect.fromLTWH(0, 0, w, h))
        ..blendMode = BlendMode.plus,
    );
    final bottom = RadialGradient(
      center: const Alignment(0, 1),
      radius: 0.9,
      colors: [
        c1.withValues(alpha: a * 0.5),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Offset.zero & Size(w, h),
      Paint()
        ..shader = bottom.createShader(Rect.fromLTWH(0, 0, w, h))
        ..blendMode = BlendMode.plus,
    );
  }

  void _paintFireBurst(Canvas canvas, double w, double h, math.Random rnd) {
    final count = _minimal ? 5 : (_reduced ? 9 : (12 + (crowdIntensity * 8).round()));
    final baseY = h * 0.88;
    for (var i = 0; i < count; i++) {
      final u = rnd.nextDouble();
      final x = w * (0.08 + u * 0.84) + math.sin(phase * 1.4 + i) * 2.5 * leaderMul;
      final r = 1.2 + rnd.nextDouble() * 2.8 * (0.85 + crowdIntensity * 0.4);
      final py = baseY - (i % 3) * 2.0 - math.sin(phase + i * 0.7) * 3 * votePct01;
      canvas.drawCircle(
        Offset(x, py),
        r,
        Paint()
          ..color = Color.lerp(c1, const Color(0xFFFF9800), rnd.nextDouble())!
              .withValues(alpha: 0.07 * _amp(1.0)),
      );
    }
  }

  void _paintUltraPulse(Canvas canvas, double w, double h) {
    final pulse = 0.5 + 0.5 * math.sin(phase * (1.35 + crowdIntensity * 1.2 + votePct01 * 0.9));
    final inset = 2.0 + (1.0 - pulse) * 5.5 * (0.7 + crowdIntensity * 0.5);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * leaderMul
        ..color = c1.withValues(alpha: 0.12 + 0.22 * pulse * _amp(1.0)),
    );
  }

  void _paintNeonWave(Canvas canvas, double w, double h) {
    final path = Path();
    final y0 = h * 0.78;
    path.moveTo(0, y0);
    for (var x = 0.0; x <= w; x += 2.5) {
      final y = y0 + math.sin((x / w) * math.pi * 4 + phase) * 2.8 * leaderMul;
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Color.lerp(c1, c2, 0.5)!.withValues(alpha: 0.18 * _amp(1.0)),
    );
  }

  void _paintEagleEnergy(Canvas canvas, double w, double h) {
    final a = 0.16 * _amp(1.0) * (isAhlyClub ? 1.15 : 0.85);
    final wing = Path()
      ..moveTo(w * 0.08, h * 0.18)
      ..lineTo(w * 0.42, h * 0.32)
      ..lineTo(w * 0.5, h * 0.22)
      ..lineTo(w * 0.58, h * 0.32)
      ..lineTo(w * 0.92, h * 0.18);
    canvas.drawPath(
      wing,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * leaderMul
        ..color = c1.withValues(alpha: a),
    );
    canvas.drawPath(
      wing,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.45
        ..color = c2.withValues(alpha: a * 0.7),
    );
  }

  void _paintKnightEnergy(Canvas canvas, double w, double h) {
    final a = 0.14 * _amp(1.0);
    for (final sx in [-1.0, 1.0]) {
      final cx = w * 0.5 + sx * w * 0.38;
      canvas.drawLine(
        Offset(cx, h * 0.25),
        Offset(cx, h * 0.72),
        Paint()
          ..strokeWidth = 1.1
          ..color = c1.withValues(alpha: a),
      );
      canvas.drawLine(
        Offset(cx - 5, h * 0.48),
        Offset(cx + 5, h * 0.48),
        Paint()
          ..strokeWidth = 0.9
          ..color = Colors.white.withValues(alpha: a * 0.65),
      );
    }
  }

  void _paintGlitchEnergy(Canvas canvas, double w, double h) {
    final shift = 2.0 * math.sin(phase * 3.2);
    final a = 0.08 * _amp(1.0);
    for (var k = 0; k < 3; k++) {
      final y = h * (0.28 + k * 0.18);
      canvas.save();
      canvas.translate(shift * (k.isEven ? 1 : -1), 0);
      canvas.drawRect(
        Rect.fromLTWH(1, y, w - 2, h * 0.06),
        Paint()..color = c2.withValues(alpha: a * (0.6 + 0.2 * k)),
      );
      canvas.restore();
    }
  }

  void _paintEnergySweep(Canvas canvas, double w, double h) {
    final t = (math.sin(phase * 0.9) * 0.5 + 0.5);
    final x = -w * 0.25 + t * (w * 1.5);
    final grad = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        c2.withValues(alpha: 0.14 * _amp(1.0)),
        Colors.transparent,
      ],
      stops: const [0.35, 0.5, 0.65],
    );
    canvas.drawRect(
      Rect.fromLTWH(x, 0, w * 0.22, h),
      Paint()
        ..shader = grad.createShader(Rect.fromLTWH(x, 0, w * 0.22, h))
        ..blendMode = BlendMode.screen,
    );
  }

  void _paintLeaderRays(Canvas canvas, double w, double h) {
    if (_minimal) return;
    final cx = w * 0.78;
    final cy = h * 0.1;
    final rays = _reduced ? 5 : 9;
    final a = 0.06 * _amp(1.0) * (0.85 + crowdIntensity * 0.35);
    final denom = math.max(1, rays - 1);
    for (var i = 0; i < rays; i++) {
      final ang = -math.pi * 0.35 + (i / denom) * math.pi * 0.55 + math.sin(phase) * 0.08;
      final len = w * (0.14 + 0.06 * math.sin(phase * 1.3 + i));
      final p2 = Offset(cx + math.cos(ang) * len, cy + math.sin(ang) * len);
      canvas.drawLine(
        Offset(cx, cy),
        p2,
        Paint()
          ..strokeWidth = 1.0
          ..color = c2.withValues(alpha: a),
      );
    }
    if (!_reduced) {
      final n = 6;
      final dotA = 0.045 * _amp(1.0);
      for (var i = 0; i < n; i++) {
        final u = i / n;
        final px = cx + math.cos(phase * 1.1 + u * math.pi * 2) * 10;
        final py = cy + math.sin(phase * 0.9 + u * math.pi * 2) * 8;
        canvas.drawCircle(
          Offset(px, py),
          1.1 + 0.35 * math.sin(phase + i),
          Paint()..color = c2.withValues(alpha: dotA),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatchCardRuntimeFxPainter oldDelegate) {
    return oldDelegate.overlayType != overlayType ||
        oldDelegate.phase != phase ||
        oldDelegate.crowdIntensity != crowdIntensity ||
        oldDelegate.leaderMul != leaderMul ||
        oldDelegate.votePct01 != votePct01 ||
        oldDelegate.budget != budget ||
        oldDelegate.seed != seed ||
        oldDelegate.c1 != c1 ||
        oldDelegate.c2 != c2 ||
        oldDelegate.isVoteLeader != isVoteLeader ||
        oldDelegate.isAhlyClub != isAhlyClub ||
        oldDelegate.rarityWire != rarityWire ||
        oldDelegate.styleWire != styleWire ||
        oldDelegate.themeWire != themeWire;
  }
}
