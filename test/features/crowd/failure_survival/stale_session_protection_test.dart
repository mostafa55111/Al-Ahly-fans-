import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/stale_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

void main() {
  const guard = StaleSessionGuard();

  setUp(FailureSurvivalRuntimeReport.instance.reset);

  test('rejects finalized session', () {
    final v = guard.evaluate(
      session: const MatchActiveSession(
        id: 'm',
        title: 't',
        votingEnabled: true,
        formation: '4-3-3',
        createdAt: 1,
        awardsFinalized: true,
      ),
      serverNowMs: 5000,
    );
    expect(v.acceptsVotes, isFalse);
    expect(v.isStale, isTrue);
  });

  test('rejects past closesAtServer', () {
    final v = guard.evaluate(
      session: MatchActiveSession(
        id: 'm',
        title: 't',
        votingEnabled: true,
        formation: '4-3-3',
        createdAt: 1,
        closesAtServer: 1000,
        openedAtServer: 500,
      ),
      serverNowMs: 2000,
    );
    expect(v.acceptsVotes, isFalse);
    expect(FailureSurvivalRuntimeReport.instance.staleSessionsBlocked, 1);
  });

  test('accepts open session with server clock', () {
    final v = guard.evaluate(
      session: MatchActiveSession(
        id: 'm',
        title: 't',
        votingEnabled: true,
        formation: '4-3-3',
        createdAt: 500,
        closesAtServer: 999999999999,
        openedAtServer: 500,
      ),
      serverNowMs: 10000,
      recordBlock: false,
    );
    expect(v.acceptsVotes, isTrue);
  });
}
