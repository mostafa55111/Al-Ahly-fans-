import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';

/// سياسة قناة الإصدار — بدون أسرار.
enum ReleaseChannelTier {
  internal,
  closedBeta,
  softLaunch,
  production,
}

class ReleaseChannelPolicy {
  ReleaseChannelPolicy({
    FirebaseRemoteConfig? remote,
    String? channelOverride,
    bool? betaChannelOnlyOverride,
    bool? publicRolloutOverride,
  })  : _remote = remote,
        _channelOverride = channelOverride,
        _betaChannelOnlyOverride = betaChannelOnlyOverride,
        _publicRolloutOverride = publicRolloutOverride;

  final FirebaseRemoteConfig? _remote;
  final String? _channelOverride;
  final bool? _betaChannelOnlyOverride;
  final bool? _publicRolloutOverride;

  @visibleForTesting
  factory ReleaseChannelPolicy.testing({
    String channel = 'soft',
    bool betaChannelOnly = true,
    bool publicRolloutEnabled = false,
  }) =>
      ReleaseChannelPolicy(
        channelOverride: channel,
        betaChannelOnlyOverride: betaChannelOnly,
        publicRolloutOverride: publicRolloutEnabled,
      );

  String get configuredChannel {
    if (_channelOverride != null) return _channelOverride!.trim().toLowerCase();
    return (_remote ?? FirebaseRemoteConfig.instance)
        .getString('release_channel')
        .trim()
        .toLowerCase();
  }

  bool get betaChannelOnly {
    if (_betaChannelOnlyOverride != null) return _betaChannelOnlyOverride!;
    return (_remote ?? FirebaseRemoteConfig.instance)
        .getBool('crowd_beta_channel_only');
  }

  bool get publicRolloutEnabled {
    if (_publicRolloutOverride != null) return _publicRolloutOverride!;
    return (_remote ?? FirebaseRemoteConfig.instance)
        .getBool('crowd_public_rollout_enabled');
  }

  ReleaseChannelTier resolveTier() {
    final ch = configuredChannel;
    if (ch.contains('internal')) return ReleaseChannelTier.internal;
    if (ch.contains('beta') || ch.contains('closed')) {
      return ReleaseChannelTier.closedBeta;
    }
    if (ch.contains('soft')) return ReleaseChannelTier.softLaunch;
    if (ch.isEmpty && ReleaseModeGuard.isStrictRelease) {
      return ReleaseChannelTier.production;
    }
    return ReleaseChannelTier.softLaunch;
  }

  bool isProductionSafe() {
    if (!ReleaseModeGuard.isStrictRelease) return true;
    if (ReleaseModeGuard.sandboxDisabled) return true;
    return configuredChannel == 'production' || configuredChannel == 'soft';
  }
}
