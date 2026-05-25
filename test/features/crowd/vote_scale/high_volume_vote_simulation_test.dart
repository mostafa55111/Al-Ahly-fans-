import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/aggregation_determinism_verifier.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/deterministic_vote_allocator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/sharded_vote_allocator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_idempotency_guard.dart';

void main() {
  test('100k simulated votes: allocate + aggregate + idempotency', () {
    final alloc = ShardedVoteAllocator();
    const verifier = AggregationDeterminismVerifier();
    final guard = VoteIdempotencyGuard(maxEntries: 8192);

    final shardsByPlayer = <String, Map<String, int>>{};
    var duplicateBlocked = 0;
    final sw = Stopwatch()..start();

    for (var i = 0; i < 100000; i++) {
      final uid = 'fan_$i';
      final playerId = 'p${i % 11}';
      const matchId = 'sim_match';
      const club = 'ahly';

      final fp = VoteOperationFingerprint(
        uid: uid,
        playerId: playerId,
        matchId: matchId,
        clubTag: club,
        operationType: VoteOperationType.castVote,
        createdAtBucket: i ~/ 1000,
      );
      if (!guard.tryAcquire(fp)) {
        duplicateBlocked++;
        continue;
      }

      final shard = alloc.pickShardId(
        uid: uid,
        clubTag: club,
        matchId: matchId,
        playerId: playerId,
      );
      final playerShards = shardsByPlayer.putIfAbsent(playerId, () => {});
      playerShards[shard] = (playerShards[shard] ?? 0) + 1;
    }

    sw.stop();
    final report = verifier.verifyTwice(
      shardsByPlayer: shardsByPlayer,
      playerIds: List.generate(11, (i) => 'p$i'),
    );

    expect(report.deterministic, isTrue);
    expect(report.totalVotes, 100000);
    expect(duplicateBlocked, 0);
    expect(sw.elapsedMilliseconds, lessThan(45000));

    final votesPerMs = report.totalVotes / sw.elapsedMilliseconds;
    expect(votesPerMs, greaterThan(1));
  });

  test('replay attack: 10k identical operations blocked', () {
    final guard = VoteIdempotencyGuard();
    final fp = VoteOperationFingerprint(
      uid: 'attacker',
      playerId: 'p1',
      matchId: 'm1',
      clubTag: 'ahly',
      operationType: VoteOperationType.castVote,
      createdAtBucket: 1,
    );
    var ok = 0;
    for (var i = 0; i < 10000; i++) {
      if (guard.tryAcquire(fp)) ok++;
    }
    expect(ok, 1);
  });
}
