import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/launch_freeze_enforcer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/beta_distribution_registry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/controlled_rollout_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/limited_rollout_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/production_rollout_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/release_channel_policy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_remote_config.dart';

/// مرحلة الإطلاق التشغيلية.
enum SoftLaunchPhase {
  disabled,
  internalBeta,
  closedBeta,
  softLaunchActive,
  rolloutExpansion,
  emergencyRollback,
}

/// السلطة المركزية للإطلاق الناعم.
class SoftLaunchGovernor {
  SoftLaunchGovernor({
    SoftLaunchConfigReader? config,
    LimitedRolloutController? rollout,
    ProductionRolloutGuard? guard,
    LaunchFreezeEnforcer? freeze,
    ControlledRolloutGate? expansionGate,
    BetaDistributionRegistry? registry,
    ReleaseChannelPolicy? channel,
  })  : _config = config ?? SoftLaunchRemoteConfig(),
        _freeze = freeze ?? LaunchFreezeEnforcer(),
        _registry = registry ?? BetaDistributionRegistry.instance {
    final cfg = _config;
    final ch = channel ?? ReleaseChannelPolicy();
    _channel = ch;
    _guard = guard ?? ProductionRolloutGuard(config: cfg, channel: ch);
    _rollout = rollout ?? LimitedRolloutController(config: cfg);
    _expansionGate =
        expansionGate ?? ControlledRolloutGate(rolloutGuard: _guard);
  }

  final SoftLaunchConfigReader _config;
  late final LimitedRolloutController _rollout;
  late final ProductionRolloutGuard _guard;
  final LaunchFreezeEnforcer _freeze;
  late final ControlledRolloutGate _expansionGate;
  final BetaDistributionRegistry _registry;
  late final ReleaseChannelPolicy _channel;

  SoftLaunchPhase get currentPhase {
    if (_config.emergencyRolloutStop) {
      return SoftLaunchPhase.emergencyRollback;
    }
    if (!_config.softLaunchEnabled) return SoftLaunchPhase.disabled;
    if (_config.betaChannelOnly) {
      return _registry.globalPhase == BetaDistributionPhase.internal
          ? SoftLaunchPhase.internalBeta
          : SoftLaunchPhase.closedBeta;
    }
    if (_rollout.canExpandToNextStage()) {
      return SoftLaunchPhase.rolloutExpansion;
    }
    return SoftLaunchPhase.softLaunchActive;
  }

  bool get betaRestrictionsActive =>
      _config.betaChannelOnly || !_config.publicRolloutEnabled;

  bool get launchFreezeEnforced =>
      _freeze.isFreezeActive || _config.softLaunchFreeze;

  bool get operationalReadinessOk {
    final g = _guard.evaluate();
    return g.verdict != ProductionRolloutVerdict.blocked;
  }

  ControlledRolloutGateReport evaluateExpansion() =>
      _expansionGate.evaluate();

  void triggerEmergencyRollback() {
    if (kDebugMode) {
      debugPrint(
        '[SoftLaunchGovernor] emergency rollback requested — '
        'set crowd_emergency_rollout_stop=true in RC',
      );
    }
  }

  Map<String, dynamic> operationalSnapshot() => {
        'phase': currentPhase.name,
        'rc': _config is SoftLaunchRemoteConfig
            ? (_config as SoftLaunchRemoteConfig).snapshot()
            : <String, dynamic>{
                'softLaunchEnabled': _config.softLaunchEnabled,
                'rolloutPercentage': _config.rolloutPercentage,
              },
        'channel': _channel.configuredChannel,
        'channelTier': _channel.resolveTier().name,
        'freeze': launchFreezeEnforced,
        'rolloutFrozen': _rollout.rolloutFrozen,
        'betaDevices': _registry.allDevices.length,
        'expansion': evaluateExpansion().verdict.name,
        'featureFreeze': ProductionFeatureFreeze.instance.featureFreeze,
      };
}
