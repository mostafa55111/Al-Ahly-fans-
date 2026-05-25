import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_surface_gate.dart';

/// مقاييس تشغيل المالك — داخلية فقط.
class OwnerOperationAnalytics {
  OwnerOperationAnalytics._();

  static final OwnerOperationAnalytics instance = OwnerOperationAnalytics._();

  int _launchPrepMs = 0;
  int _publishMs = 0;
  int _finalizeMs = 0;
  int _emergencyUsage = 0;
  int _retries = 0;
  int _recoveryOps = 0;

  void recordLaunchPreparation(int ms) {
    if (!SoftLaunchSurfaceGate.visible) return;
    _launchPrepMs = ms;
  }

  void recordPublishDuration(int ms) {
    if (!SoftLaunchSurfaceGate.visible) return;
    _publishMs = ms;
  }

  void recordFinalizeDuration(int ms) {
    if (!SoftLaunchSurfaceGate.visible) return;
    _finalizeMs = ms;
  }

  void recordEmergencyUsage() {
    if (!SoftLaunchSurfaceGate.visible) return;
    _emergencyUsage++;
  }

  void recordRetry() {
    if (!SoftLaunchSurfaceGate.visible) return;
    _retries++;
  }

  void recordRecoveryOperation() {
    if (!SoftLaunchSurfaceGate.visible) return;
    _recoveryOps++;
  }

  Map<String, dynamic> snapshot() => {
        'launchPreparationMs': _launchPrepMs,
        'sessionPublishMs': _publishMs,
        'finalizeMs': _finalizeMs,
        'emergencyUsage': _emergencyUsage,
        'retries': _retries,
        'recoveryOperations': _recoveryOps,
      };

  @visibleForTesting
  void resetForTests() {
    _launchPrepMs = 0;
    _publishMs = 0;
    _finalizeMs = 0;
    _emergencyUsage = 0;
    _retries = 0;
    _recoveryOps = 0;
  }
}
