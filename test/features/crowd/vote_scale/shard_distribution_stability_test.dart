import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/shard_distribution_analyzer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/deterministic_vote_allocator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/sharded_vote_allocator.dart';

void main() {
  test('same uid always maps to same shard (deterministic)', () {
    final alloc = ShardedVoteAllocator();
    const uid = 'stable_fan_99';
    final a = alloc.pickShardId(
      uid: uid,
      clubTag: 'ahly',
      matchId: 'm1',
      playerId: 'p1',
    );
    final b = alloc.pickShardId(
      uid: uid,
      clubTag: 'ahly',
      matchId: 'm1',
      playerId: 'p1',
    );
    expect(a, b);
  });

  test('100k simulated allocations stay within 32 shards', () {
    final alloc = ShardedVoteAllocator();
    final seen = <String>{};
    for (var i = 0; i < 100000; i++) {
      seen.add(
        alloc.pickShardId(
          uid: 'u_$i',
          clubTag: 'zamalek',
          matchId: 'derby_2026',
          playerId: 'player_${i % 11}',
        ),
      );
    }
    expect(seen.length, greaterThan(8));
    for (final id in seen) {
      final n = int.parse(id.substring(1));
      expect(n, inInclusiveRange(0, 31));
    }
  });

  test('distribution analyzer reports fairness for 10k uids', () {
    final uids = List.generate(10000, (i) => 'fan_$i');
    final report = ShardDistributionAnalyzer().analyze(
      uids: uids,
      clubTag: 'ahly',
      allocator: ShardedVoteAllocator(),
    );
    expect(report.sampleSize, 10000);
    expect(report.skewPercent, lessThan(80));
    expect(report.shardCounts.length, greaterThan(16));
  });

  test('checksum of allocation keys is stable', () {
    final keys = <String>[];
    for (var i = 0; i < 1000; i++) {
      keys.add(
        DeterministicVoteAllocator.allocate(
          clubTag: 'ahly',
          matchId: 'm',
          playerId: 'p',
          uid: 'u$i',
        ).deterministicKey,
      );
    }
    keys.sort();
    final checksum1 = DeterministicVoteAllocator.fnv1a64Utf8(keys.join(','));
    keys.shuffle();
    keys.sort();
    final checksum2 = DeterministicVoteAllocator.fnv1a64Utf8(keys.join(','));
    expect(checksum1, checksum2);
  });
}
