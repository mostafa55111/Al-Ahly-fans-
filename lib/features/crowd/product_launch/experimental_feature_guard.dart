import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/legacy/legacy_crowd_feature_flags.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_contract.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';

/// ميزات تجريبية/قديمة — لا تُحمّل في release production.
enum ExperimentalFeatureId {
  legacyEagleVoting,
  legacyMatchCenter,
  legacyCrowdStreams,
  publicArenaMotmPreview,
  productionOpsSandbox,
  syntheticLoad,
  reconnectStormSim,
  debugRuntimeHooks,
}

class ExperimentalFeatureGuard {
  ExperimentalFeatureGuard._();

  static bool isExperimental(ExperimentalFeatureId id) => switch (id) {
        ExperimentalFeatureId.legacyEagleVoting =>
          LegacyCrowdFeatureFlags.enableLegacyVoting,
        ExperimentalFeatureId.legacyMatchCenter =>
          LegacyCrowdFeatureFlags.enableLegacyRoutes,
        ExperimentalFeatureId.legacyCrowdStreams =>
          LegacyCrowdFeatureFlags.enableLegacyStreams,
        ExperimentalFeatureId.publicArenaMotmPreview => true,
        ExperimentalFeatureId.productionOpsSandbox => true,
        ExperimentalFeatureId.syntheticLoad => true,
        ExperimentalFeatureId.reconnectStormSim => true,
        ExperimentalFeatureId.debugRuntimeHooks => true,
      };

  /// هل يُسمح بتحميل الميزة في runtime الحالي؟
  static bool allowLoad(ExperimentalFeatureId id) {
    if (!isExperimental(id)) return true;
    if (ReleaseModeGuard.isStrictRelease) return false;
    if (ProductionFeatureFreeze.instance.disableExperimental) return false;
    if (ProductionFeatureFreeze.instance.runtimeLock) return false;
    return kDebugMode;
  }

  static void assertNotLoadedInRelease(ExperimentalFeatureId id) {
    if (!allowLoad(id)) {
      LaunchContract.warnUnsupported(
        'experimental_${id.name}',
        reason: 'experimental_blocked',
      );
    }
  }
}
