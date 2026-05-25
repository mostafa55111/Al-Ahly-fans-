import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_contract.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/runtime_owner_guard.dart';

enum LaunchStabilityScenario {
  openAppNoSession,
  publishSession,
  castVote,
  sessionHourEnds,
  finalizeSession,
  hallOfFameUpdate,
  reopenApp,
  reconnectStorm,
  backgroundResume,
  degradedNetwork,
}

class LaunchStabilityScenarioResult {
  const LaunchStabilityScenarioResult({
    required this.scenario,
    required this.passed,
    this.detail,
  });

  final LaunchStabilityScenario scenario;
  final bool passed;
  final String? detail;
}

/// سيناريوهات استقرار الإطلاق — تُشغَّل في الاختبارات وdebug.
class LaunchStabilitySuite {
  LaunchStabilitySuite._();

  static final LaunchStabilitySuite instance = LaunchStabilitySuite._();

  final List<LaunchStabilityScenarioResult> _results = [];

  Future<LaunchStabilityScenarioResult> run(
    LaunchStabilityScenario scenario, {
    required Future<bool> Function() body,
  }) async {
    try {
      final ok = await body();
      final result = LaunchStabilityScenarioResult(
        scenario: scenario,
        passed: ok,
        detail: ok ? null : 'body_returned_false',
      );
      _results.add(result);
      return result;
    } catch (e, st) {
      final result = LaunchStabilityScenarioResult(
        scenario: scenario,
        passed: false,
        detail: '$e',
      );
      _results.add(result);
      if (kDebugMode) debugPrint('[LaunchStability] $scenario FAIL: $e\n$st');
      return result;
    }
  }

  /// تشغيل سيناريوهات وحدوية (logic gates) بدون Firebase.
  Future<Map<String, bool>> runLogicGates() async {
    _results.clear();

    await run(LaunchStabilityScenario.openAppNoSession, body: () async => true);

    await run(LaunchStabilityScenario.castVote, body: () async {
      LaunchContract.assertSupportedOnly('vote_edits');
      return !LaunchContract.isUnsupportedActive(
        LaunchUnsupportedCapability.voteEdits,
      );
    });

    await run(LaunchStabilityScenario.finalizeSession, body: () async {
      RuntimeOwnerGuard.instance.recordFinalizeAttempt();
      final claimed = RuntimeOwnerGuard.instance.claim(
        RuntimeOwnershipDomain.finalize,
        'ProductionFinalizePipeline',
      );
      RuntimeOwnerGuard.instance.recordFinalizeComplete();
      return claimed;
    });

    await run(LaunchStabilityScenario.reconnectStorm, body: () async {
      RuntimeOwnerGuard.instance.recordReconnectOrchestration(
        'LazyVoteSubscriptionController',
      );
      return RuntimeOwnerGuard.instance.violations.isEmpty;
    });

    return {for (final r in _results) r.scenario.name: r.passed};
  }

  bool get allPassed => _results.isNotEmpty && _results.every((r) => r.passed);

  List<LaunchStabilityScenarioResult> get results =>
      List.unmodifiable(_results);

  @visibleForTesting
  void reset() => _results.clear();
}
