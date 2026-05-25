import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/deterministic_backoff.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/infrastructure_degradation_resolver.dart';

void main() {
  setUp(FailureSurvivalRuntimeReport.instance.reset);

  test('authority timeout activates fallback mode', () {
    final mode = InfrastructureDegradationResolver.instance.resolve(
      const InfrastructureSignals(authorityTimeout: true),
    );
    expect(mode, CrowdInfrastructureRuntimeMode.authorityFallback);
  });

  test('backoff timing increases deterministically with attempts', () {
    const backoff = DeterministicBackoff(baseMs: 200, maxMs: 5000);
    final delays = <int>[];
    for (var i = 1; i <= 4; i++) {
      delays.add(
        backoff.delayMsForAttempt(operationId: 'authority_finalize', attempt: i),
      );
    }
    for (var i = 1; i < delays.length; i++) {
      expect(delays[i], greaterThanOrEqualTo(delays[i - 1]));
    }
    expect(delays.last, lessThanOrEqualTo(5000 + 401));
  });
}
