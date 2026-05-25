import 'dart:math' as math;

import 'package:flutter/material.dart';

/// حلقة نسبة مئوية حول الكرت (صوت المستخدم).
class MatchVotePercentRing extends StatelessWidget {
  const MatchVotePercentRing({
    super.key,
    required this.percent,
    required this.size,
    this.color = const Color(0xFFFFD700),
  });

  final double percent;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(size, size),
        painter: _RingPainter(
          sweep: (percent.clamp(0, 100) / 100) * math.pi * 2,
          color: color,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.sweep, required this.color});

  final double sweep;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 2;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(c, r, bg);

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.sweep != sweep || oldDelegate.color != color;
}
