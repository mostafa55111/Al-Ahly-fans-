import 'package:flutter/foundation.dart';

/// مقاييس بقاء التشغيل — debug/profile فقط.
class FailureSurvivalRuntimeReport {
  FailureSurvivalRuntimeReport._();

  static final FailureSurvivalRuntimeReport instance =
      FailureSurvivalRuntimeReport._();

  int recoveredVoteIntents = 0;
  int staleSessionsBlocked = 0;
  int interruptedFinalizeRecovered = 0;
  int degradedRuntimeActivations = 0;
  int reconnectSuppressionCount = 0;
  int authorityFallbacks = 0;
  int pendingQueueDepth = 0;
  int duplicateRecoveryPrevented = 0;
  int lastReplayRecoveryMs = 0;

  void recordRecoveredVoteIntent() {
    recoveredVoteIntents++;
    _log('recovered_vote_intents=$recoveredVoteIntents');
  }

  void recordStaleSessionBlocked() {
    staleSessionsBlocked++;
    _log('stale_sessions_blocked=$staleSessionsBlocked');
  }

  void recordInterruptedFinalizeRecovered() {
    interruptedFinalizeRecovered++;
    _log('interrupted_finalize_recovered=$interruptedFinalizeRecovered');
  }

  void recordDegradedRuntime() {
    degradedRuntimeActivations++;
    _log('degraded_runtime=$degradedRuntimeActivations');
  }

  void recordReconnectSuppression() {
    reconnectSuppressionCount++;
    _log('reconnect_suppression=$reconnectSuppressionCount');
  }

  void recordAuthorityFallback() {
    authorityFallbacks++;
    _log('authority_fallbacks=$authorityFallbacks');
  }

  void recordQueueDepth(int depth) {
    pendingQueueDepth = depth;
    _log('pending_queue_depth=$depth');
  }

  void recordDuplicateRecoveryPrevented() {
    duplicateRecoveryPrevented++;
    _log('duplicate_recovery_prevented=$duplicateRecoveryPrevented');
  }

  void recordReplayRecoveryMs(int ms) {
    lastReplayRecoveryMs = ms;
    _log('replay_recovery_ms=$ms');
  }

  Map<String, dynamic> toJson() => {
        'recoveredVoteIntents': recoveredVoteIntents,
        'staleSessionsBlocked': staleSessionsBlocked,
        'interruptedFinalizeRecovered': interruptedFinalizeRecovered,
        'degradedRuntimeActivations': degradedRuntimeActivations,
        'reconnectSuppressionCount': reconnectSuppressionCount,
        'authorityFallbacks': authorityFallbacks,
        'pendingQueueDepth': pendingQueueDepth,
        'duplicateRecoveryPrevented': duplicateRecoveryPrevented,
        'lastReplayRecoveryMs': lastReplayRecoveryMs,
      };

  @visibleForTesting
  void reset() {
    recoveredVoteIntents = 0;
    staleSessionsBlocked = 0;
    interruptedFinalizeRecovered = 0;
    degradedRuntimeActivations = 0;
    reconnectSuppressionCount = 0;
    authorityFallbacks = 0;
    pendingQueueDepth = 0;
    duplicateRecoveryPrevented = 0;
    lastReplayRecoveryMs = 0;
  }

  void _log(String msg) {
    if (kDebugMode) {
      debugPrint('[FailureSurvival] $msg');
    }
  }
}
