import 'package:flutter/material.dart';

/// مناطق التصميم النهائي للملعب — مُعرَّفة في الكود (ليست جزءاً من صورة الخلفية).
class StadiumBroadcastLayout {
  StadiumBroadcastLayout._();

  /// تفعيل التخطيط النهائي لشاشة الجمهور (كلا الناديين).
  static const bool enabled = true;

  static const double subsBarHeightFrac = 0.17;
  static const double reservesBarWidthFrac = 0.21;
  static const double headerTopPad = 8;
  static const double headerHeight = 44;

  /// منطقة التشكيلة الأساسية (تجنب Subs و Reserves).
  static const double playableLeft = 0.07;
  static const double playableTop = 0.11;
  static const double playableWidth = 0.70;
  static const double playableHeight = 0.52;

  static Rect playableRectOn(Size size) {
    return Rect.fromLTWH(
      size.width * playableLeft,
      size.height * playableTop,
      size.width * playableWidth,
      size.height * playableHeight,
    );
  }

  static Offset clampNormToPlayable(Offset n) {
    return Offset(
      n.dx.clamp(playableLeft + 0.02, playableLeft + playableWidth - 0.02),
      n.dy.clamp(playableTop + 0.02, playableTop + playableHeight - 0.02),
    );
  }

  static EdgeInsets subsPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return EdgeInsets.only(
      left: w * 0.05,
      right: w * reservesBarWidthFrac + 8,
      bottom: MediaQuery.paddingOf(context).bottom + 6,
    );
  }

  static double subsBarHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * subsBarHeightFrac;

  static double reservesBarWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width * reservesBarWidthFrac;
}
