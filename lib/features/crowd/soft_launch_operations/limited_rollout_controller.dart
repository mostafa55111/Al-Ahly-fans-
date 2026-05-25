import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/beta_distribution_registry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_remote_config.dart';

/// نسب الإطلاق المدعومة.
enum RolloutStage {
  none,
  p5,
  p10,
  p25,
  p50,
  p100,
}

class RolloutAccessVerdict {
  const RolloutAccessVerdict({
    required this.allowed,
    required this.reason,
    required this.stage,
  });

  final bool allowed;
  final String reason;
  final RolloutStage stage;
}

/// تحكم بالإطلاق المرحلي — RC + فحوص محلية.
class LimitedRolloutController {
  LimitedRolloutController({
    SoftLaunchConfigReader? config,
    BetaDistributionRegistry? registry,
  })  : _config = config ?? SoftLaunchRemoteConfig(),
        _registry = registry ?? BetaDistributionRegistry.instance;

  final SoftLaunchConfigReader _config;
  final BetaDistributionRegistry _registry;

  static const rolloutStages = [5, 10, 25, 50, 100];

  RolloutStage stageFromPercentage(int pct) => switch (pct) {
        0 => RolloutStage.none,
        5 => RolloutStage.p5,
        10 => RolloutStage.p10,
        25 => RolloutStage.p25,
        50 => RolloutStage.p50,
        100 => RolloutStage.p100,
        _ => RolloutStage.none,
      };

  bool get rolloutFrozen =>
      _config.softLaunchFreeze || _config.emergencyRolloutStop;

  bool get emergencyStop => _config.emergencyRolloutStop;

  RolloutAccessVerdict evaluateAccess({
    required String? userOrDeviceKey,
    bool isOwner = false,
    bool isApprovedBeta = false,
  }) {
    if (_config.emergencyRolloutStop) {
      return const RolloutAccessVerdict(
        allowed: false,
        reason: 'إيقاف طوارئ نشط',
        stage: RolloutStage.none,
      );
    }
    if (!_config.softLaunchEnabled) {
      return const RolloutAccessVerdict(
        allowed: false,
        reason: 'الإطلاق الناعم غير مفعّل',
        stage: RolloutStage.none,
      );
    }
    if (_config.betaChannelOnly && !isOwner && !isApprovedBeta) {
      return const RolloutAccessVerdict(
        allowed: false,
        reason: 'قناة beta فقط',
        stage: RolloutStage.none,
      );
    }
    if (isOwner || isApprovedBeta) {
      if (isApprovedBeta && userOrDeviceKey != null && userOrDeviceKey.isNotEmpty) {
        _registry.register(
          deviceId: userOrDeviceKey,
          releaseChannel: 'beta',
          cohort: 'approved_beta',
          approvedBeta: true,
          ownerDevice: isOwner,
        );
      }
      return RolloutAccessVerdict(
        allowed: true,
        reason: 'مستثنى (مالك/بيتا)',
        stage: stageFromPercentage(_config.rolloutPercentage),
      );
    }
    final pct = _config.rolloutPercentage;
    final stage = stageFromPercentage(pct);
    if (pct >= 100 || _config.publicRolloutEnabled) {
      return RolloutAccessVerdict(
        allowed: true,
        reason: 'إطلاق عام مسموح',
        stage: stage,
      );
    }
    final key = userOrDeviceKey ?? '';
    if (key.isEmpty) {
      return RolloutAccessVerdict(
        allowed: false,
        reason: 'لا معرّف مستخدم',
        stage: stage,
      );
    }
    final bucket = _stableBucket(key);
    final allowed = bucket < pct;
    return RolloutAccessVerdict(
      allowed: allowed,
      reason: allowed ? 'ضمن نسبة $pct%' : 'خارج نطاق $pct%',
      stage: stage,
    );
  }

  int _stableBucket(String key) {
    var h = 0;
    for (final c in key.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h % 100;
  }

  bool canExpandToNextStage() {
    if (rolloutFrozen) return false;
    final current = _config.rolloutPercentage;
    final idx = rolloutStages.indexOf(current);
    return idx >= 0 && idx < rolloutStages.length - 1;
  }

  int? nextStagePercentage() {
    final current = _config.rolloutPercentage;
    final idx = rolloutStages.indexOf(current);
    if (idx < 0 || idx >= rolloutStages.length - 1) return null;
    return rolloutStages[idx + 1];
  }
}
