import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_focus_balance.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_readability_matrix.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_surface_harmony.dart';

/// طبقة الجودة النهائية — حواف نظيفة وإحساس مكلف.
class BroadcastFinishQuality {
  const BroadcastFinishQuality({
    required this.hierarchyConsistency,
    required this.edgeCleanliness,
    required this.premiumFeel,
    required this.visualNoiseCap,
    required this.sheenCap,
  });

  final double hierarchyConsistency;
  final double edgeCleanliness;
  final double premiumFeel;
  final double visualNoiseCap;
  final double sheenCap;

  static BroadcastFinishQuality compose({
    required BroadcastFocusBalance focus,
    required BroadcastReadabilityMatrix readability,
    required BroadcastSurfaceHarmony harmony,
  }) {
    return BroadcastFinishQuality(
      hierarchyConsistency: focus.competingHighlightReduction,
      edgeCleanliness: readability.edgeHighlightMul,
      premiumFeel: harmony.cardFrameOpacity,
      visualNoiseCap: (1.0 - focus.atmosphereWeight * 0.25).clamp(0.72, 1.0),
      sheenCap: (readability.edgeHighlightMul * harmony.borderOpacity * 4)
          .clamp(0.08, 0.2),
    );
  }

  double polish(double value) => value * premiumFeel.clamp(0.9, 1.05);
}
