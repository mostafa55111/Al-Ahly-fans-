import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/socket_pressure_guard.dart';

enum DevicePressureTier {
  lowEnd,
  medium,
  highEnd,
}

/// تصنيف ضغط الجهاز — يضبط الوسائط والـ hydration بدون تغيير UX.
class DevicePressureClassifier {
  DevicePressureClassifier._();

  static final DevicePressureClassifier instance = DevicePressureClassifier._();

  DevicePressureTier _tier = DevicePressureTier.medium;
  int _frameJankSignals = 0;

  DevicePressureTier get currentTier => _tier;

  bool get suppressHeavyMedia => _tier != DevicePressureTier.highEnd;
  bool get reducePreloadConcurrency => _tier == DevicePressureTier.lowEnd;
  bool get lightweightHydration => _tier == DevicePressureTier.lowEnd;

  void refresh({
    bool appBackgrounded = false,
    int? imageCacheFillPercent,
  }) {
    if (appBackgrounded || SocketPressureGuard.instance.isAppBackgrounded) {
      _tier = DevicePressureTier.lowEnd;
      return;
    }
    if (FirebaseCostGuard.instance.level == CostPressureLevel.critical ||
        FirebaseCostGuard.instance.level == CostPressureLevel.high) {
      _tier = DevicePressureTier.lowEnd;
      return;
    }
    if (imageCacheFillPercent != null && imageCacheFillPercent >= 85) {
      _tier = DevicePressureTier.lowEnd;
      return;
    }
    if (_frameJankSignals > 6) {
      _tier = DevicePressureTier.medium;
      return;
    }
    if (FirebaseCostGuard.instance.level == CostPressureLevel.elevated) {
      _tier = DevicePressureTier.medium;
      return;
    }
    _tier = DevicePressureTier.highEnd;
  }

  void recordFrameJank() {
    if (!kDebugMode) return;
    _frameJankSignals++;
    if (_frameJankSignals > 12) _frameJankSignals = 12;
  }

  @visibleForTesting
  void reset() {
    _tier = DevicePressureTier.medium;
    _frameJankSignals = 0;
  }
}
