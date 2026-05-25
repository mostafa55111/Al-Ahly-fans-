import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/validation_finding.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/device_pressure_classifier.dart';

/// مراقبة ضغط حراري/GPU — إشارات فقط، بدون sensors إضافية.
class ThermalPerformanceMonitor {
  ThermalPerformanceMonitor._();

  static final ThermalPerformanceMonitor instance = ThermalPerformanceMonitor._();

  int _thermalWarnings = 0;
  DevicePressureTier _lastTier = DevicePressureTier.medium;

  DevicePressureTier get lastTier => _lastTier;
  int get thermalWarnings => _thermalWarnings;

  @visibleForTesting
  void reset() {
    _thermalWarnings = 0;
    _lastTier = DevicePressureTier.medium;
  }

  void sample() {
    if (!_diagnosticsEnabled) return;
    _lastTier = DevicePressureClassifier.instance.currentTier;
    if (_lastTier == DevicePressureTier.lowEnd) {
      _thermalWarnings++;
    }
  }

  static bool get _diagnosticsEnabled =>
      !kReleaseMode && (kDebugMode || kProfileMode);

  ValidationReport audit({
    required BroadcastCalibrationSnapshot broadcast,
  }) {
    final findings = <ValidationFinding>[];
    final tier = DevicePressureClassifier.instance.currentTier;

    if (broadcast.device == BroadcastDeviceProfile.lowEndGpu &&
        broadcast.density.atmosphereFxMul > 0.78) {
      findings.add(const ValidationFinding(
        code: 'thermal_fx_high',
        message: 'FX density high for low-end GPU tier',
        severity: ValidationSeverity.fail,
      ));
    }

    if (broadcast.density.glowVisibility > 0.9 &&
        tier != DevicePressureTier.highEnd) {
      findings.add(const ValidationFinding(
        code: 'thermal_glow',
        message: 'Glow may elevate GPU work on non-flagship devices',
      ));
    }

    if (_thermalWarnings > 8) {
      findings.add(ValidationFinding(
        code: 'thermal_escalation',
        message: 'Thermal warnings=$_thermalWarnings — reduce FX',
        severity: ValidationSeverity.warn,
      ));
    }

    return ValidationReport(
      domain: 'thermal',
      findings: findings,
      passed: !findings.any((f) => f.severity == ValidationSeverity.fail),
    );
  }
}
