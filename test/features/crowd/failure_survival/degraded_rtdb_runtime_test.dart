import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/infrastructure_degradation_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/socket_pressure_guard.dart';

void main() {
  setUp(() {
    FailureSurvivalRuntimeReport.instance.reset();
    SocketPressureGuard.instance.reset();
  });

  test('rtdb slow maps to degraded_reads', () {
    SocketPressureGuard.instance.setRuntimePressure(high: true);
    final mode = InfrastructureDegradationResolver.instance.resolve(
      InfrastructureDegradationResolver.instance.collectLiveSignals(),
    );
    expect(mode, CrowdInfrastructureRuntimeMode.degradedReads);
    expect(InfrastructureDegradationResolver.instance.suppressHeavyPreload, isTrue);
  });

  test('authority timeout maps to authority_fallback', () {
    final mode = InfrastructureDegradationResolver.instance.resolve(
      const InfrastructureSignals(authorityTimeout: true),
    );
    expect(mode, CrowdInfrastructureRuntimeMode.authorityFallback);
    expect(FailureSurvivalRuntimeReport.instance.authorityFallbacks, 1);
  });

  test('recovery mode when queue depth and partial shards', () {
    final mode = InfrastructureDegradationResolver.instance.resolve(
      const InfrastructureSignals(
        recoveryQueueDepth: 2,
        partialShardReads: true,
        authorityTimeout: true,
      ),
    );
    expect(mode, CrowdInfrastructureRuntimeMode.recoveryMode);
  });
}
