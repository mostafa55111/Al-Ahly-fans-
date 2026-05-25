import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/validation_finding.dart';

/// تقرير قراءة العالم الحقيقي — شمس، ليل، شاشات صغيرة.
abstract final class RealWorldReadabilityReport {
  static ValidationReport audit({
    required BroadcastCalibrationSnapshot broadcast,
  }) {
    final findings = <ValidationFinding>[];
    final r = broadcast.readability;

    if (r.textContrastMul < 1.0) {
      findings.add(const ValidationFinding(
        code: 'text_contrast_low',
        message: 'Text contrast multiplier below baseline',
        severity: ValidationSeverity.fail,
      ));
    }

    if (r.scrimDarknessMul < 1.0) {
      findings.add(const ValidationFinding(
        code: 'scrim_weak',
        message: 'Bottom scrim may fail on bright card art',
      ));
    }

    if (r.sunlightBoost < 1.0) {
      findings.add(const ValidationFinding(
        code: 'sunlight_weak',
        message: 'Sunlight boost below 1.0',
        severity: ValidationSeverity.info,
      ));
    }

    if (broadcast.harmony.countdownBackdropAlpha < 0.72) {
      findings.add(const ValidationFinding(
        code: 'countdown_backdrop',
        message: 'Countdown backdrop too transparent outdoors',
        severity: ValidationSeverity.fail,
      ));
    }

    if (broadcast.device == BroadcastDeviceProfile.compactPhone &&
        broadcast.spacing.cardScaleMul > 1.0) {
      findings.add(const ValidationFinding(
        code: 'compact_typography_risk',
        message: 'Card scale >1 on compact may crowd name plates',
      ));
    }

    final scrimSample = r.calibratedScrim(0.82);
    if (scrimSample < 0.74) {
      findings.add(ValidationFinding(
        code: 'weak_scrim_zone',
        message: 'Calibrated scrim $scrimSample risks overlap readability',
      ));
    }

    return ValidationReport(
      domain: 'readability',
      findings: findings,
      passed: !findings.any((f) => f.severity == ValidationSeverity.fail),
    );
  }
}
