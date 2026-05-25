import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/finalize_recovery_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

void main() {
  test('recovery plan skips when session already finalized', () {
    const orchestrator = FinalizeRecoveryOrchestrator();
    const session = MatchActiveSession(
      id: 'm1',
      title: 't',
      votingEnabled: false,
      formation: '4-3-3',
      createdAt: 0,
      awardsFinalized: true,
      status: 'closed',
      closesAtServer: 1000,
    );
    final plan = orchestrator.plan(
      session: session,
      snapshot: const FinalizeRecoverySnapshot(
        sessionFinalized: true,
        matchAwardExists: true,
        leaseAcquired: true,
        aggregationChecksum: null,
        monthlyDone: true,
        seasonDone: true,
      ),
    );
    expect(plan.skipEntirely, isTrue);
  });

  test('shouldBlockDuplicateRecovery when in flight', () {
    const orchestrator = FinalizeRecoveryOrchestrator();
    final inFlight = {'m1'};
    expect(
      orchestrator.shouldBlockDuplicateRecovery(
        matchId: 'm1',
        inFlight: inFlight,
      ),
      isTrue,
    );
  });
}
