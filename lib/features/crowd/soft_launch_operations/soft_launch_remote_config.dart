import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// مفاتيح Remote Config للإطلاق الناعم — افتراضيات آمنة / معطّلة.
abstract final class SoftLaunchRemoteConfigKeys {
  static const softLaunchEnabled = 'crowd_soft_launch_enabled';
  static const rolloutPercentage = 'crowd_rollout_percentage';
  static const publicRolloutEnabled = 'crowd_public_rollout_enabled';
  static const emergencyRolloutStop = 'crowd_emergency_rollout_stop';
  static const betaChannelOnly = 'crowd_beta_channel_only';
  static const softLaunchFreeze = 'crowd_soft_launch_freeze';

  static const defaults = <String, dynamic>{
    softLaunchEnabled: false,
    rolloutPercentage: 0,
    publicRolloutEnabled: false,
    emergencyRolloutStop: false,
    betaChannelOnly: true,
    softLaunchFreeze: true,
  };
}

/// واجهة قراءة إعدادات الإطلاق الناعم — للاختبار بدون Firebase.
abstract interface class SoftLaunchConfigReader {
  bool get softLaunchEnabled;
  int get rolloutPercentage;
  bool get publicRolloutEnabled;
  bool get emergencyRolloutStop;
  bool get betaChannelOnly;
  bool get softLaunchFreeze;
}

/// قيم ثابتة للاختبارات.
@visibleForTesting
class InMemorySoftLaunchConfig implements SoftLaunchConfigReader {
  const InMemorySoftLaunchConfig({
    this.softLaunchEnabled = false,
    this.rolloutPercentage = 0,
    this.publicRolloutEnabled = false,
    this.emergencyRolloutStop = false,
    this.betaChannelOnly = true,
    this.softLaunchFreeze = true,
  });

  @override
  final bool softLaunchEnabled;
  @override
  final int rolloutPercentage;
  @override
  final bool publicRolloutEnabled;
  @override
  final bool emergencyRolloutStop;
  @override
  final bool betaChannelOnly;
  @override
  final bool softLaunchFreeze;
}

/// قارئ إعدادات الإطلاق الناعم من RC.
class SoftLaunchRemoteConfig implements SoftLaunchConfigReader {
  SoftLaunchRemoteConfig({FirebaseRemoteConfig? remote})
      : _remote = remote ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remote;

  static Future<void> installDefaults({FirebaseRemoteConfig? remote}) async {
    try {
      final rc = remote ?? FirebaseRemoteConfig.instance;
      await rc.setDefaults(SoftLaunchRemoteConfigKeys.defaults);
    } catch (e, st) {
      debugPrint('[SoftLaunchRemoteConfig] defaults: $e\n$st');
    }
  }

  @override
  bool get softLaunchEnabled => _remote.getBool(
        SoftLaunchRemoteConfigKeys.softLaunchEnabled,
      );

  @override
  int get rolloutPercentage {
    final v = _remote.getInt(SoftLaunchRemoteConfigKeys.rolloutPercentage);
    return _clampPercentage(v);
  }

  @override
  bool get publicRolloutEnabled => _remote.getBool(
        SoftLaunchRemoteConfigKeys.publicRolloutEnabled,
      );

  @override
  bool get emergencyRolloutStop => _remote.getBool(
        SoftLaunchRemoteConfigKeys.emergencyRolloutStop,
      );

  @override
  bool get betaChannelOnly => _remote.getBool(
        SoftLaunchRemoteConfigKeys.betaChannelOnly,
      );

  @override
  bool get softLaunchFreeze => _remote.getBool(
        SoftLaunchRemoteConfigKeys.softLaunchFreeze,
      );

  static int _clampPercentage(int raw) {
    const allowed = {0, 5, 10, 25, 50, 100};
    if (allowed.contains(raw)) return raw;
    if (raw <= 0) return 0;
    if (raw <= 5) return 5;
    if (raw <= 10) return 10;
    if (raw <= 25) return 25;
    if (raw <= 50) return 50;
    return 100;
  }

  Map<String, dynamic> snapshot() => {
        'softLaunchEnabled': softLaunchEnabled,
        'rolloutPercentage': rolloutPercentage,
        'publicRolloutEnabled': publicRolloutEnabled,
        'emergencyRolloutStop': emergencyRolloutStop,
        'betaChannelOnly': betaChannelOnly,
        'softLaunchFreeze': softLaunchFreeze,
      };
}
