import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';

/// توازن حرارة اللون — أهلي دافئ / زمالك فضي أنيق.
class BroadcastColorBalance {
  const BroadcastColorBalance({
    required this.warmthMul,
    required this.prestigeSaturation,
    required this.ambientCoolness,
    required this.scrimNeutral,
  });

  final double warmthMul;
  final double prestigeSaturation;
  final double ambientCoolness;
  final Color scrimNeutral;

  static BroadcastColorBalance current() {
    final isAhly = FanAppIdentity.registryAppId == 'ahly';
    if (isAhly) {
      return const BroadcastColorBalance(
        warmthMul: 0.92,
        prestigeSaturation: 0.88,
        ambientCoolness: 0.15,
        scrimNeutral: Color(0xFF140808),
      );
    }
    return const BroadcastColorBalance(
      warmthMul: 0.78,
      prestigeSaturation: 0.72,
      ambientCoolness: 0.35,
      scrimNeutral: Color(0xFF101218),
    );
  }

  Color tunePrimary(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation((hsl.saturation * prestigeSaturation).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * (0.98 + warmthMul * 0.02)).clamp(0.0, 1.0))
        .toColor();
  }

  Color tuneHighlight(Color c) {
    if (FanAppIdentity.registryAppId == 'zamalek') {
      return Color.lerp(c, Colors.white, 0.08)!;
    }
    return Color.lerp(c, const Color(0xFFFFE082), 0.06)!;
  }
}
