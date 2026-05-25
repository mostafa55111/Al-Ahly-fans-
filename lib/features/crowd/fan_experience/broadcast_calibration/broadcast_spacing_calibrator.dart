import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_device_profiles.dart';

/// معايرة إيقاع المسافات على الشاشة.
class BroadcastSpacingTune {
  const BroadcastSpacingTune({
    required this.cardScaleMul,
    required this.horizontalGapMul,
    required this.verticalGapMul,
    required this.edgeMarginMul,
    required this.benchGapMul,
    required this.topHudPadMul,
    required this.bottomRailBreathingMul,
    required this.formationSpreadMul,
  });

  final double cardScaleMul;
  final double horizontalGapMul;
  final double verticalGapMul;
  final double edgeMarginMul;
  final double benchGapMul;
  final double topHudPadMul;
  final double bottomRailBreathingMul;
  final double formationSpreadMul;

  static BroadcastSpacingTune forDevice(BroadcastDeviceProfile device) {
    final base = BroadcastDeviceProfiles.spacingMul(device);
    return BroadcastSpacingTune(
      cardScaleMul: base,
      horizontalGapMul: base * 1.02,
      verticalGapMul: base * 0.98,
      edgeMarginMul: device == BroadcastDeviceProfile.compactPhone ? 1.06 : 1.0,
      benchGapMul: base,
      topHudPadMul: device == BroadcastDeviceProfile.compactPhone ? 1.04 : 1.0,
      bottomRailBreathingMul:
          device == BroadcastDeviceProfile.tallPhone ? 1.05 : 1.0,
      formationSpreadMul: device == BroadcastDeviceProfile.tablet ? 1.03 : 1.0,
    );
  }

  Size adjustViewport(Size size) {
    return Size(size.width, size.height);
  }
}
