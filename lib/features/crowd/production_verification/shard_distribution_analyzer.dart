import 'dart:math';

import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/deterministic_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/sharded_vote_allocator.dart';

class ShardDistributionReport {
  const ShardDistributionReport({
    required this.shardCounts,
    required this.entropyBits,
    required this.skewPercent,
    required this.hotShardId,
    required this.coldShardId,
    required this.sampleSize,
  });

  final Map<String, int> shardCounts;
  final double entropyBits;
  final double skewPercent;
  final String hotShardId;
  final String coldShardId;
  final int sampleSize;

  bool get isHealthy => skewPercent < 35 && entropyBits > 3.5;

  Map<String, dynamic> toJson() => {
        'sampleSize': sampleSize,
        'entropyBits': entropyBits,
        'skewPercent': skewPercent,
        'hotShardId': hotShardId,
        'coldShardId': coldShardId,
        'isHealthy': isHealthy,
        'topShards': _topShards(5),
      };

  List<MapEntry<String, int>> _topShards(int n) {
    final sorted = shardCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }
}

class ShardDistributionAnalyzer {
  double computeEntropy(Map<String, int> counts) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return 0;
    var entropy = 0.0;
    for (final c in counts.values) {
      if (c <= 0) continue;
      final p = c / total;
      entropy -= p * (log(p) / ln2);
    }
    return entropy;
  }

  ShardDistributionReport analyze({
    required Iterable<String> uids,
    required String clubTag,
    ShardedVoteAllocator? allocator,
  }) {
    final alloc = allocator ?? ShardedVoteAllocator();
    final counts = alloc.simulateDistribution(uids: uids, clubTag: clubTag);
    final sample = counts.values.fold<int>(0, (a, b) => a + b);
    if (counts.isEmpty) {
      return const ShardDistributionReport(
        shardCounts: {},
        entropyBits: 0,
        skewPercent: 0,
        hotShardId: '',
        coldShardId: '',
        sampleSize: 0,
      );
    }

    final maxEntry = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final minEntry = counts.entries.reduce((a, b) => a.value <= b.value ? a : b);
    final expected = sample / counts.length;
    final skew = expected <= 0
        ? 0.0
        : ((maxEntry.value - expected) / expected) * 100;

    DeterministicRuntimeReport.instance.recordShardImbalance(skew);

    return ShardDistributionReport(
      shardCounts: counts,
      entropyBits: computeEntropy(counts),
      skewPercent: skew,
      hotShardId: maxEntry.key,
      coldShardId: minEntry.key,
      sampleSize: sample,
    );
  }
}
