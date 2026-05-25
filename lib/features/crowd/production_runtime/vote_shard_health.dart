import 'package:flutter/foundation.dart';

/// صحة شاردات التصويت — debug.
class VoteShardHealth {
  VoteShardHealth._();

  static final VoteShardHealth instance = VoteShardHealth._();

  int shardWrites = 0;
  int shardRollbacks = 0;
  int aggregationRuns = 0;

  void recordShardWrite() {
    if (!kDebugMode) return;
    shardWrites++;
  }

  void recordRollback() {
    if (!kDebugMode) return;
    shardRollbacks++;
  }

  void recordAggregation() {
    if (!kDebugMode) return;
    aggregationRuns++;
  }

  Map<String, int> snapshot() => {
        'shardWrites': shardWrites,
        'shardRollbacks': shardRollbacks,
        'aggregationRuns': aggregationRuns,
      };
}
