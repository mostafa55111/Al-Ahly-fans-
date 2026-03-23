import 'package:flutter/material.dart';

/// ألوان ومسافات موحّدة (TikTok / Instagram dark) لشاشة الريلز والعناصر المرتبطة.
abstract final class ReelsFeedTheme {
  static const Color rose = Color(0xFFFE2C55);
  static const Color roseMuted = Color(0xFFE1306C);
  static const Color yellowBookmark = Color(0xFFFFE135);
  static const Color sheetDark = Color(0xFF121212);
  static const Color sheetDarker = Color(0xFF0F0F0F);
  static const Color overlayBlurTint = Color(0x47000000);

  /// شريط علوي / جوانب
  static const double topBarHeight = 56;
  static const double topBarHorizontalInset = 12;
  static const double sideActionsRightInset = 12;
  static const double captionLeftInset = 16;
  static const double captionRightInset = 88;

  /// تباعد بين أزرار العمود الجانبي (تيك توك)
  static const double sideActionGap = 18;

  static const TextStyle topTabSelected = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 18,
    letterSpacing: 0.1,
    shadows: [Shadow(blurRadius: 10, color: Colors.black87)],
  );

  static TextStyle topTabUnselected = TextStyle(
    color: Colors.white.withValues(alpha: 0.65),
    fontWeight: FontWeight.w700,
    fontSize: 17,
    letterSpacing: 0.1,
    shadows: const [Shadow(blurRadius: 10, color: Colors.black54)],
  );

  static TextStyle sideActionCount = const TextStyle(
    color: Colors.white,
    fontSize: 12.5,
    fontWeight: FontWeight.w800,
    height: 1.2,
    shadows: [
      Shadow(blurRadius: 12, color: Colors.black),
      Shadow(blurRadius: 4, color: Colors.black87),
    ],
  );

  static const TextStyle usernameStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 16.5,
    shadows: [
      Shadow(blurRadius: 12, color: Colors.black),
      Shadow(blurRadius: 4, color: Colors.black87),
    ],
  );

  static const TextStyle captionStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 14.5,
    height: 1.35,
    shadows: [
      Shadow(blurRadius: 10, color: Colors.black),
    ],
  );
}
