import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/deterministic_backoff.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/durable_vote_intent_queue.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FailureSurvivalRuntimeReport.instance.reset();
  });

  test('pause blocks replay for stale session', () async {
    final prefs = await SharedPreferences.getInstance();
    final queue = DurableVoteIntentQueue(prefs);
    final intent = VoteIntent(
      operationId: 'op',
      uid: 'u',
      matchId: 'm',
      playerId: 'p',
      clubTag: 'ahly',
      createdAtServerEstimate: 1000,
      retryCount: 0,
      sessionStatusSnapshot: 's',
      enqueuedAtMs: 1000,
    );
    await queue.enqueue(intent);
    final staleSession = MatchActiveSession(
      id: 'm',
      title: 't',
      votingEnabled: true,
      formation: '4-3-3',
      createdAt: 1,
      closesAtServer: 500,
    );
    final due = queue.dueForReplay(
      serverNowMs: 2000,
      session: staleSession,
      userAlreadyVoted: (_) => false,
    );
    expect(due, isEmpty);
  });

  test('deterministic replay delay stable', () {
    const backoff = DeterministicBackoff();
    final d = backoff.delayMsForAttempt(operationId: 'op', attempt: 2);
    expect(d, backoff.delayMsForAttempt(operationId: 'op', attempt: 2));
  });
}
