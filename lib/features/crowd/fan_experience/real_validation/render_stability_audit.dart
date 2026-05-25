import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/validation_finding.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/device_pressure_classifier.dart';

/// تدقيق استقرار الرسم — opacity stacking وإعادة البناء.
abstract final class RenderStabilityAudit {
  static const int maxOpacityLayers = 3;

  static ValidationReport audit({
    required BroadcastCalibrationSnapshot broadcast,
    CinematicAtmosphereSnapshot? cinematic,
  }) {
    final findings = <ValidationFinding>[];

    var opacityLayers = 1;
    if (broadcast.density.atmosphereFxMul < 1.0) opacityLayers++;
    if (broadcast.finish.visualNoiseCap < 1.0) opacityLayers++;
    if (cinematic != null && cinematic.visibility.showStadiumFxEngine) {
      opacityLayers++;
    }
    if (cinematic != null && cinematic.visibility.showCrowdAtmosphereFx) {
      opacityLayers++;
    }

    if (opacityLayers > maxOpacityLayers + 1) {
      findings.add(ValidationFinding(
        code: 'opacity_stack',
        message: 'Estimated opacity layers=$opacityLayers — risk frame drops',
        severity: ValidationSeverity.warn,
      ));
    }

    if (DevicePressureClassifier.instance.currentTier ==
            DevicePressureTier.lowEnd &&
        cinematic?.visibility.allowCardBreathing == true) {
      findings.add(const ValidationFinding(
        code: 'breathing_low_end',
        message: 'Card breathing on low-end may cause jank',
      ));
    }

    if (broadcast.motion.breathCycleMs < 4000) {
      findings.add(const ValidationFinding(
        code: 'breath_fast',
        message: 'Breath cycle fast — unnecessary repaint churn',
        severity: ValidationSeverity.info,
      ));
    }

    return ValidationReport(
      domain: 'render_stability',
      findings: findings,
      passed: !findings.any((f) => f.severity == ValidationSeverity.fail),
    );
  }
}
