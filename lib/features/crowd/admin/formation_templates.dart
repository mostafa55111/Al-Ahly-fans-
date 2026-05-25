import 'dart:ui' show Offset;

/// إحداثيات معيّنة (0–1) على الملعب لكل تشكيلة — 11 مركزاً.
class FormationTemplates {
  FormationTemplates._();

  static List<Offset> slotsFor(String formation) {
    switch (formation.trim()) {
      case '4-2-3-1':
        return List<Offset>.from(formation4231);
      case '3-5-2':
        return List<Offset>.from(formation352);
      case '4-3-3':
      default:
        return List<Offset>.from(formation433);
    }
  }

  /// 4-3-3 — خطوط تكتيكية كلاسيكية.
  static const formation433 = <Offset>[
    Offset(0.50, 0.90),
    Offset(0.18, 0.72),
    Offset(0.38, 0.74),
    Offset(0.62, 0.74),
    Offset(0.82, 0.72),
    Offset(0.22, 0.52),
    Offset(0.50, 0.50),
    Offset(0.78, 0.52),
    Offset(0.32, 0.30),
    Offset(0.50, 0.22),
    Offset(0.68, 0.30),
  ];

  static const formation4231 = <Offset>[
    Offset(0.50, 0.90),
    Offset(0.15, 0.72),
    Offset(0.35, 0.74),
    Offset(0.65, 0.74),
    Offset(0.85, 0.72),
    Offset(0.30, 0.52),
    Offset(0.50, 0.48),
    Offset(0.70, 0.52),
    Offset(0.22, 0.32),
    Offset(0.50, 0.22),
    Offset(0.78, 0.32),
  ];

  static const formation352 = <Offset>[
    Offset(0.50, 0.90),
    Offset(0.22, 0.74),
    Offset(0.50, 0.76),
    Offset(0.78, 0.74),
    Offset(0.12, 0.54),
    Offset(0.30, 0.50),
    Offset(0.50, 0.46),
    Offset(0.70, 0.50),
    Offset(0.88, 0.54),
    Offset(0.38, 0.28),
    Offset(0.62, 0.28),
  ];
}
