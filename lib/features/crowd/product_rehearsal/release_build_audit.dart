import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/legacy/legacy_crowd_feature_flags.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/experimental_feature_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_contract.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';
class ReleaseBuildFinding {
  const ReleaseBuildFinding({
    required this.check,
    required this.passed,
    this.detail,
  });

  final String check;
  final bool passed;
  final String? detail;
}

/// تدقيق build الإصدار — لا debug/sandbox/legacy في release.
class ReleaseBuildAudit {
  ReleaseBuildAudit._();

  static final ReleaseBuildAudit instance = ReleaseBuildAudit._();

  final List<ReleaseBuildFinding> _findings = [];

  List<ReleaseBuildFinding> get findings => List.unmodifiable(_findings);

  bool get green => _findings.isNotEmpty && _findings.every((f) => f.passed);

  void run() {
    _findings.clear();

    _check('no_debug_banners_in_strict_release', () {
      if (!ReleaseModeGuard.isStrictRelease) return true;
      return !ReleaseModeGuard.allowDebugOps;
    });

    _check('sandbox_disabled', () {
      if (!ReleaseModeGuard.isStrictRelease) return true;
      return ReleaseModeGuard.sandboxDisabled;
    });

    _check('experimental_disabled', () {
      if (ReleaseModeGuard.isStrictRelease) {
        return ReleaseModeGuard.experimentalDisabled;
      }
      return true;
    });

    _check('legacy_voting_off', () => !LegacyCrowdFeatureFlags.enableLegacyVoting);
    _check('legacy_routes_off', () => !LegacyCrowdFeatureFlags.enableLegacyRoutes);
    _check('legacy_streams_off', () => !LegacyCrowdFeatureFlags.enableLegacyStreams);

    _check('experimental_sandbox_blocked', () {
      return !ExperimentalFeatureGuard.allowLoad(
        ExperimentalFeatureId.productionOpsSandbox,
      );
    });

    _check('release_freeze_config_ready', () {
      return ProductionFeatureFreeze.instance.isReady;
    });

    _check('launch_contract_defined', () {
      return LaunchContract.supported.isNotEmpty;
    });
  }

  void _check(String name, bool Function() predicate) {
    final ok = predicate();
    _findings.add(ReleaseBuildFinding(check: name, passed: ok));
    if (!ok && kDebugMode) {
      debugPrint('[ReleaseBuildAudit] FAIL: $name');
    }
  }

  Map<String, dynamic> snapshot() => {
        'green': green,
        'findings': _findings
            .map(
              (f) => {
                'check': f.check,
                'passed': f.passed,
                'detail': f.detail,
              },
            )
            .toList(),
        'strictRelease': ReleaseModeGuard.isStrictRelease,
      };

  @visibleForTesting
  void reset() => _findings.clear();
}
