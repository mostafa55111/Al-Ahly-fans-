import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/human_validation_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/launch_freeze_enforcer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/release_channel_policy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_remote_config.dart';

/// حكم حماية الإطلاق الإنتاجي.
enum ProductionRolloutVerdict {
  safe,
  blocked,
  conditional,
}

class ProductionRolloutGuardReport {
  const ProductionRolloutGuardReport({
    required this.verdict,
    required this.findings,
  });

  final ProductionRolloutVerdict verdict;
  final Map<String, bool> findings;
}

/// يمنع الإطلاق العام العرضي.
class ProductionRolloutGuard {
  ProductionRolloutGuard({
    SoftLaunchConfigReader? config,
    LaunchFreezeEnforcer? freeze,
    HumanValidationSuite? human,
    ReleaseChannelPolicy? channel,
  })  : _config = config ?? SoftLaunchRemoteConfig(),
        _freeze = freeze ?? LaunchFreezeEnforcer(),
        _human = human ?? HumanValidationSuite(),
        _channel = channel ?? ReleaseChannelPolicy();

  final SoftLaunchConfigReader _config;
  final LaunchFreezeEnforcer _freeze;
  final HumanValidationSuite _human;
  final ReleaseChannelPolicy _channel;

  ProductionRolloutGuardReport evaluate({bool requireHumanValidated = false}) {
    final findings = <String, bool>{};

    findings['no_accidental_public'] =
        !_config.publicRolloutEnabled || _config.betaChannelOnly;

    findings['freeze_or_soft_freeze'] =
        _freeze.isFreezeActive || _config.softLaunchFreeze;

    final human = _human.buildReport();
    findings['owner_validation_clear'] = requireHumanValidated
        ? human.readyForGoLive
        : human.failedCount == 0 && human.blockedCount == 0;

    findings['release_channel_safe'] = _channel.isProductionSafe();

    final envOk = !ReleaseModeGuard.isStrictRelease ||
        (CrowdEnvironmentResolver.isBootstrapped &&
            CrowdEnvironmentResolver.current.isProductionData);
    findings['firebase_environment_valid'] = envOk;

    findings['no_emergency_stop'] = !_config.emergencyRolloutStop;

    findings['freeze_ready'] = ProductionFeatureFreeze.instance.isReady;

    final anyBlock = findings.entries.any((e) => !e.value);
    final critical = !findings['firebase_environment_valid']! ||
        !findings['no_emergency_stop']! ||
        (ReleaseModeGuard.isStrictRelease &&
            !_freeze.isFreezeActive &&
            _config.publicRolloutEnabled);

    ProductionRolloutVerdict verdict;
    if (critical || (anyBlock && requireHumanValidated)) {
      verdict = ProductionRolloutVerdict.blocked;
    } else if (anyBlock) {
      verdict = ProductionRolloutVerdict.conditional;
    } else {
      verdict = ProductionRolloutVerdict.safe;
    }

    return ProductionRolloutGuardReport(verdict: verdict, findings: findings);
  }
}
