import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_visual_density.dart';

/// توحيد معاملات الأسطح — كروت، قضبان، عداد، sheets.
class BroadcastSurfaceHarmony {
  const BroadcastSurfaceHarmony({
    required this.glassAlpha,
    required this.borderOpacity,
    required this.cardFrameOpacity,
    required this.countdownBackdropAlpha,
    required this.sheetMaterialAlpha,
  });

  final double glassAlpha;
  final double borderOpacity;
  final double cardFrameOpacity;
  final double countdownBackdropAlpha;
  final double sheetMaterialAlpha;

  static BroadcastSurfaceHarmony fromDensity(BroadcastDensityTune density) {
    return BroadcastSurfaceHarmony(
      glassAlpha: (0.92 * density.overlayDominance).clamp(0.82, 0.96),
      borderOpacity: (0.16 * density.cardProminence).clamp(0.12, 0.22),
      cardFrameOpacity: density.cardProminence.clamp(0.92, 1.05),
      countdownBackdropAlpha: (0.78 * density.textDensity).clamp(0.72, 0.88),
      sheetMaterialAlpha: (0.94 * density.overlayDominance).clamp(0.88, 0.96),
    );
  }
}
