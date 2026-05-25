import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/validation_finding.dart';

/// تدقيق إحساس التفاعل — سريع، متماسك، موثوق.
abstract final class InteractionQualityAudit {
  static const int maxPressMs = 160;
  static const int maxFadeMs = 240;
  static const double minInteractionSoftness = 0.82;

  static ValidationReport audit({
    required BroadcastCalibrationSnapshot broadcast,
  }) {
    final findings = <ValidationFinding>[];
    final motion = broadcast.motion;

    if (motion.pressMs > maxPressMs) {
      findings.add(ValidationFinding(
        code: 'press_slow',
        message: 'Press feedback ${motion.pressMs}ms > $maxPressMs',
      ));
    }

    if (motion.fadeMs > maxFadeMs) {
      findings.add(const ValidationFinding(
        code: 'fade_slow',
        message: 'Fade exceeds broadcast cap — feels sluggish',
        severity: ValidationSeverity.fail,
      ));
    }

    if (motion.interactionSoftness < minInteractionSoftness) {
      findings.add(const ValidationFinding(
        code: 'interaction_harsh',
        message: 'Interaction softness too low on this device profile',
      ));
    }

    if (broadcast.density.cardProminence < 0.9) {
      findings.add(const ValidationFinding(
        code: 'card_tap_weak',
        message: 'Card prominence may reduce tap target confidence',
        severity: ValidationSeverity.info,
      ));
    }

    return ValidationReport(
      domain: 'interaction_quality',
      findings: findings,
      passed: !findings.any((f) => f.severity == ValidationSeverity.fail),
    );
  }
}
