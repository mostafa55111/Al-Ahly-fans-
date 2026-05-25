import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_contract.dart';

/// تعديلات مسموحة بعد تجميد تجربة المشجع.
enum FanExperienceModificationClass {
  bugFix,
  readabilityFix,
  spacingFix,
  deviceCompatibilityFix,
  prohibited,
}

/// توسعات ممنوعة بعد الإطلاق.
enum FanExperienceExpansionKind {
  extraOverlay,
  extraTab,
  experimentalFx,
  newMotionSystem,
  extraStatistics,
  liveLeaderboard,
  visualExperiment,
}

/// تجميد سطح Fan Experience — لا توسع بصري جديد.
class ProductionSurfaceLock {
  ProductionSurfaceLock._();

  static final ProductionSurfaceLock instance = ProductionSurfaceLock._();

  bool _fanExperienceLocked = false;

  bool get isFanExperienceLocked => _fanExperienceLocked || kReleaseMode;

  void activateFanExperienceLock() {
    _fanExperienceLocked = true;
    if (kDebugMode) {
      debugPrint('[ProductionSurfaceLock] fan experience LOCKED for launch');
    }
  }

  @visibleForTesting
  void resetForTests() => _fanExperienceLocked = false;

  bool allowModification(FanExperienceModificationClass kind) {
    if (kind == FanExperienceModificationClass.prohibited) return false;
    if (!isFanExperienceLocked) return true;
    return kind == FanExperienceModificationClass.bugFix ||
        kind == FanExperienceModificationClass.readabilityFix ||
        kind == FanExperienceModificationClass.spacingFix ||
        kind == FanExperienceModificationClass.deviceCompatibilityFix;
  }

  void guardExpansion(FanExperienceExpansionKind kind) {
    if (!isFanExperienceLocked) return;
    LaunchContract.warnUnsupported(
      'fan_expansion_${kind.name}',
      reason: 'fan_experience_surface_locked',
    );
  }

  void assertModificationAllowed(FanExperienceModificationClass kind) {
    if (!allowModification(kind)) {
      LaunchContract.warnUnsupported(
        'fan_mod_${kind.name}',
        reason: 'modification_not_on_allowlist',
      );
    }
  }
}
