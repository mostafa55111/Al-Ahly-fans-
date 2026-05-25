import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_contract.dart';

/// طبقات مجمّدة — تعديلات دقيقة فقط (±8%).
enum LaunchFreezeLayer {
  stadiumStructure,
  cinematicHierarchy,
  cardHierarchy,
  typographySystem,
  motionPhilosophy,
  broadcastCalibration,
}

/// حارس تجميد ما بعد Phase 6 — يمنع إعادة تصميم كاملة.
class LaunchFreezeGuard {
  LaunchFreezeGuard._();

  static final LaunchFreezeGuard instance = LaunchFreezeGuard._();

  static const double maxTinyTuningDelta = 0.08;

  bool _active = false;

  bool get isActive => _active || kReleaseMode;

  void activate() {
    _active = true;
    if (kDebugMode) {
      debugPrint('[LaunchFreezeGuard] fan experience layers frozen');
    }
  }

  @visibleForTesting
  void resetForTests() => _active = false;

  bool allowsRelativeChange(LaunchFreezeLayer layer, double relativeDelta) {
    if (!isActive) return true;
    return relativeDelta.abs() <= maxTinyTuningDelta;
  }

  void assertTinyTuningOnly(
    LaunchFreezeLayer layer, {
    required double relativeDelta,
    String? context,
  }) {
    if (!isActive) return;
    if (allowsRelativeChange(layer, relativeDelta)) return;
    LaunchContract.warnUnsupported(
      'freeze_${layer.name}',
      reason: 'delta_${relativeDelta.toStringAsFixed(3)}_exceeds_cap'
          '${context != null ? ':$context' : ''}',
    );
  }
}
