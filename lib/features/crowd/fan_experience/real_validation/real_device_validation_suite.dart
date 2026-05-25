import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/interaction_quality_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/launch_freeze_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/production_surface_lock.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/real_user_focus_tracking.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/real_world_readability_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/render_stability_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/thermal_performance_monitor.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/validation_finding.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/visual_fatigue_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/visual_noise_detector.dart';

/// فئة جهاز للتحقق اليدوي/الآلي.
enum RealDeviceClass {
  compactPhone,
  tallPhone,
  mediumAndroid,
  flagshipAndroid,
  tablet,
  lowEndAndroid,
}

class RealDeviceValidationSuite {
  RealDeviceValidationSuite._();

  static final RealDeviceValidationSuite instance =
      RealDeviceValidationSuite._();

  static bool get diagnosticsEnabled =>
      !kReleaseMode && (kDebugMode || kProfileMode);

  ValidationReport? _lastReport;
  ValidationReport? get lastReport => _lastReport;

  bool _bootstrapped = false;
  bool get allPassed => _lastReport?.passed ?? true;

  void bootstrap() {
    if (!diagnosticsEnabled) return;
    if (_bootstrapped) return;
    _bootstrapped = true;
    ProductionSurfaceLock.instance.activateFanExperienceLock();
    LaunchFreezeGuard.instance.activate();
    debugPrint('[RealDeviceValidation] suite armed (debug/profile only)');
  }

  static RealDeviceClass classify(Size viewport) {
    final profile = BroadcastDeviceProfiles.resolve(viewport);
    return switch (profile) {
      BroadcastDeviceProfile.compactPhone => RealDeviceClass.compactPhone,
      BroadcastDeviceProfile.tallPhone => RealDeviceClass.tallPhone,
      BroadcastDeviceProfile.tablet => RealDeviceClass.tablet,
      BroadcastDeviceProfile.lowEndGpu => RealDeviceClass.lowEndAndroid,
    };
  }

  ValidationReport runFullAudit({
    required Size viewport,
    required BroadcastCalibrationSnapshot broadcast,
    CinematicAtmosphereSnapshot? cinematic,
  }) {
    ThermalPerformanceMonitor.instance.sample();

    final deviceClass = classify(viewport);
    final reports = <ValidationReport>[
      VisualFatigueAudit.audit(broadcast: broadcast, cinematic: cinematic),
      RealUserFocusTracking.audit(broadcast: broadcast, cinematic: cinematic),
      InteractionQualityAudit.audit(broadcast: broadcast),
      RealWorldReadabilityReport.audit(broadcast: broadcast),
      ThermalPerformanceMonitor.instance.audit(broadcast: broadcast),
      RenderStabilityAudit.audit(broadcast: broadcast, cinematic: cinematic),
      VisualNoiseDetector.audit(broadcast: broadcast, cinematic: cinematic),
    ];

    final merged = ValidationReport.merge('real_device_$deviceClass', reports);
    _lastReport = merged;
    return merged;
  }

  /// يُستدعى من assert() في المعاير — صفر تكلفة في release.
  void recordBroadcastSnapshot({
    required Size viewport,
    required BroadcastCalibrationSnapshot snapshot,
    CinematicAtmosphereSnapshot? cinematic,
  }) {
    if (!diagnosticsEnabled) return;
    _lastReport = runFullAudit(
      viewport: viewport,
      broadcast: snapshot,
      cinematic: cinematic,
    );
    if (!_lastReport!.passed && kDebugMode) {
      for (final f in _lastReport!.findings) {
        if (f.severity == ValidationSeverity.fail) {
          debugPrint('[RealDeviceValidation] FAIL ${f.code}: ${f.message}');
        }
      }
    }
  }

  /// بوابات منطقية للاختبارات — محاكاة أجهزة متعددة.
  Map<RealDeviceClass, bool> runReferenceDeviceMatrix({
    MatchNightPhase phase = MatchNightPhase.liveVoting,
  }) {
    final viewports = <RealDeviceClass, Size>{
      RealDeviceClass.compactPhone: const Size(340, 720),
      RealDeviceClass.tallPhone: const Size(412, 915),
      RealDeviceClass.mediumAndroid: const Size(393, 851),
      RealDeviceClass.flagshipAndroid: const Size(412, 892),
      RealDeviceClass.tablet: const Size(800, 1280),
      RealDeviceClass.lowEndAndroid: const Size(360, 640),
    };

    final results = <RealDeviceClass, bool>{};
    for (final entry in viewports.entries) {
      final broadcast = BroadcastCalibrationSnapshot.resolve(
        viewport: entry.value,
        phase: phase,
      );
      final report = runFullAudit(
        viewport: entry.value,
        broadcast: broadcast,
      );
      results[entry.key] = report.passed;
    }
    return results;
  }

  @visibleForTesting
  void resetForTests() {
    _bootstrapped = false;
    _lastReport = null;
  }
}
