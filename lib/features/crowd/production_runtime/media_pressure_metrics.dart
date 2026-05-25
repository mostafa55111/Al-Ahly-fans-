import 'package:flutter/foundation.dart';

/// ضغط وسائط الكروت.
class MediaPressureMetrics {
  MediaPressureMetrics._();

  static final MediaPressureMetrics instance = MediaPressureMetrics._();

  int thumbnailLoads = 0;
  int fullPromotions = 0;
  int promotionSkippedPressure = 0;
  int validationFailures = 0;

  void recordThumbnailLoad() {
    if (!kDebugMode) return;
    thumbnailLoads++;
  }

  void recordFullPromotion() {
    if (!kDebugMode) return;
    fullPromotions++;
  }

  void recordPromotionSkipped() {
    if (!kDebugMode) return;
    promotionSkippedPressure++;
  }

  void recordValidationFailure() {
    if (!kDebugMode) return;
    validationFailures++;
  }
}
