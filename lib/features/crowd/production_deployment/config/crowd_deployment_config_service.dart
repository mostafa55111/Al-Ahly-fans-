import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';

/// Remote Config لمرحلة الإطلاق (قنوات، طوارئ، عزل بيئات).
class CrowdDeploymentConfigService {
  CrowdDeploymentConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remote = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remote;

  static const _defaults = <String, dynamic>{
    'crowd_env_lock': '',
    'release_channel': '',
    'crowd_emergency_local_authority': false,
    'crowd_disable_heavy_preload': false,
    'crowd_disable_nesr_overlay': false,
    'crowd_pause_background_hydration': false,
    'crowd_reduce_thumbnail_promotion': false,
    'crowd_staging_owner_emails': '',
    'crowd_feature_freeze': false,
    'crowd_runtime_lock': false,
    'crowd_disable_experimental': true,
    'crowd_soft_launch_enabled': false,
    'crowd_rollout_percentage': 0,
    'crowd_public_rollout_enabled': false,
    'crowd_emergency_rollout_stop': false,
    'crowd_beta_channel_only': true,
    'crowd_soft_launch_freeze': true,
  };

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> bootstrap() async {
    try {
      await _remote.setDefaults(_defaults);
      final lock = _remote.getString('crowd_env_lock').trim().toLowerCase();
      if (lock.isNotEmpty &&
          (lock == 'staging' || lock == 'production' || lock == 'development')) {
        await CrowdEnvironmentResolver.bootstrap(overrideWire: lock);
      }
      _ready = true;
      debugPrint('[CrowdDeploymentConfig] ready envLock=$lock');
    } catch (e, st) {
      debugPrint('[CrowdDeploymentConfig] failed: $e\n$st');
      _ready = true;
    }
  }

  String get stagingOwnerEmailsCsv =>
      _remote.getString('crowd_staging_owner_emails');

  void validateProductionSanity() {
    if (!CrowdEnvironmentResolver.isBootstrapped) return;
    final env = CrowdEnvironmentResolver.current;
    if (!env.isProductionData) return;

    final lock = _remote.getString('crowd_env_lock');
    if (lock == 'development' || lock == 'staging') {
      throw StateError(
        'Remote Config crowd_env_lock=$lock conflicts with production build',
      );
    }
  }
}
