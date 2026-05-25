import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/stadium_slot_system.dart';

/// خطوط تكتيكية واضحة فوق الملعب — بدون شبكة سداسية مزدحمة.
class MatchStadiumPitchOverlay extends StatefulWidget {
  const MatchStadiumPitchOverlay({
    super.key,
    required this.tacticalAccent,
    this.momentumTier = CrowdMomentumTier.calm,
  });

  final Color tacticalAccent;
  final CrowdMomentumTier momentumTier;

  @override
  State<MatchStadiumPitchOverlay> createState() =>
      _MatchStadiumPitchOverlayState();
}

class _MatchStadiumPitchOverlayState extends State<MatchStadiumPitchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _TacticalGlowPainter(
              phase: _ctrl.value * math.pi * 2,
              accent: widget.tacticalAccent,
              momentumBoost: 1 + widget.momentumTier.index * 0.08,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _TacticalGlowPainter extends CustomPainter {
  _TacticalGlowPainter({
    required this.phase,
    required this.accent,
    required this.momentumBoost,
  });

  final double phase;
  final Color accent;
  final double momentumBoost;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w * 0.5;
    final shimmer = 0.28 + 0.10 * math.sin(phase);

    void strokePath(Path path, {double width = 1.4, double glowAlpha = 0.14}) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * momentumBoost
          ..color = accent.withValues(alpha: glowAlpha + 0.10 * shimmer)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 0.5 * momentumBoost
          ..color = accent.withValues(alpha: 0.42 + 0.12 * shimmer),
      );
    }

    final mid = StadiumPitchPlayableRect.normalizedRectOn(size);

    strokePath(Path()..addRect(mid));

    final centerCircle = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, mid.center.dy), radius: w * 0.13));
    strokePath(centerCircle);

    final halfLine = Path()
      ..moveTo(mid.left, mid.center.dy)
      ..lineTo(mid.right, mid.center.dy);
    strokePath(halfLine, width: 1.1);

    final boxW = mid.width * 0.42;
    final boxH = mid.height * 0.16;
    final topBox = Rect.fromCenter(
      center: Offset(cx, mid.top + boxH * 0.55),
      width: boxW,
      height: boxH,
    );
    final bottomBox = Rect.fromCenter(
      center: Offset(cx, mid.bottom - boxH * 0.55),
      width: boxW,
      height: boxH,
    );
    strokePath(Path()..addRect(topBox), width: 1.1, glowAlpha: 0.10);
    strokePath(Path()..addRect(bottomBox), width: 1.1, glowAlpha: 0.10);

    final spotR = w * 0.018;
    canvas.drawCircle(
      Offset(cx, mid.center.dy),
      spotR,
      Paint()..color = accent.withValues(alpha: 0.35 + 0.1 * shimmer),
    );
    canvas.drawCircle(
      Offset(cx, topBox.center.dy),
      spotR * 0.9,
      Paint()..color = accent.withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      Offset(cx, bottomBox.center.dy),
      spotR * 0.9,
      Paint()..color = accent.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _TacticalGlowPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.accent != accent ||
      oldDelegate.momentumBoost != momentumBoost;
}
