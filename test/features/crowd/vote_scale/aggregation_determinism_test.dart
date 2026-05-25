import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/aggregation_determinism_verifier.dart';

void main() {
  const verifier = AggregationDeterminismVerifier();

  test('read order does not change totals or checksum', () {
    final data = <String, Map<String, int>>{
      'p1': {'s3': 100, 's1': 50, 's7': 25},
      'p2': {'s0': 200, 's2': 10},
    };
    final report = verifier.verifyTwice(
      shardsByPlayer: data,
      playerIds: ['p1', 'p2'],
    );
    expect(report.deterministic, isTrue);
    expect(report.playerTotals['p1'], 175);
    expect(report.playerTotals['p2'], 210);
    expect(report.totalVotes, 385);
    expect(report.checksum, isNotEmpty);
  });

  test('same dataset yields identical checksum across runs', () {
    final data = <String, Map<String, int>>{
      'a': {'s1': 1, 's2': 2},
      'b': {'s1': 9},
    };
    final r1 = verifier.verifyTwice(shardsByPlayer: data);
    final r2 = verifier.verifyTwice(shardsByPlayer: data);
    expect(r1.checksum, r2.checksum);
    expect(r1.playerTotals, r2.playerTotals);
  });

  test('rejects negative counts in inconsistent list', () {
    final report = verifier.verifyShardMaps(
      shardsByPlayer: {
        'p1': {'s0': -1},
      },
    );
    expect(report.inconsistentShards, isNotEmpty);
  });
}
