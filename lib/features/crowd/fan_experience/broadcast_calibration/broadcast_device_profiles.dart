import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/device_pressure_classifier.dart';

/// ملف جهاز للمعايرة — بدون تغيير البنية.
enum BroadcastDeviceProfile {
  compactPhone,
  tallPhone,
  tablet,
  lowEndGpu,
}

abstract final class BroadcastDeviceProfiles {
  static BroadcastDeviceProfile resolve(Size size) {
    final shortest = size.shortestSide;
    final longest = size.longestSide;

    if (DevicePressureClassifier.instance.currentTier ==
        DevicePressureTier.lowEnd) {
      return BroadcastDeviceProfile.lowEndGpu;
    }
    if (shortest >= 600 || longest >= 900) {
      return BroadcastDeviceProfile.tablet;
    }
    if (shortest < 360) {
      return BroadcastDeviceProfile.compactPhone;
    }
    return BroadcastDeviceProfile.tallPhone;
  }

  static double spacingMul(BroadcastDeviceProfile p) => switch (p) {
        BroadcastDeviceProfile.compactPhone => 0.94,
        BroadcastDeviceProfile.tallPhone => 1.0,
        BroadcastDeviceProfile.tablet => 1.05,
        BroadcastDeviceProfile.lowEndGpu => 0.92,
      };

  static double fxMul(BroadcastDeviceProfile p) => switch (p) {
        BroadcastDeviceProfile.lowEndGpu => 0.72,
        BroadcastDeviceProfile.compactPhone => 0.88,
        _ => 1.0,
      };

  static double motionMul(BroadcastDeviceProfile p) => switch (p) {
        BroadcastDeviceProfile.lowEndGpu => 0.85,
        _ => 1.0,
      };
}
