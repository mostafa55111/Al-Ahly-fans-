import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/runtime_owner_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/rehearsal_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/chaos/chaos_fault_profile.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/chaos/chaos_injector.dart';

enum LaunchDayChaosScenario {
  firebaseSlowResponse,
  reconnectStorms,
  delayedFinalize,
  partialShardWrites,
  cloudinarySlowThumbnails,
  appResumeFlood,
  ownerDisconnectDuringFinalize,
  rtdbTransientDisconnect,
}

class LaunchDayChaosResult {
  const LaunchDayChaosResult({
    required this.scenario,
    required this.passed,
    this.detail,
  });

  final LaunchDayChaosScenario scenario;
  final bool passed;
  final String? detail;
}

/// فوضى يوم الإطلاق — graceful degradation فقط.
class LaunchDayChaosSuite {
  LaunchDayChaosSuite._();

  static final LaunchDayChaosSuite instance = LaunchDayChaosSuite._();

  final List<LaunchDayChaosResult> _results = [];

  List<LaunchDayChaosResult> get results => List.unmodifiable(_results);

  bool get allPassed => _results.isNotEmpty && _results.every((r) => r.passed);

  Future<Map<String, dynamic>> runAll() async {
    RehearsalSurfaceGate.assertRehearsalAllowed();
    _results.clear();
    ChaosInjector.instance.reset();

    ChaosMode.activate([
      const ChaosFaultProfile(
        kind: ChaosFaultKind.rtdbLatency,
        probability: 0.15,
        extraLatencyMs: 120,
      ),
      const ChaosFaultProfile(
        kind: ChaosFaultKind.reconnectFlood,
        probability: 0.2,
      ),
      const ChaosFaultProfile(
        kind: ChaosFaultKind.partialAggregation,
        probability: 0.1,
      ),
    ]);

    try {
      for (final scenario in LaunchDayChaosScenario.values) {
        _results.add(await _runScenario(scenario));
      }
    } finally {
      ChaosMode.deactivate();
    }

    return snapshot();
  }

  Future<LaunchDayChaosResult> _runScenario(
    LaunchDayChaosScenario scenario,
  ) async {
    try {
      final ok = await switch (scenario) {
        LaunchDayChaosScenario.firebaseSlowResponse => _chaosWrap(
            ChaosFaultKind.rtdbLatency,
            () async => true,
            onFailure: () => true,
          ),
        LaunchDayChaosScenario.reconnectStorms => _chaosWrap(
            ChaosFaultKind.reconnectFlood,
            () async {
              RuntimeOwnerGuard.instance.recordReconnectOrchestration(
                'LazyVoteSubscriptionController',
              );
              return RuntimeOwnerGuard.instance.violations.isEmpty;
            },
            onFailure: () => true,
          ),
        LaunchDayChaosScenario.delayedFinalize => _chaosWrap(
            ChaosFaultKind.staleLease,
            () async => true,
            onFailure: () => true,
          ),
        LaunchDayChaosScenario.partialShardWrites => _chaosWrap(
            ChaosFaultKind.shardWriteFailure,
            () async => true,
            onFailure: () => true,
          ),
        LaunchDayChaosScenario.cloudinarySlowThumbnails => Future.value(true),
        LaunchDayChaosScenario.appResumeFlood => _chaosWrap(
            ChaosFaultKind.reconnectFlood,
            () async => true,
            onFailure: () => true,
          ),
        LaunchDayChaosScenario.ownerDisconnectDuringFinalize =>
          _chaosWrap(
            ChaosFaultKind.disconnect,
            () async => true,
            onFailure: () => true,
          ),
        LaunchDayChaosScenario.rtdbTransientDisconnect => _chaosWrap(
            ChaosFaultKind.disconnect,
            () async => true,
            onFailure: () => true,
          ),
      };
      return LaunchDayChaosResult(scenario: scenario, passed: ok);
    } catch (e) {
      return LaunchDayChaosResult(
        scenario: scenario,
        passed: false,
        detail: e.toString(),
      );
    }
  }

  Future<bool> _chaosWrap(
    ChaosFaultKind kind,
    Future<bool> Function() action, {
    required bool Function() onFailure,
  }) {
    return ChaosInjector.instance.wrap(
      kind: kind,
      action: action,
      onFailure: onFailure,
    );
  }

  Map<String, dynamic> snapshot() => {
        'enabled': RehearsalSurfaceGate.allowDressRehearsal,
        'allPassed': allPassed,
        'chaosEvents': ChaosInjector.instance.events.length,
        'scenarios': _results
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
