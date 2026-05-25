import 'package:flutter/foundation.dart';

class EnduranceRuntimeReport {
  EnduranceRuntimeReport._();

  static final EnduranceRuntimeReport instance = EnduranceRuntimeReport._();

  Duration simulatedUptime = Duration.zero;
  int listenerLeaksDetected = 0;
  int timerLeaksDetected = 0;
  int queueDepthPeak = 0;
  int memorySamples = 0;
  double memoryGrowthMb = 0;
  bool cacheStabilized = true;

  void recordHourTick(int hours) {
    _inc(() => simulatedUptime = Duration(hours: hours));
  }

  void recordQueueDepth(int depth) {
    _inc(() {
      if (depth > queueDepthPeak) queueDepthPeak = depth;
    });
  }

  void recordMemorySample(double growthMb) {
    _inc(() {
      memorySamples++;
      memoryGrowthMb = growthMb;
      if (growthMb > 80) cacheStabilized = false;
    });
  }

  void recordListenerLeak() => _inc(() => listenerLeaksDetected++);
  void recordTimerLeak() => _inc(() => timerLeaksDetected++);

  Map<String, dynamic> snapshot() {
    if (!kDebugMode) return const {};
    return {
      'simulatedUptimeHours': simulatedUptime.inHours,
      'listenerLeaksDetected': listenerLeaksDetected,
      'timerLeaksDetected': timerLeaksDetected,
      'queueDepthPeak': queueDepthPeak,
      'memoryGrowthMb': memoryGrowthMb,
      'cacheStabilized': cacheStabilized,
    };
  }

  void _inc(void Function() fn) {
    if (!kDebugMode) return;
    fn();
  }

  @visibleForTesting
  void reset() {
    simulatedUptime = Duration.zero;
    listenerLeaksDetected = 0;
    timerLeaksDetected = 0;
    queueDepthPeak = 0;
    memorySamples = 0;
    memoryGrowthMb = 0;
    cacheStabilized = true;
  }
}
