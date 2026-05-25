import 'package:flutter/material.dart';

/// ثوابت تشطيب البث — لا أرقام سحرية في الودجتات.
abstract final class PremiumCardBroadcastTokens {
  static const double cardRadius = 10;
  static const double innerRadius = 9;

  static const double borderWidthNormal = 1.0;
  static const double borderWidthActive = 1.4;
  static const double borderWidthSelected = 2.0;
  static const double borderWidthWinner = 2.2;

  static const double borderOpacityNormal = 0.22;
  static const double borderOpacityActive = 0.38;
  static const double borderOpacitySelected = 0.72;
  static const double borderOpacityWinner = 0.85;

  static const double sheenIntensityNormal = 0.08;
  static const double sheenIntensitySelected = 0.14;
  static const double sheenIntensityWinner = 0.18;

  static const double shadowBlur = 8;
  static const double shadowAlpha = 0.42;
  static const Offset shadowOffset = Offset(0, 4);

  static const double fieldLiftAlpha = 0.12;
  static const double scrimBottomAlpha = 0.82;
  static const double scrimBoostForArt = 0.08;

  static const double nameFontScale = 9.5;
  static const double positionFontScale = 8;
  static const double ratingFontScale = 10;
  static const double nameLetterSpacing = 0.35;

  static const double glassMaterialAlpha = 0.94;
  static const double glassBorderAlpha = 0.14;
  static const double glassBlurSigma = 8;

  static const Duration pressDuration = Duration(milliseconds: 140);
  static const Duration releaseDuration = Duration(milliseconds: 160);
  static const double pressScale = 0.97;
  static const double pressOpacity = 0.92;

  static const double winnerScale = 1.04;
  static const double substituteScale = 0.96;
  static const double benchQuietOpacity = 0.88;
}
