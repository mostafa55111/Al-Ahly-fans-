import 'package:flutter/foundation.dart';

/// مقاييس debug فقط — بدون analytics SDK.
class VoteScaleMetrics {
  VoteScaleMetrics._();

  static final VoteScaleMetrics instance = VoteScaleMetrics._();

  int shardWriteAttempts = 0;
  int shardWriteSuccess = 0;
  int shardWriteRollbacks = 0;
  int failedWrites = 0;
  int duplicateVoteRejections = 0;
  int duplicateFinalizeAttempts = 0;
  int finalizeSuccess = 0;
  int aggregationRuns = 0;
  Duration lastAggregationDuration = Duration.zero;
  Duration lastFinalizeDuration = Duration.zero;

  void recordShardWriteAttempt() => shardWriteAttempts++;

  void recordShardWriteSuccess() => shardWriteSuccess++;

  void recordShardWriteRollback() {
    shardWriteRollbacks++;
    debugPrint('[VoteScale] shard write rolled back');
  }

  void recordFailedWrite([Object? e]) {
    failedWrites++;
    debugPrint('[VoteScale] write failed: $e');
  }

  void recordDuplicateVote() {
    duplicateVoteRejections++;
    debugPrint('[VoteScale] duplicate vote rejected');
  }

  void recordDuplicateFinalize() {
    duplicateFinalizeAttempts++;
    debugPrint('[VoteScale] duplicate finalize attempt blocked');
  }

  void recordAggregation(Duration d) {
    aggregationRuns++;
    lastAggregationDuration = d;
    debugPrint('[VoteScale] aggregation ms=${d.inMilliseconds}');
  }

  void recordFinalize(Duration d, {required bool success}) {
    lastFinalizeDuration = d;
    if (success) {
      finalizeSuccess++;
      debugPrint('[VoteScale] finalize ok ms=${d.inMilliseconds}');
    } else {
      debugPrint('[VoteScale] finalize failed ms=${d.inMilliseconds}');
    }
  }

  @visibleForTesting
  void reset() {
    shardWriteAttempts = 0;
    shardWriteSuccess = 0;
    shardWriteRollbacks = 0;
    failedWrites = 0;
    duplicateVoteRejections = 0;
    duplicateFinalizeAttempts = 0;
    finalizeSuccess = 0;
    aggregationRuns = 0;
    lastAggregationDuration = Duration.zero;
    lastFinalizeDuration = Duration.zero;
  }
}
