import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/deterministic_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_idempotency_guard.dart';

void main() {
  setUp(DeterministicRuntimeReport.instance.reset);

  test('reconnect storm blocks duplicate cast fingerprints', () {
    final guard = VoteIdempotencyGuard(maxEntries: 2048);
    final fp = VoteOperationFingerprint(
      uid: 'uid_storm',
      playerId: 'p1',
      matchId: 'match_1',
      clubTag: 'ahly',
      operationType: VoteOperationType.reconnectReplay,
      createdAtBucket: 100,
    );

    var allowed = 0;
    var blocked = 0;
    for (var i = 0; i < 50; i++) {
      if (guard.tryAcquire(fp)) {
        allowed++;
      } else {
        blocked++;
      }
    }
    expect(allowed, 1);
    expect(blocked, 49);
    expect(DeterministicRuntimeReport.instance.replayBlocked, greaterThan(0));
  });

  test('different buckets allow new attempts', () {
    final guard = VoteIdempotencyGuard();
    final base = VoteOperationFingerprint(
      uid: 'u1',
      playerId: 'p1',
      matchId: 'm1',
      clubTag: 'zamalek',
      operationType: VoteOperationType.castVote,
      createdAtBucket: 1,
    );
    expect(guard.tryAcquire(base), isTrue);
    final nextBucket = VoteOperationFingerprint(
      uid: 'u1',
      playerId: 'p1',
      matchId: 'm1',
      clubTag: 'zamalek',
      operationType: VoteOperationType.castVote,
      createdAtBucket: 2,
    );
    expect(guard.tryAcquire(nextBucket), isTrue);
  });
}
