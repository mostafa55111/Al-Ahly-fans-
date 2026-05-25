import 'package:flutter/foundation.dart';

/// مقاييس حتمية — debug/profile فقط، بدون spam في release.
class DeterministicRuntimeReport {
  DeterministicRuntimeReport._();

  static final DeterministicRuntimeReport instance =
      DeterministicRuntimeReport._();

  int duplicateVotePrevented = 0;
  int replayBlocked = 0;
  int finalizeRacePrevented = 0;
  int aggregationMismatch = 0;
  double lastShardImbalancePercent = 0;
  String lastAggregationChecksum = '';
  String lastChecksumDrift = '';

  void recordDuplicateVotePrevented() {
    duplicateVotePrevented++;
    _debugLog('duplicate_vote_prevented=$duplicateVotePrevented');
  }

  void recordReplayBlocked() {
    replayBlocked++;
    _debugLog('replay_blocked=$replayBlocked');
  }

  void recordFinalizeRacePrevented() {
    finalizeRacePrevented++;
    _debugLog('finalize_race_prevented=$finalizeRacePrevented');
  }

  void recordAggregationMismatch({String? detail}) {
    aggregationMismatch++;
    _debugLog('aggregation_mismatch=$aggregationMismatch detail=$detail');
  }

  void recordShardImbalance(double skewPercent) {
    lastShardImbalancePercent = skewPercent;
    _debugLog('shard_imbalance_pct=$skewPercent');
  }

  void recordAggregationChecksum(String checksum) {
    if (lastAggregationChecksum.isNotEmpty &&
        lastAggregationChecksum != checksum) {
      lastChecksumDrift = '$lastAggregationChecksum->$checksum';
      _debugLog('checksum_drift=$lastChecksumDrift');
    }
    lastAggregationChecksum = checksum;
  }

  Map<String, dynamic> toJson() => {
        'duplicateVotePrevented': duplicateVotePrevented,
        'replayBlocked': replayBlocked,
        'finalizeRacePrevented': finalizeRacePrevented,
        'aggregationMismatch': aggregationMismatch,
        'lastShardImbalancePercent': lastShardImbalancePercent,
        'lastAggregationChecksum': lastAggregationChecksum,
        'lastChecksumDrift': lastChecksumDrift,
      };

  @visibleForTesting
  void reset() {
    duplicateVotePrevented = 0;
    replayBlocked = 0;
    finalizeRacePrevented = 0;
    aggregationMismatch = 0;
    lastShardImbalancePercent = 0;
    lastAggregationChecksum = '';
    lastChecksumDrift = '';
  }

  void _debugLog(String msg) {
    if (kDebugMode) {
      debugPrint('[DeterministicRuntime] $msg');
    }
  }
}
