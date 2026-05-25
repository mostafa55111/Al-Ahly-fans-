import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/reconnect_storm_metrics.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_health_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/media_pressure_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_report.dart';

/// لقطة مراقبة داخلية — debug/profile فقط.
class ReleaseObservabilitySnapshot {
  const ReleaseObservabilitySnapshot({
    required this.runtimeRecoveries,
    required this.reconnectPressure,
    required this.finalizeRetries,
    required this.uploadFailures,
    required this.mediaPressure,
    required this.thermalPressure,
    required this.restoreEvents,
  });

  final int runtimeRecoveries;
  final double reconnectPressure;
  final int finalizeRetries;
  final int uploadFailures;
  final int mediaPressure;
  final int thermalPressure;
  final int restoreEvents;
}

/// تجميع مؤشرات التشغيل — بدون واجهة analytics للمستخدم.
class ReleaseObservabilityReport {
  ReleaseObservabilityReport();

  ReleaseObservabilitySnapshot? capture() {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) {
      return null;
    }
    final survival = FailureSurvivalRuntimeReport.instance;
    final reconnect = ReconnectStormReport.instance;
    final health = RuntimeHealthReport.instance;
    final media = MediaPressureReport.instance;
    final storm = ReconnectStormMetrics.instance;

    return ReleaseObservabilitySnapshot(
      runtimeRecoveries: survival.interruptedFinalizeRecovered,
      reconnectPressure: reconnect.stabilizationRate,
      finalizeRetries: health.finalizeAttempts - health.finalizeSuccess,
      uploadFailures: 0,
      mediaPressure: media.decodeSlowFrames,
      thermalPressure: storm.deferredHeavySkips,
      restoreEvents: survival.duplicateRecoveryPrevented,
    );
  }

  Map<String, dynamic> toJson(ReleaseObservabilitySnapshot snap) => {
        'runtimeRecoveries': snap.runtimeRecoveries,
        'reconnectPressure': snap.reconnectPressure,
        'finalizeRetries': snap.finalizeRetries,
        'uploadFailures': snap.uploadFailures,
        'mediaPressure': snap.mediaPressure,
        'thermalPressure': snap.thermalPressure,
        'restoreEvents': snap.restoreEvents,
      };

  void logSnapshot(ReleaseObservabilitySnapshot snap) {
    if (!kDebugMode) return;
    debugPrint('[ReleaseObservability] ${toJson(snap)}');
  }
}
