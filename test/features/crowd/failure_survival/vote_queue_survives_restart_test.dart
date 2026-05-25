import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/durable_vote_intent_queue.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('queue persists across reload (restart simulation)', () async {
    final prefs = await SharedPreferences.getInstance();
    final q1 = DurableVoteIntentQueue(prefs);
    await q1.enqueue(
      VoteIntent(
        operationId: 'op1',
        uid: 'u1',
        matchId: 'm1',
        playerId: 'p1',
        clubTag: 'ahly',
        createdAtServerEstimate: 1000,
        retryCount: 0,
        sessionStatusSnapshot: 'snap',
        enqueuedAtMs: 1000,
      ),
    );
    final q2 = DurableVoteIntentQueue(prefs);
    expect(q2.load().length, 1);
    expect(q2.load().first.operationId, 'op1');
  });

  test('FIFO capped at maxSize', () async {
    final prefs = await SharedPreferences.getInstance();
    final q = DurableVoteIntentQueue(prefs, maxSize: 3);
    for (var i = 0; i < 5; i++) {
      await q.enqueue(
        VoteIntent(
          operationId: 'op$i',
          uid: 'u',
          matchId: 'm',
          playerId: 'p',
          clubTag: 'ahly',
          createdAtServerEstimate: i,
          retryCount: 0,
          sessionStatusSnapshot: 's',
          enqueuedAtMs: i,
        ),
      );
    }
    final loaded = q.load();
    expect(loaded.length, 3);
    expect(loaded.first.operationId, 'op2');
    expect(loaded.last.operationId, 'op4');
  });
}
