import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';

/// مقاييس اقتصاد الوسائط — debug/profile.
class MediaEconomicsReport {
  MediaEconomicsReport._();

  static final MediaEconomicsReport instance = MediaEconomicsReport._();

  int thumbnailLoads = 0;
  int fullPromotions = 0;
  int skippedPromotions = 0;
  int preloadSuppressed = 0;
  int duplicatePromotionBlocked = 0;
  int totalEstimatedPayloadKb = 0;

  void recordThumbnail({int estimatedKb = 24}) {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) return;
    thumbnailLoads++;
    totalEstimatedPayloadKb += estimatedKb;
  }

  void recordUpgrade({int estimatedKb = 180}) {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) return;
    fullPromotions++;
    totalEstimatedPayloadKb += estimatedKb;
  }

  void recordSkippedPromotion() => skippedPromotions++;
  void recordPreloadSuppressed() => preloadSuppressed++;
  void recordDuplicateBlocked() => duplicatePromotionBlocked++;

  double get upgradeRate =>
      thumbnailLoads == 0 ? 0 : fullPromotions / thumbnailLoads;

  Map<String, dynamic> snapshot() {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) {
      return const {'enabled': false};
    }
    return {
      'enabled': true,
      'thumbnailLoads': thumbnailLoads,
      'fullPromotions': fullPromotions,
      'upgradeRate': upgradeRate,
      'skippedPromotions': skippedPromotions,
      'preloadSuppressed': preloadSuppressed,
      'duplicatePromotionBlocked': duplicatePromotionBlocked,
      'avgCardPayloadKb': thumbnailLoads == 0
          ? 0
          : totalEstimatedPayloadKb / (thumbnailLoads + fullPromotions),
    };
  }

  @visibleForTesting
  void reset() {
    thumbnailLoads = 0;
    fullPromotions = 0;
    skippedPromotions = 0;
    preloadSuppressed = 0;
    duplicatePromotionBlocked = 0;
    totalEstimatedPayloadKb = 0;
  }
}
