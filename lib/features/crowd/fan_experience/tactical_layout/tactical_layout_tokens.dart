import 'package:flutter/material.dart';

/// ثوابت تخطيط التشكيلة التكتيكية — لا أرقام سحرية في الودجتات.
abstract final class TacticalLayoutTokens {
  static const double heroScale = 1.0;
  static const double benchScale = 0.78;
  static const double forwardHeroScale = 1.06;

  static const double selectedScale = 1.04;
  static const double winnerScale = 1.035;
  static const double activeScale = 1.02;
  static const double lockedScale = 0.94;
  static const double finalizingScale = 0.97;

  static const double cardVerticalGap = 0.04;
  static const double cardHorizontalGap = 0.06;
  static const double forwardLineSpread = 0.76;
  static const double midfieldCompress = 0.92;

  static const double safeTopRatio = 0.10;
  static const double safeBottomRatio = 0.22;
  static const double safeSideRatio = 0.06;

  static const double focusOpacity = 1.0;
  static const double selectedOpacity = 1.0;
  static const double lockedOpacity = 0.72;
  static const double idleOpacity = 0.9;
  static const double finalizingOpacity = 0.82;

  /// مزج خفيف بين RTDB والتشكيلة التكتيكية.
  static const double formationBlend = 0.14;
  static const double orbAnchorYOffset = 0.62;

  static const Duration emphasisMaxDuration = Duration(milliseconds: 240);

  static const double anchorRadialAlpha = 0.28;
  static const double anchorShadowAlpha = 0.45;
  static const double anchorShadowBlur = 8;
  static const Offset anchorShadowOffset = Offset(0, 4);

  static const double benchRailHeightFrac = 0.15;
  static const double benchRailHorizontalPad = 0.04;
  static const double benchGlassAlpha = 0.55;
  static const double benchBorderAlpha = 0.14;

  static const int starterCount = 11;
  static const int forwardSlotStart = 8;
}
