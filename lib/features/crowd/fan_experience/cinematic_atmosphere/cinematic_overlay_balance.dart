import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_match_state_palette.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_motion_tokens.dart';

/// موازنة الشفافية — منع غسيل الكروت أو تراكم التوهج.
abstract final class CinematicOverlayBalance {
  static double depthLayerOpacity(CinematicMatchPalette palette) {
    final raw = palette.ambientOpacity + palette.vignetteEdge * 0.18;
    return raw.clamp(0.12, CinematicMotionTokens.maxAtmosphereStackOpacity);
  }

  static double fieldDimOpacity(CinematicMatchPalette palette) =>
      palette.fieldDarkness.clamp(0.08, 0.32);

  static double centerGlowOpacity(CinematicMatchPalette palette) =>
      (palette.glowWarmth * 0.14).clamp(0.04, 0.18);

  static double cardDominanceGuard(double proposedCardOpacity) =>
      proposedCardOpacity.clamp(0.58, 1.0);

  static double atmosphereFxOpacity(
    CinematicMatchPalette palette,
    double policyMultiplier,
  ) {
    return (palette.ambientOpacity * policyMultiplier)
        .clamp(0.0, CinematicMotionTokens.maxAtmosphereStackOpacity);
  }
}
