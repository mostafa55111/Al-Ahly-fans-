import 'package:flutter/foundation.dart';

enum CostPressureLevel {
  normal,
  elevated,
  high,
  critical,
}

/// حارس تكلفة Firebase — قراءات/كتابات/مستمعين/استدعاءات.
class FirebaseCostGuard {
  FirebaseCostGuard._();

  static final FirebaseCostGuard instance = FirebaseCostGuard._();

  int rtdbReadsPerWindow = 0;
  int rtdbWritesPerWindow = 0;
  int activeListeners = 0;
  int cloudFunctionCalls = 0;
  int bandwidthSpikeEvents = 0;
  DateTime _windowStart = DateTime.now();

  CostPressureLevel _level = CostPressureLevel.normal;

  CostPressureLevel get level => _level;

  bool get shouldReduceHofPreload =>
      _level.index >= CostPressureLevel.elevated.index;

  bool get shouldDelayBackgroundHydration =>
      _level.index >= CostPressureLevel.high.index;

  bool get shouldReduceThumbnailPromotion =>
      _level.index >= CostPressureLevel.elevated.index;

  void recordRead({int count = 1}) => _bump(() => rtdbReadsPerWindow += count);
  void recordWrite({int count = 1}) =>
      _bump(() => rtdbWritesPerWindow += count);
  void recordListenerDelta(int delta) =>
      _bump(() => activeListeners = (activeListeners + delta).clamp(0, 9999));
  void recordCloudFunctionCall() => _bump(() => cloudFunctionCalls++);
  void recordBandwidthSpike() => _bump(() => bandwidthSpikeEvents++);

  void _bump(void Function() fn) {
    _maybeRollWindow();
    fn();
    _recomputeLevel();
  }

  void _maybeRollWindow() {
    final elapsed = DateTime.now().difference(_windowStart);
    if (elapsed.inSeconds < 10) return;
    rtdbReadsPerWindow = 0;
    rtdbWritesPerWindow = 0;
    cloudFunctionCalls = 0;
    bandwidthSpikeEvents = 0;
    _windowStart = DateTime.now();
  }

  void _recomputeLevel() {
    if (rtdbReadsPerWindow > 800 ||
        rtdbWritesPerWindow > 200 ||
        activeListeners > 48 ||
        cloudFunctionCalls > 40) {
      _level = CostPressureLevel.critical;
    } else if (rtdbReadsPerWindow > 400 ||
        activeListeners > 32 ||
        cloudFunctionCalls > 20) {
      _level = CostPressureLevel.high;
    } else if (rtdbReadsPerWindow > 180 || activeListeners > 20) {
      _level = CostPressureLevel.elevated;
    } else {
      _level = CostPressureLevel.normal;
    }
  }

  Map<String, dynamic> snapshot() {
    if (!kDebugMode) return const {};
    return {
      'level': _level.name,
      'rtdbReadsPerWindow': rtdbReadsPerWindow,
      'rtdbWritesPerWindow': rtdbWritesPerWindow,
      'activeListeners': activeListeners,
      'cloudFunctionCalls': cloudFunctionCalls,
      'bandwidthSpikeEvents': bandwidthSpikeEvents,
      'reduceHofPreload': shouldReduceHofPreload,
      'delayBackgroundHydration': shouldDelayBackgroundHydration,
      'reduceThumbnailPromotion': shouldReduceThumbnailPromotion,
    };
  }

  @visibleForTesting
  void reset() {
    rtdbReadsPerWindow = 0;
    rtdbWritesPerWindow = 0;
    activeListeners = 0;
    cloudFunctionCalls = 0;
    bandwidthSpikeEvents = 0;
    _level = CostPressureLevel.normal;
    _windowStart = DateTime.now();
  }
}
