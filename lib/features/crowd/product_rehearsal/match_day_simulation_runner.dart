import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_stability_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/rehearsal_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/verification_sandbox_guard.dart';

enum MatchDayStep {
  ownerLogin,
  cmsOpen,
  lineupSelection,
  benchSelection,
  sessionPublish,
  fanJoins,
  votesCast,
  reconnectStorms,
  backgroundResume,
  countdownExpiry,
  finalize,
  hallOfFameRefresh,
}

class MatchDayStepResult {
  const MatchDayStepResult({
    required this.step,
    required this.passed,
    required this.durationMs,
    this.detail,
  });

  final MatchDayStep step;
  final bool passed;
  final int durationMs;
  final String? detail;
}

/// محاكاة يوم مباراة — orchestration فقط، بدون Firebase حقيقي في unit path.
class MatchDaySimulationRunner {
  MatchDaySimulationRunner._();

  static final MatchDaySimulationRunner instance = MatchDaySimulationRunner._();

  final List<MatchDayStepResult> _results = [];
  String? _sandboxSessionId;

  List<MatchDayStepResult> get results => List.unmodifiable(_results);

  bool get allPassed => _results.isNotEmpty && _results.every((r) => r.passed);

  int get totalDurationMs =>
      _results.fold<int>(0, (a, r) => a + r.durationMs);

  Future<Map<String, dynamic>> runFullMatchDay({
    Future<bool> Function(MatchDayStep step)? stepExecutor,
  }) async {
    RehearsalSurfaceGate.assertRehearsalAllowed();
    _results.clear();
    _sandboxSessionId = VerificationSandboxGuard.newSandboxSessionId('matchday');

    final steps = MatchDayStep.values;
    for (final step in steps) {
      final sw = Stopwatch()..start();
      var ok = true;
      String? detail;
      try {
        if (stepExecutor != null) {
          ok = await stepExecutor(step);
        } else {
          ok = await _defaultStep(step);
        }
      } catch (e) {
        ok = false;
        detail = e.toString();
      }
      sw.stop();
      _results.add(
        MatchDayStepResult(
          step: step,
          passed: ok,
          durationMs: sw.elapsedMilliseconds,
          detail: detail,
        ),
      );
    }

    return snapshot();
  }

  Future<bool> _defaultStep(MatchDayStep step) async {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    switch (step) {
      case MatchDayStep.reconnectStorms:
        return _simulateReconnect();
      case MatchDayStep.finalize:
        return _simulateFinalize();
      case MatchDayStep.hallOfFameRefresh:
        return true;
      default:
        return true;
    }
  }

  Future<bool> _simulateReconnect() async {
    final gates = await LaunchStabilitySuite.instance.runLogicGates();
    return gates[LaunchStabilityScenario.reconnectStorm.name] ?? false;
  }

  Future<bool> _simulateFinalize() async {
    final gates = await LaunchStabilitySuite.instance.runLogicGates();
    return gates[LaunchStabilityScenario.finalizeSession.name] ?? false;
  }

  Map<String, dynamic> snapshot() {
    if (!RehearsalSurfaceGate.allowDressRehearsal) {
      return const {'enabled': false};
    }
    return {
      'enabled': true,
      'sandboxSessionId': _sandboxSessionId,
      'allPassed': allPassed,
      'totalDurationMs': totalDurationMs,
      'steps': _results
          .map(
            (r) => {
              'step': r.step.name,
              'passed': r.passed,
              'durationMs': r.durationMs,
              'detail': r.detail,
            },
          )
          .toList(),
    };
  }

  @visibleForTesting
  void reset() => _results.clear();
}
