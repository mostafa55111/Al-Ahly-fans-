import 'package:flutter/foundation.dart';

/// تقرير صحة تشغيل — debug فقط.
class RuntimeHealthReport {
  RuntimeHealthReport._();

  static final RuntimeHealthReport instance = RuntimeHealthReport._();

  String authorityMode = 'local_client_authority';
  int abuseBlocks = 0;
  int finalizeAttempts = 0;
  int finalizeSuccess = 0;
  int recoveryQueueDepth = 0;
  int deadSessionRecoveries = 0;

  void recordAuthorityMode(String mode) {
    if (!kDebugMode) return;
    authorityMode = mode;
  }

  void recordAbuseBlock(String reason) {
    if (!kDebugMode) return;
    abuseBlocks++;
    debugPrint('[RuntimeHealth] abuse_block=$reason total=$abuseBlocks');
  }

  void recordFinalizeAttempt({required bool success}) {
    if (!kDebugMode) return;
    finalizeAttempts++;
    if (success) finalizeSuccess++;
  }

  void recordRecoveryQueueDepth(int depth) {
    if (!kDebugMode) return;
    recoveryQueueDepth = depth;
  }

  void recordDeadSessionRecovery() {
    if (!kDebugMode) return;
    deadSessionRecoveries++;
  }

  Map<String, dynamic> snapshot() {
    if (!kDebugMode) return const {};
    return {
      'authorityMode': authorityMode,
      'abuseBlocks': abuseBlocks,
      'finalizeAttempts': finalizeAttempts,
      'finalizeSuccess': finalizeSuccess,
      'recoveryQueueDepth': recoveryQueueDepth,
      'deadSessionRecoveries': deadSessionRecoveries,
    };
  }

  @visibleForTesting
  void reset() {
    authorityMode = 'local_client_authority';
    abuseBlocks = 0;
    finalizeAttempts = 0;
    finalizeSuccess = 0;
    recoveryQueueDepth = 0;
    deadSessionRecoveries = 0;
  }
}
