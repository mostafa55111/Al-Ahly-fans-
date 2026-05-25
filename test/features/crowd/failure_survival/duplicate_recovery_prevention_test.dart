import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/finalize_recovery_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/infrastructure_degradation_resolver.dart';

void main() {
  const orchestrator = FinalizeRecoveryOrchestrator();

  setUp(() {
    FailureSurvivalRuntimeReport.instance.reset();
  });

  test('inFlight set blocks duplicate recovery', () {
    final inFlight = {'m1'};
    expect(
      orchestrator.shouldBlockDuplicateRecovery(
        matchId: 'm1',
        inFlight: inFlight,
      ),
      isTrue,
    );
    expect(
      FailureSurvivalRuntimeReport.instance.duplicateRecoveryPrevented,
      1,
    );
  });

  test('degradation resolver single recovery slot', () {
    final r = InfrastructureDegradationResolver.instance;
    expect(r.tryEnterRecovery('a'), isTrue);
    expect(r.tryEnterRecovery('b'), isFalse);
    r.leaveRecovery();
    expect(r.tryEnterRecovery('b'), isTrue);
    r.leaveRecovery();
  });
}
