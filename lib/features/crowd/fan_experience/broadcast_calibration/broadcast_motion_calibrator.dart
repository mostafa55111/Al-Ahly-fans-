import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_device_profiles.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_motion_tokens.dart';

/// معايرة حركة شبه غير مرئية — مكلفة ومقصودة.
class BroadcastMotionTune {
  const BroadcastMotionTune({
    required this.fadeMs,
    required this.scaleIn,
    required this.pressMs,
    required this.breathCycleMs,
    required this.interactionSoftness,
  });

  final int fadeMs;
  final double scaleIn;
  final int pressMs;
  final int breathCycleMs;
  final double interactionSoftness;

  static BroadcastMotionTune forDevice(BroadcastDeviceProfile device) {
    final mul = BroadcastDeviceProfiles.motionMul(device);
    final fade = (CinematicMotionTokens.maxTransition.inMilliseconds * mul)
        .round()
        .clamp(180, 240);
    return BroadcastMotionTune(
      fadeMs: fade,
      scaleIn: CinematicMotionTokens.transitionScaleIn +
          (1.0 - mul) * 0.004,
      pressMs: (140 * mul).round().clamp(120, 160),
      breathCycleMs: (CinematicMotionTokens.breathFullCycle.inMilliseconds * mul)
          .round()
          .clamp(4200, 5200),
      interactionSoftness: mul.clamp(0.82, 1.0),
    );
  }

  Duration fadeDuration() => Duration(milliseconds: fadeMs);
  Duration pressDuration() => Duration(milliseconds: pressMs);
}
