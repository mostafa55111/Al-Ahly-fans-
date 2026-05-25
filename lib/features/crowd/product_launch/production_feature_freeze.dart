import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_contract.dart';

/// تجميد الميزات عبر Remote Config — يمنع feature creep بعد الإطلاق.
class ProductionFeatureFreeze {
  ProductionFeatureFreeze._();

  static final ProductionFeatureFreeze instance = ProductionFeatureFreeze._();

  bool _ready = false;
  bool featureFreeze = false;
  bool runtimeLock = false;
  bool disableExperimental = true;

  bool get isReady => _ready;

  Future<void> bootstrap({FirebaseRemoteConfig? remote}) async {
    try {
      final rc = remote ?? FirebaseRemoteConfig.instance;
      await rc.setDefaults({
        'crowd_feature_freeze': false,
        'crowd_runtime_lock': false,
        'crowd_disable_experimental': true,
      });
      featureFreeze = rc.getBool('crowd_feature_freeze');
      runtimeLock = rc.getBool('crowd_runtime_lock');
      disableExperimental = rc.getBool('crowd_disable_experimental');
      _ready = true;
      if (featureFreeze || runtimeLock) {
        debugPrint(
          '[ProductionFeatureFreeze] active freeze=$featureFreeze lock=$runtimeLock',
        );
      }
    } catch (e, st) {
      debugPrint('[ProductionFeatureFreeze] bootstrap: $e\n$st');
      _ready = true;
    }
  }

  bool blocksNewCapability(String featureKey) {
    if (!featureFreeze && !runtimeLock) return false;
    LaunchContract.warnUnsupported(featureKey, reason: 'feature_freeze');
    return true;
  }

  @visibleForTesting
  void resetForTests({
    bool freeze = false,
    bool lock = false,
    bool disableExp = true,
  }) {
    featureFreeze = freeze;
    runtimeLock = lock;
    disableExperimental = disableExp;
    _ready = true;
  }
}
