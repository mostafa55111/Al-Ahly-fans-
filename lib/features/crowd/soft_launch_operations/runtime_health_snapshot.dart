import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_health_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/reconnect_event_tracker.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_surface_gate.dart';

/// مستوى تدهور التشغيل.
enum RuntimeDegradationLevel {
  none,
  mild,
  moderate,
  severe,
}

class RuntimeHealthSnapshot {
  const RuntimeHealthSnapshot({
    required this.activeListenersEstimate,
    required this.reconnectPressure,
    required this.hydrationPressure,
    required this.finalizeState,
    required this.recoveryState,
    required this.degradation,
  });

  final int activeListenersEstimate;
  final double reconnectPressure;
  final int hydrationPressure;
  final String finalizeState;
  final String recoveryState;
  final RuntimeDegradationLevel degradation;
}

/// لقطة صحة التشغيل — تجميع من مسارات موجودة.
class RuntimeHealthSnapshotBuilder {
  RuntimeHealthSnapshot? capture() {
    if (!SoftLaunchSurfaceGate.visible) return null;

    final health = RuntimeHealthReport.instance;
    final reconnect = ReconnectEventTracker.instance.snapshot();
    final storm = ReconnectStormReport.instance;
    final survival = FailureSurvivalRuntimeReport.instance;

    var finalizeState = 'idle';
    if (health.finalizeAttempts > 0 &&
        health.finalizeSuccess >= health.finalizeAttempts) {
      finalizeState = 'complete';
    } else if (health.finalizeAttempts > health.finalizeSuccess) {
      finalizeState = 'in_flight_or_retry';
    } else if (health.finalizeAttempts > 0) {
      finalizeState = 'attempted';
    }

    final recoveryState = survival.interruptedFinalizeRecovered > 0
        ? 'recovery_active'
        : 'stable';

    final degradation = _classify(
      reconnectPressure: 1.0 - storm.stabilizationRate,
      hydrationPressure: reconnect.repeatedHydrationAttempts,
      finalizeFailures: health.finalizeAttempts - health.finalizeSuccess,
    );

    return RuntimeHealthSnapshot(
      activeListenersEstimate: health.recoveryQueueDepth,
      reconnectPressure: 1.0 - storm.stabilizationRate,
      hydrationPressure: reconnect.repeatedHydrationAttempts,
      finalizeState: finalizeState,
      recoveryState: recoveryState,
      degradation: degradation,
    );
  }

  RuntimeDegradationLevel _classify({
    required double reconnectPressure,
    required int hydrationPressure,
    required int finalizeFailures,
  }) {
    if (finalizeFailures >= 3 || reconnectPressure > 0.7) {
      return RuntimeDegradationLevel.severe;
    }
    if (finalizeFailures >= 1 || reconnectPressure > 0.4) {
      return RuntimeDegradationLevel.moderate;
    }
    if (hydrationPressure > 10 || reconnectPressure > 0.2) {
      return RuntimeDegradationLevel.mild;
    }
    return RuntimeDegradationLevel.none;
  }
}
