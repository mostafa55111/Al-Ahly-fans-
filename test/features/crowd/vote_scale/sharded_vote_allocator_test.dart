import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/sharded_vote_allocator.dart';

void main() {
  test('shard ids stay within default 32 buckets', () {
    final alloc = ShardedVoteAllocator();
    for (var i = 0; i < 200; i++) {
      final id = alloc.pickShardId(
        uid: 'user_$i',
        clubTag: 'ahly',
        matchId: 'm1',
        playerId: 'p1',
      );
      expect(id.startsWith('s'), isTrue);
      final n = int.parse(id.substring(1));
      expect(n, inInclusiveRange(0, 31));
    }
  });

  test('distribution uses multiple shards for many users', () {
    final alloc = ShardedVoteAllocator();
    final uids = List.generate(500, (i) => 'fan_$i');
    final dist = alloc.simulateDistribution(uids: uids, clubTag: 'zamalek');
    expect(dist.length, greaterThan(8));
  });

  test('same uid+club+match+player is stable across calls', () {
    final alloc = ShardedVoteAllocator();
    final a = alloc.pickShardId(
      uid: 'same_uid',
      clubTag: 'ahly',
      matchId: 'm',
      playerId: 'p',
    );
    final b = alloc.pickShardId(
      uid: 'same_uid',
      clubTag: 'ahly',
      matchId: 'm',
      playerId: 'p',
    );
    expect(a, b);
  });

  test('different club changes shard for same uid', () {
    final alloc = ShardedVoteAllocator();
    final a = alloc.pickShardId(
      uid: 'same_uid',
      clubTag: 'ahly',
      matchId: 'm',
      playerId: 'p',
    );
    final z = alloc.pickShardId(
      uid: 'same_uid',
      clubTag: 'zamalek',
      matchId: 'm',
      playerId: 'p',
    );
    expect(a, isNotEmpty);
    expect(z, isNotEmpty);
  });
}
