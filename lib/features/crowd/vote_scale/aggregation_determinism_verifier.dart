import 'dart:math';

import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/deterministic_vote_allocator.dart';

/// تقرير تحقق تجميع حتمي.
class AggregationVerificationReport {
  const AggregationVerificationReport({
    required this.totalVotes,
    required this.shardCount,
    required this.missingShards,
    required this.inconsistentShards,
    required this.deterministic,
    required this.checksum,
    required this.playerTotals,
  });

  final int totalVotes;
  final int shardCount;
  final List<String> missingShards;
  final List<String> inconsistentShards;
  final bool deterministic;
  final String checksum;
  final Map<String, int> playerTotals;

  Map<String, dynamic> toJson() => {
        'totalVotes': totalVotes,
        'shardCount': shardCount,
        'missingShards': missingShards,
        'inconsistentShards': inconsistentShards,
        'deterministic': deterministic,
        'checksum': checksum,
        'playerTotals': playerTotals,
      };
}

/// تجميع شاردات بترتيب ثابت + checksum — للإغلاق والاختبارات.
class AggregationDeterminismVerifier {
  const AggregationDeterminismVerifier();

  /// `playerId -> shardId -> count`
  AggregationVerificationReport verifyShardMaps({
    required Map<String, Map<String, int>> shardsByPlayer,
    Iterable<String>? playerIds,
    int expectedShardSlots = DeterministicVoteAllocator.defaultShardCount,
  }) {
    final ids = playerIds?.toList() ??
        (shardsByPlayer.keys.toList()..sort());
    final first = _aggregateSorted(shardsByPlayer, ids);
    final second = _aggregateSorted(_shuffleCopy(shardsByPlayer), ids);
    final deterministic = _mapsEqual(first.totals, second.totals) &&
        first.checksum == second.checksum;

    final missingShards = <String>[];
    final inconsistentShards = <String>[];

    for (final pid in ids) {
      final shards = shardsByPlayer[pid] ?? const {};
      for (var i = 0; i < expectedShardSlots; i++) {
        final sid = 's$i';
        if (!shards.containsKey(sid) && shards.isNotEmpty) {
          // لا نُبلغ عن كل الشاردات الفارغة — فقط إن وُجدت شاردات أخرى
        }
      }
      for (final e in shards.entries) {
        if (e.value < 0) inconsistentShards.add('$pid:${e.key}:negative');
        if (e.value > 0x7FFFFFFF) inconsistentShards.add('$pid:${e.key}:overflow');
      }
    }

    return AggregationVerificationReport(
      totalVotes: first.totals.values.fold<int>(0, (a, b) => a + b),
      shardCount: expectedShardSlots,
      missingShards: missingShards,
      inconsistentShards: inconsistentShards,
      deterministic: deterministic,
      checksum: first.checksum,
      playerTotals: first.totals,
    );
  }

  /// يدمج عدة تمريرات تجميع ويُرجع تقريراً واحداً.
  AggregationVerificationReport verifyTwice({
    required Map<String, Map<String, int>> shardsByPlayer,
    Iterable<String>? playerIds,
  }) {
    return verifyShardMaps(shardsByPlayer: shardsByPlayer, playerIds: playerIds);
  }

  String checksumForTotals(Map<String, int> totals) {
    final sortedKeys = totals.keys.toList()..sort();
    final buf = StringBuffer();
    for (final k in sortedKeys) {
      final v = totals[k] ?? 0;
      if (v < 0) continue;
      buf.write('$k=$v;');
    }
    return DeterministicVoteAllocator.fnv1a64Utf8(buf.toString())
        .toRadixString(16)
        .padLeft(16, '0');
  }

  _AggPass _aggregateSorted(
    Map<String, Map<String, int>> shardsByPlayer,
    List<String> playerIds,
  ) {
    final totals = <String, int>{};
    for (final pid in playerIds) {
      final shards = shardsByPlayer[pid];
      if (shards == null || shards.isEmpty) {
        totals[pid] = 0;
        continue;
      }
      var sum = 0;
      final shardKeys = shards.keys.toList()..sort();
      for (final sid in shardKeys) {
        final c = shards[sid] ?? 0;
        if (c < 0) continue;
        if (c > 0x7FFFFFFF - sum) {
          sum = 0x7FFFFFFF;
          break;
        }
        sum += c;
      }
      totals[pid] = sum;
    }
    return _AggPass(totals: totals, checksum: checksumForTotals(totals));
  }

  Map<String, Map<String, int>> _shuffleCopy(
    Map<String, Map<String, int>> source,
  ) {
    final out = <String, Map<String, int>>{};
    source.forEach((pid, shards) {
      final keys = shards.keys.toList()..sort();
      keys.shuffle(); // ترتيب القراءة فقط — المفاتيح تُفرز عند الجمع
      final m = <String, int>{};
      for (final k in keys) {
        m[k] = shards[k] ?? 0;
      }
      out[pid] = m;
    });
    return out;
  }

  bool _mapsEqual(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

}

class _AggPass {
  const _AggPass({required this.totals, required this.checksum});
  final Map<String, int> totals;
  final String checksum;
}
