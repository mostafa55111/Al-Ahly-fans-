import 'package:flutter/foundation.dart';

class MediaPressureReport {
  MediaPressureReport._();

  static final MediaPressureReport instance = MediaPressureReport._();

  int thumbnailLoads = 0;
  int fullPromotions = 0;
  int promotionSkipped = 0;
  int stadiumOpens = 0;
  int hofTimelineLoads = 0;
  int rapidScrollBursts = 0;
  int decodeSlowFrames = 0;
  double peakDecodeMs = 0;
  int cacheChurnEvents = 0;
  int memoryPressureSignals = 0;

  void recordThumbnail() => _inc(() => thumbnailLoads++);
  void recordFullPromotion() => _inc(() => fullPromotions++);
  void recordPromotionSkipped() => _inc(() => promotionSkipped++);
  void recordStadiumOpen() => _inc(() => stadiumOpens++);
  void recordHofTimeline() => _inc(() => hofTimelineLoads++);
  void recordRapidScroll() => _inc(() => rapidScrollBursts++);
  void recordDecodeMs(double ms) {
    _inc(() {
      if (ms > peakDecodeMs) peakDecodeMs = ms;
      if (ms > 48) decodeSlowFrames++;
    });
  }

  void recordCacheChurn() => _inc(() => cacheChurnEvents++);
  void recordMemoryPressure() => _inc(() => memoryPressureSignals++);

  Map<String, dynamic> snapshot() {
    if (!kDebugMode) return const {};
    return {
      'thumbnailLoads': thumbnailLoads,
      'fullPromotions': fullPromotions,
      'promotionSkipped': promotionSkipped,
      'stadiumOpens': stadiumOpens,
      'hofTimelineLoads': hofTimelineLoads,
      'rapidScrollBursts': rapidScrollBursts,
      'decodeSlowFrames': decodeSlowFrames,
      'peakDecodeMs': peakDecodeMs,
      'cacheChurnEvents': cacheChurnEvents,
      'memoryPressureSignals': memoryPressureSignals,
    };
  }

  void _inc(void Function() fn) {
    if (!kDebugMode) return;
    fn();
  }

  @visibleForTesting
  void reset() {
    thumbnailLoads = 0;
    fullPromotions = 0;
    promotionSkipped = 0;
    stadiumOpens = 0;
    hofTimelineLoads = 0;
    rapidScrollBursts = 0;
    decodeSlowFrames = 0;
    peakDecodeMs = 0;
    cacheChurnEvents = 0;
    memoryPressureSignals = 0;
  }
}
