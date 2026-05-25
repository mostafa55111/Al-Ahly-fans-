import 'package:flutter/material.dart';

/// أيقونة قوس وسهم — هوية إشعارات تطبيق الزمالك (بدل جرس Material).
class BowArrowNotificationIcon extends StatelessWidget {
  const BowArrowNotificationIcon({
    super.key,
    required this.color,
    this.size = 26,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BowArrowPainter(color: color),
    );
  }
}

class _BowArrowPainter extends CustomPainter {
  _BowArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.11;

    final bowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final bow = Path()
      ..moveTo(w * 0.14, h * 0.82)
      ..quadraticBezierTo(w * 0.5, h * 0.12, w * 0.86, h * 0.82);
    canvas.drawPath(bow, bowPaint);

    final stringPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = stroke * 0.55
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.14, h * 0.82),
      Offset(w * 0.86, h * 0.82),
      stringPaint,
    );

    final shaft = Paint()
      ..color = color
      ..strokeWidth = stroke * 0.75
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.24, h * 0.68),
      Offset(w * 0.78, h * 0.38),
      shaft,
    );

    final head = Path()
      ..moveTo(w * 0.78, h * 0.38)
      ..lineTo(w * 0.66, h * 0.32)
      ..lineTo(w * 0.7, h * 0.48)
      ..close();
    canvas.drawPath(
      head,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // ريشة بسيطة
    canvas.drawCircle(Offset(w * 0.24, h * 0.68), stroke * 0.45,
        Paint()..color = color.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _BowArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
