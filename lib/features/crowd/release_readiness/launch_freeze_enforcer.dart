import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';

/// فئة تغيير أثناء التجميد.
enum LaunchFreezeChangeKind {
  feature,
  tab,
  runtimeLayer,
  experimentalFlag,
  realtimeSystem,
  bugFix,
  readability,
  spacing,
  stability,
  accessibility,
  performance,
}

/// نتيجة فحص التجميد.
class LaunchFreezeVerdict {
  const LaunchFreezeVerdict({required this.allowed, this.reason});

  final bool allowed;
  final String? reason;
}

/// يفرض تجميد الإطلاق — RC + محلي.
class LaunchFreezeEnforcer {
  LaunchFreezeEnforcer({ProductionFeatureFreeze? freeze})
      : _freeze = freeze ?? ProductionFeatureFreeze.instance;

  final ProductionFeatureFreeze _freeze;

  static const _blockedKinds = {
    LaunchFreezeChangeKind.feature,
    LaunchFreezeChangeKind.tab,
    LaunchFreezeChangeKind.runtimeLayer,
    LaunchFreezeChangeKind.experimentalFlag,
    LaunchFreezeChangeKind.realtimeSystem,
  };

  static const _allowedKinds = {
    LaunchFreezeChangeKind.bugFix,
    LaunchFreezeChangeKind.readability,
    LaunchFreezeChangeKind.spacing,
    LaunchFreezeChangeKind.stability,
    LaunchFreezeChangeKind.accessibility,
    LaunchFreezeChangeKind.performance,
  };

  LaunchFreezeVerdict evaluateChange(LaunchFreezeChangeKind kind) {
    if (_allowedKinds.contains(kind)) {
      return const LaunchFreezeVerdict(allowed: true);
    }
    if (!_blockedKinds.contains(kind)) {
      return const LaunchFreezeVerdict(allowed: true);
    }
    final active = _freeze.featureFreeze || _freeze.runtimeLock;
    if (!active && !ReleaseModeGuard.isStrictRelease) {
      return const LaunchFreezeVerdict(allowed: true);
    }
    if (_freeze.blocksNewCapability(kind.name)) {
      return LaunchFreezeVerdict(
        allowed: false,
        reason: 'تجميد الإطلاق نشط — ممنوع: ${kind.name}',
      );
    }
    return LaunchFreezeVerdict(
      allowed: false,
      reason: 'تجميد الإطلاق — ${kind.name}',
    );
  }

  bool get isFreezeActive =>
      _freeze.featureFreeze ||
      _freeze.runtimeLock ||
      _readRemoteLaunchFreeze();

  bool _readRemoteLaunchFreeze() {
    try {
      final rc = FirebaseRemoteConfig.instance;
      return rc.getBool('crowd_launch_freeze') ||
          rc.getBool('crowd_feature_freeze');
    } catch (e) {
      debugPrint('[LaunchFreezeEnforcer] rc: $e');
      return false;
    }
  }

  Map<String, bool> snapshot() => {
        'featureFreeze': _freeze.featureFreeze,
        'runtimeLock': _freeze.runtimeLock,
        'remoteLaunchFreeze': _readRemoteLaunchFreeze(),
        'strictRelease': ReleaseModeGuard.isStrictRelease,
      };
}