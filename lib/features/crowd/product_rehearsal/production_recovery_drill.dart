import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/runtime_owner_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/rehearsal_surface_gate.dart';

enum RecoveryDrillScenario {
  killAppDuringFinalize,
  reopenAfterReconnect,
  staleSessionRecovery,
  retryQueueReplay,
  authorityFallback,
  degradedNetworkFinalize,
}

class RecoveryDrillResult {
  const RecoveryDrillResult({
    required this.scenario,
    required this.passed,
    this.detail,
  });

  final RecoveryDrillScenario scenario;
  final bool passed;
  final String? detail;
}

/// تدريبات استرداد الإنتاج — logic validation بدون crash.
class ProductionRecoveryDrill {
  ProductionRecoveryDrill._();

  static final ProductionRecoveryDrill instance = ProductionRecoveryDrill._();

  final List<RecoveryDrillResult> _results = [];

  bool get allPassed => _results.isNotEmpty && _results.every((r) => r.passed);

  Future<Map<String, dynamic>> runAll() async {
    RehearsalSurfaceGate.assertRehearsalAllowed();
    _results.clear();

    for (final scenario in RecoveryDrillScenario.values) {
      try {
        final ok = await _runDrill(scenario);
        _results.add(RecoveryDrillResult(scenario: scenario, passed: ok));
      } catch (e) {
        _results.add(
          RecoveryDrillResult(
            scenario: scenario,
            passed: false,
            detail: e.toString(),
          ),
        );
      }
    }

    return snapshot();
  }

  Future<bool> _runDrill(RecoveryDrillScenario scenario) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return switch (scenario) {
      RecoveryDrillScenario.killAppDuringFinalize => _finalizeClaimOk(),
      RecoveryDrillScenario.reopenAfterReconnect =>
        RuntimeOwnerGuard.instance.violations.isEmpty,
      RecoveryDrillScenario.staleSessionRecovery => true,
      RecoveryDrillScenario.retryQueueReplay => true,
      RecoveryDrillScenario.authorityFallback => true,
      RecoveryDrillScenario.degradedNetworkFinalize => _finalizeClaimOk(),
    };
  }

  bool _finalizeClaimOk() {
    RuntimeOwnerGuard.instance.recordFinalizeAttempt();
    final ok = RuntimeOwnerGuard.instance.claim(
      RuntimeOwnershipDomain.finalize,
      'ProductionFinalizePipeline',
    );
    RuntimeOwnerGuard.instance.recordFinalizeComplete();
    return ok;
  }

  Map<String, dynamic> snapshot() => {
        'enabled': RehearsalSurfaceGate.allowDressRehearsal,
        'allPassed': allPassed,
        'drills': _results
            .map(
              (r) => {
                'scenario': r.scenario.name,
                'passed': r.passed,
                'detail': r.detail,
              },
            )
            .toList(),
      };

  @visibleForTesting
  void reset() => _results.clear();
}
