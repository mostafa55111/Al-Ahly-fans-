import 'package:flutter/material.dart';

/// ثوابت أساس الملعب العمودي — جاهزة للمراحل اللاحقة (بدون حركة في Phase 1).
abstract final class StadiumFoundationTokens {
  static const String assetPath =
      'assets/images/stadiums/stadium_foundation_vertical.png';

  /// إطار آمن للكروت والتبويبات فوق الملعب.
  static const double playableTopFrac = 0.10;
  static const double playableBottomFrac = 0.22;
  static const double playableHorizontalFrac = 0.06;

  /// تعتيم الحواف (Phase 2+).
  static const double darkVignetteEdgeAlpha = 0.58;
  static const double fieldDimAlpha = 0.12;

  /// توهج خطوط الملعب — أحمر/برتقالي للأهداف، أبيض/ذهبي للمنتصف.
  static const Color lineGlowGoalWarm = Color(0xFFFF6B35);
  static const Color lineGlowGoalHot = Color(0xFFE53935);
  static const Color lineGlowCenter = Color(0xFFFFF8E7);

  /// ظل المدرجات العلوية.
  static const Color topStadiumShadow = Color(0xCC000000);

  /// تدرج أسفل الشاشة.
  static const Color bottomFade = Color(0xF0000000);

  static const EdgeInsets safeMinimum = EdgeInsets.symmetric(horizontal: 4);
}
