import 'package:flutter/services.dart';

/// لمسات اختيارية — بدون صوت تلقائي.
class FanExperienceHaptics {
  FanExperienceHaptics._();

  static void voteTap() => HapticFeedback.lightImpact();

  static void voteConfirm() => HapticFeedback.mediumImpact();

  static void voteSuccess() => HapticFeedback.selectionClick();

  static void revealPulse() => HapticFeedback.heavyImpact();

  static void lockedTap() => HapticFeedback.selectionClick();
}
