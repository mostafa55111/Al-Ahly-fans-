import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/formation_templates.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/stadium_slot_system.dart';

/// معاينة تكتيكية خفيفة للفورمة (بدون كروت).
class StadiumCmsFormationPreview extends StatelessWidget {
  const StadiumCmsFormationPreview({
    super.key,
    required this.formation,
    required this.accent,
    this.height = 200,
  });

  final String formation;
  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _FormationPreviewPainter(
            formation: formation,
            accent: accent,
          ),
        ),
      ),
    );
  }
}

class _FormationPreviewPainter extends CustomPainter {
  _FormationPreviewPainter({required this.formation, required this.accent});

  final String formation;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = StadiumPitchPlayableRect.normalizedRectOn(size);
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = accent.withValues(alpha: 0.35),
    );
    final slots = FormationTemplates.slotsFor(formation);
    final dot = Paint()..color = accent.withValues(alpha: 0.85);
    for (final s in slots) {
      final p = Offset(rect.left + s.dx * rect.width, rect.top + s.dy * rect.height);
      canvas.drawCircle(p, 5, dot);
      canvas.drawCircle(
        p,
        8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FormationPreviewPainter oldDelegate) =>
      oldDelegate.formation != formation || oldDelegate.accent != accent;
}
