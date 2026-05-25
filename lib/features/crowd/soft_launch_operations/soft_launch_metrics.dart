import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_surface_gate.dart';

/// مقاييس الإطلاق الناعم — تشغيلية فقط، بدون لوحة analytics جماهيرية.
class SoftLaunchMetrics {
  SoftLaunchMetrics._();

  static final SoftLaunchMetrics instance = SoftLaunchMetrics._();

  int sessionOpens = 0;
  int successfulVotes = 0;
  int voteAttempts = 0;
  int finalizeSuccess = 0;
  int finalizeAttempts = 0;
  int reconnectCount = 0;
  int ownerRecoveryUsage = 0;
  int idleScreenExposure = 0;
  int totalSessionDurationMs = 0;

  double get voteCompletionRate =>
      voteAttempts == 0 ? 0 : successfulVotes / voteAttempts;

  double get finalizeSuccessRate =>
      finalizeAttempts == 0 ? 0 : finalizeSuccess / finalizeAttempts;

  double get avgSessionDurationMs =>
      sessionOpens == 0 ? 0 : totalSessionDurationMs / sessionOpens;

  void recordSessionOpen() {
    if (!SoftLaunchSurfaceGate.visible) return;
    sessionOpens++;
  }

  void recordVote({required bool success}) {
    if (!SoftLaunchSurfaceGate.visible) return;
    voteAttempts++;
    if (success) successfulVotes++;
  }

  void recordFinalize({required bool success}) {
    if (!SoftLaunchSurfaceGate.visible) return;
    finalizeAttempts++;
    if (success) finalizeSuccess++;
  }

  void recordReconnect() {
    if (!SoftLaunchSurfaceGate.visible) return;
    reconnectCount++;
  }

  void recordOwnerRecovery() {
    if (!SoftLaunchSurfaceGate.visible) return;
    ownerRecoveryUsage++;
  }

  void recordIdleExposure() {
    if (!SoftLaunchSurfaceGate.visible) return;
    idleScreenExposure++;
  }

  void recordSessionDuration(int ms) {
    if (!SoftLaunchSurfaceGate.visible) return;
    totalSessionDurationMs += ms;
  }

  Map<String, dynamic> snapshot() => {
        'sessionOpens': sessionOpens,
        'successfulVotes': successfulVotes,
        'voteCompletionRate': voteCompletionRate,
        'finalizeSuccessRate': finalizeSuccessRate,
        'reconnectCount': reconnectCount,
        'ownerRecoveryUsage': ownerRecoveryUsage,
        'idleScreenExposure': idleScreenExposure,
        'avgSessionDurationMs': avgSessionDurationMs,
      };

  @visibleForTesting
  void resetForTests() {
    sessionOpens = 0;
    successfulVotes = 0;
    voteAttempts = 0;
    finalizeSuccess = 0;
    finalizeAttempts = 0;
    reconnectCount = 0;
    ownerRecoveryUsage = 0;
    idleScreenExposure = 0;
    totalSessionDurationMs = 0;
  }
}
