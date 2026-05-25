import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_execution_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';

/// تبديلات طوارئ عبر Remote Config — بدون تحديث تطبيق.
class SafeRollbackCoordinator {
  SafeRollbackCoordinator({FirebaseRemoteConfig? remoteConfig})
      : _remote = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remote;

  bool forceLocalAuthority = false;
  bool disableHeavyPreload = false;
  bool disableNesrOverlay = false;
  bool pauseBackgroundHydration = false;
  bool reduceThumbnailPromotion = false;

  Future<void> bootstrap() async {
    forceLocalAuthority = _remote.getBool('crowd_emergency_local_authority');
    disableHeavyPreload = _remote.getBool('crowd_disable_heavy_preload');
    disableNesrOverlay = _remote.getBool('crowd_disable_nesr_overlay');
    pauseBackgroundHydration =
        _remote.getBool('crowd_pause_background_hydration');
    reduceThumbnailPromotion =
        _remote.getBool('crowd_reduce_thumbnail_promotion');

    if (forceLocalAuthority && getIt.isRegistered<AuthorityOrchestrator>()) {
      getIt<AuthorityOrchestrator>().setMode(AuthorityExecutionMode.local);
      debugPrint('[SafeRollback] authority forced LOCAL');
    }

    if (reduceThumbnailPromotion) {
      FirebaseCostGuard.instance.recordBandwidthSpike();
    }

    debugPrint(
      '[SafeRollback] local=$forceLocalAuthority heavyOff=$disableHeavyPreload '
      'hydrationPause=$pauseBackgroundHydration thumb=$reduceThumbnailPromotion',
    );
  }

  bool get shouldSkipHeavyPreload =>
      disableHeavyPreload || pauseBackgroundHydration;

  bool get shouldSkipNesrOverlay => disableNesrOverlay;

  bool get shouldThrottleMedia =>
      reduceThumbnailPromotion ||
      FirebaseCostGuard.instance.shouldReduceThumbnailPromotion;

  Map<String, dynamic> snapshot() => {
        'forceLocalAuthority': forceLocalAuthority,
        'disableHeavyPreload': disableHeavyPreload,
        'disableNesrOverlay': disableNesrOverlay,
        'pauseBackgroundHydration': pauseBackgroundHydration,
        'reduceThumbnailPromotion': reduceThumbnailPromotion,
      };
}
