import 'dart:ui';

import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_layout_tokens.dart';

/// خريطة مراكز التشكيلات — إحداثيات نسبية (0–1) داخل منطقة اللعب.
abstract final class TacticalPositionMap {
  static String normalizeFormation(String formation) {
    final f = formation.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    switch (f) {
      case '433':
        return '4-3-3';
      case '442':
        return '4-4-2';
      case '352':
        return '3-5-2';
      case '343':
        return '3-4-3';
      case '4231':
        return '4-2-3-1';
      case '532':
        return '5-3-2';
      default:
        return f.isEmpty ? '4-3-3' : formation.trim();
    }
  }

  /// 11 مركزاً: حارس → دفاع → وسط → هجوم.
  static List<Offset> anchorsFor(String formation) {
    final f = normalizeFormation(formation).toLowerCase().replaceAll(' ', '');
    switch (f) {
      case '4-4-2':
      case '442':
        return _k442;
      case '3-5-2':
      case '352':
        return _k352;
      case '3-4-3':
      case '343':
        return _k343;
      case '4-2-3-1':
      case '4231':
        return _k4231;
      case '5-3-2':
      case '532':
        return _k532;
      case '4-3-3':
      case '433':
      default:
        return _k433;
    }
  }

  static bool isForwardSlot(int slotIndex) =>
      slotIndex >= TacticalLayoutTokens.forwardSlotStart;

  /// 4-3-3 — توازن دائرة المنتصف، مهاجمون بطولانيين.
  static const _k433 = <Offset>[
    Offset(0.50, 0.56),
    Offset(0.14, 0.46), Offset(0.36, 0.48), Offset(0.64, 0.48), Offset(0.86, 0.46),
    Offset(0.26, 0.34), Offset(0.50, 0.32), Offset(0.74, 0.34),
    Offset(0.20, 0.18), Offset(0.50, 0.14), Offset(0.80, 0.18),
  ];

  static const _k442 = <Offset>[
    Offset(0.50, 0.56),
    Offset(0.14, 0.46), Offset(0.36, 0.48), Offset(0.64, 0.48), Offset(0.86, 0.46),
    Offset(0.16, 0.34), Offset(0.38, 0.32), Offset(0.62, 0.32), Offset(0.84, 0.34),
    Offset(0.34, 0.16), Offset(0.66, 0.16),
  ];

  static const _k352 = <Offset>[
    Offset(0.50, 0.56),
    Offset(0.22, 0.48), Offset(0.50, 0.50), Offset(0.78, 0.48),
    Offset(0.10, 0.36), Offset(0.28, 0.33), Offset(0.50, 0.30), Offset(0.72, 0.33), Offset(0.90, 0.36),
    Offset(0.36, 0.15), Offset(0.64, 0.15),
  ];

  static const _k343 = <Offset>[
    Offset(0.50, 0.56),
    Offset(0.22, 0.48), Offset(0.50, 0.50), Offset(0.78, 0.48),
    Offset(0.14, 0.36), Offset(0.34, 0.33), Offset(0.66, 0.33), Offset(0.86, 0.36),
    Offset(0.20, 0.16), Offset(0.50, 0.12), Offset(0.80, 0.16),
  ];

  static const _k4231 = <Offset>[
    Offset(0.50, 0.56),
    Offset(0.14, 0.46), Offset(0.36, 0.48), Offset(0.64, 0.48), Offset(0.86, 0.46),
    Offset(0.36, 0.36), Offset(0.64, 0.36),
    Offset(0.22, 0.22), Offset(0.50, 0.17), Offset(0.78, 0.22),
    Offset(0.50, 0.10),
  ];

  static const _k532 = <Offset>[
    Offset(0.50, 0.56),
    Offset(0.08, 0.46), Offset(0.24, 0.48), Offset(0.50, 0.50), Offset(0.76, 0.48), Offset(0.92, 0.46),
    Offset(0.34, 0.33), Offset(0.50, 0.30), Offset(0.66, 0.33),
    Offset(0.38, 0.15), Offset(0.62, 0.15),
  ];
}
