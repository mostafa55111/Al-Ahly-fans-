/// حدود الحركة السينمائية — premium، بطيئة، غير مبالغ فيها.
abstract final class CinematicMotionTokens {
  static const Duration maxTransition = Duration(milliseconds: 240);
  static const Duration breathHalfCycle = Duration(milliseconds: 240);
  static const Duration breathFullCycle = Duration(milliseconds: 4800);

  static const double breathScaleMin = 1.0;
  static const double breathScaleMax = 1.015;
  static const double breathOpacityMin = 0.96;
  static const double breathOpacityMax = 1.0;

  static const double transitionScaleIn = 0.985;
  static const double transitionScaleOut = 0.98;

  static const double maxAtmosphereStackOpacity = 0.72;
  static const int maxOpacityLayers = 3;
}
