import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_device_profiles.dart';

/// مصفوفة قراءة — تباين فوري في كل ظروف الإضاءة.
class BroadcastReadabilityMatrix {
  const BroadcastReadabilityMatrix({
    required this.textContrastMul,
    required this.scrimDarknessMul,
    required this.edgeHighlightMul,
    required this.overlayDarknessMul,
    required this.sunlightBoost,
  });

  final double textContrastMul;
  final double scrimDarknessMul;
  final double edgeHighlightMul;
  final double overlayDarknessMul;
  final double sunlightBoost;

  static BroadcastReadabilityMatrix forDevice(BroadcastDeviceProfile device) {
    return switch (device) {
      BroadcastDeviceProfile.compactPhone => const BroadcastReadabilityMatrix(
          textContrastMul: 1.06,
          scrimDarknessMul: 1.08,
          edgeHighlightMul: 0.92,
          overlayDarknessMul: 1.05,
          sunlightBoost: 1.04,
        ),
      BroadcastDeviceProfile.lowEndGpu => const BroadcastReadabilityMatrix(
          textContrastMul: 1.04,
          scrimDarknessMul: 1.06,
          edgeHighlightMul: 0.88,
          overlayDarknessMul: 1.02,
          sunlightBoost: 1.02,
        ),
      BroadcastDeviceProfile.tablet => const BroadcastReadabilityMatrix(
          textContrastMul: 1.0,
          scrimDarknessMul: 1.0,
          edgeHighlightMul: 1.0,
          overlayDarknessMul: 1.0,
          sunlightBoost: 1.0,
        ),
      _ => const BroadcastReadabilityMatrix(
          textContrastMul: 1.02,
          scrimDarknessMul: 1.04,
          edgeHighlightMul: 0.95,
          overlayDarknessMul: 1.03,
          sunlightBoost: 1.02,
        ),
    };
  }

  double calibratedScrim(double base) =>
      (base * scrimDarknessMul).clamp(0.72, 0.94);

  double calibratedTextOpacity(double base) =>
      (base * textContrastMul).clamp(0.88, 1.0);
}
