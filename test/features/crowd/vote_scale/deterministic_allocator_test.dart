import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/deterministic_vote_allocator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/sharded_vote_allocator.dart';

void main() {
  group('DeterministicVoteAllocator', () {
    test('same inputs always same shardId', () {
      const inputs = (
        club: 'ahly',
        match: 'm1',
        player: 'p9',
        uid: 'user_42',
      );
      final a = DeterministicVoteAllocator.allocate(
        clubTag: inputs.club,
        matchId: inputs.match,
        playerId: inputs.player,
        uid: inputs.uid,
      );
      final b = DeterministicVoteAllocator.allocate(
        clubTag: inputs.club,
        matchId: inputs.match,
        playerId: inputs.player,
        uid: inputs.uid,
      );
      expect(a.shardId, b.shardId);
      expect(a.hash, b.hash);
      expect(a.deterministicKey, 'ahly|m1|p9|user_42');
    });

    test('different playerId changes shard', () {
      final a = DeterministicVoteAllocator.allocate(
        clubTag: 'zamalek',
        matchId: 'derby',
        playerId: 'p1',
        uid: 'u1',
      );
      final b = DeterministicVoteAllocator.allocate(
        clubTag: 'zamalek',
        matchId: 'derby',
        playerId: 'p2',
        uid: 'u1',
      );
      expect(a.shardId, isNot(equals(b.shardId)));
    });

    test('shard index within bucket range', () {
      final alloc = ShardedVoteAllocator(shardCount: 32);
      for (var i = 0; i < 500; i++) {
        final id = alloc.pickShardId(
          uid: 'fan_$i',
          clubTag: 'ahly',
          matchId: 'match_x',
          playerId: 'player_y',
        );
        final n = int.parse(id.substring(1));
        expect(n, inInclusiveRange(0, 31));
      }
    });
  });
}
