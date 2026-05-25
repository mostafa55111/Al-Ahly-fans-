import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/crash_signal_registry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/live_incident_tracker.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/production_rollout_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/reconnect_event_tracker.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/runtime_health_snapshot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/session_success_tracker.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_metrics.dart';

/// حكم توسيع الإطلاق.
enum ControlledRolloutVerdict {
  go,
  noGo,
  conditionalGo,
}

class ControlledRolloutGateReport {
  const ControlledRolloutGateReport({
    required this.verdict,
    required this.blockers,
    required this.warnings,
    required this.summaryAr,
  });

  final ControlledRolloutVerdict verdict;
  final List<String> blockers;
  final List<String> warnings;
  final String summaryAr;
}

/// بوابة قبل رفع نسبة الإطلاق.
class ControlledRolloutGate {
  ControlledRolloutGate({
    LiveIncidentTracker? incidents,
    CrashSignalRegistry? crashes,
    ReconnectEventTracker? reconnect,
    SoftLaunchMetrics? metrics,
    ProductionRolloutGuard? rolloutGuard,
  })  : _incidents = incidents ?? LiveIncidentTracker.instance,
        _crashes = crashes ?? CrashSignalRegistry.instance,
        _reconnect = reconnect ?? ReconnectEventTracker.instance,
        _metrics = metrics ?? SoftLaunchMetrics.instance,
        _rolloutGuard = rolloutGuard ?? ProductionRolloutGuard();

  final LiveIncidentTracker _incidents;
  final CrashSignalRegistry _crashes;
  final ReconnectEventTracker _reconnect;
  final SoftLaunchMetrics _metrics;
  final ProductionRolloutGuard _rolloutGuard;

  ControlledRolloutGateReport evaluate({
    SessionSuccessReport? lastSession,
  }) {
    final blockers = <String>[];
    final warnings = <String>[];

    if (_incidents.hasCriticalActive) {
      blockers.add('critical_incidents_active');
    }
    if (_incidents.hasHighReconnectStorm) {
      blockers.add('reconnect_storm');
    }
    if (_crashes.spikeDetected) {
      blockers.add('crash_spike');
    }

    final health = RuntimeHealthSnapshotBuilder().capture();
    if (health != null &&
        health.degradation.index >= RuntimeDegradationLevel.moderate.index) {
      blockers.add('runtime_degradation_${health.degradation.name}');
    }

    if (_metrics.finalizeSuccessRate < 0.85 && _metrics.finalizeAttempts >= 3) {
      blockers.add('finalize_instability');
    }

    if (_reconnect.snapshot().stormDetected) {
      blockers.add('reconnect_storm_metrics');
    }

    if (_metrics.ownerRecoveryUsage >= 5) {
      warnings.add('owner_recovery_high');
    }

    final rollout = _rolloutGuard.evaluate();
    if (rollout.verdict == ProductionRolloutVerdict.blocked) {
      blockers.add('rollout_guard_blocked');
    } else if (rollout.verdict == ProductionRolloutVerdict.conditional) {
      warnings.add('rollout_guard_conditional');
    }

    if (lastSession != null) {
      if (lastSession.verdict == SessionSuccessVerdict.failed) {
        blockers.add('last_session_failed');
      } else if (lastSession.verdict == SessionSuccessVerdict.partial) {
        warnings.add('last_session_partial');
      }
    }

    ControlledRolloutVerdict verdict;
    String summary;
    if (blockers.isNotEmpty) {
      verdict = ControlledRolloutVerdict.noGo;
      summary = 'لا توسيع — مخاطر تشغيلية نشطة';
    } else if (warnings.isNotEmpty) {
      verdict = ControlledRolloutVerdict.conditionalGo;
      summary = 'توسيع مشروط — راقب المؤشرات 24 ساعة';
    } else {
      verdict = ControlledRolloutVerdict.go;
      summary = 'جاهز لتوسيع النسبة — جلسات مستقرة';
    }

    return ControlledRolloutGateReport(
      verdict: verdict,
      blockers: blockers,
      warnings: warnings,
      summaryAr: summary,
    );
  }

  static String verdictLabelAr(ControlledRolloutVerdict v) => switch (v) {
        ControlledRolloutVerdict.go => 'GO',
        ControlledRolloutVerdict.conditionalGo => 'CONDITIONAL GO',
        ControlledRolloutVerdict.noGo => 'NO-GO',
      };
}
