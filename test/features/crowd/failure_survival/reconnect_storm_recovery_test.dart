import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/deterministic_backoff.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/infrastructure_degradation_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/reconnect_backoff_controller.dart';

void main() {
  setUp(() {
    FailureSurvivalRuntimeReport.instance.reset();
    InfrastructureDegradationResolver.instance;
  });

  test('reconnect backoff delays are deterministic', () {
    final a = ReconnectBackoffController();
    final b = ReconnectBackoffController();
    expect(a.nextResumeDelayMs(), b.nextResumeDelayMs());
  });

  test('degraded mode on reconnect storm', () {
    final mode = InfrastructureDegradationResolver.instance.resolve(
      const InfrastructureSignals(reconnectStorm: true),
    );
    expect(mode, CrowdInfrastructureRuntimeMode.lightweightRuntime);
    expect(
      FailureSurvivalRuntimeReport.instance.degradedRuntimeActivations,
      greaterThan(0),
    );
  });

  test('exponential backoff caps attempts', () {
    const backoff = DeterministicBackoff(maxAttempts: 5);
    expect(backoff.shouldRetry(4), isTrue);
    expect(backoff.shouldRetry(5), isFalse);
    final d1 = backoff.delayMsForAttempt(operationId: 'x', attempt: 1);
    final d2 = backoff.delayMsForAttempt(operationId: 'x', attempt: 2);
    expect(d2, greaterThan(d1));
  });
}
