import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/validation_finding.dart';

/// كشف الضوضاء البصرية — توهج، تركيز متنافس، ازدحام.
abstract final class VisualNoiseDetector {
  static ValidationReport audit({
    required BroadcastCalibrationSnapshot broadcast,
    CinematicAtmosphereSnapshot? cinematic,
  }) {
    final findings = <ValidationFinding>[];

    if (broadcast.density.glowVisibility > 0.88 &&
        broadcast.focus.competingHighlightReduction > 0.78) {
      findings.add(const ValidationFinding(
        code: 'glow_highlight_stack',
        message: 'Glow + competing highlights — attention competition',
      ));
    }

    if (broadcast.density.cardProminence > 1.06 &&
        broadcast.density.atmosphereFxMul > 0.86) {
      findings.add(const ValidationFinding(
        code: 'card_fx_clutter',
        message: 'Cards and atmosphere both loud',
      ));
    }

    if (broadcast.spacing.horizontalGapMul < 0.93 ||
        broadcast.spacing.verticalGapMul < 0.93) {
      findings.add(const ValidationFinding(
        code: 'spacing_cramped',
        message: 'Formation spacing cramped — visual clutter risk',
      ));
    }

    final cinematicPulse = cinematic?.visibility.showCollectivePulse ?? false;
    final cinematicFx = cinematic?.visibility.showStadiumFxEngine ?? false;
    if (cinematicPulse && cinematicFx && broadcast.density.atmosphereFxMul > 0.7) {
      findings.add(const ValidationFinding(
        code: 'fx_triple_stack',
        message: 'Pulse + stadium FX + broadcast FX stacked',
        severity: ValidationSeverity.fail,
      ));
    }

    if (broadcast.finish.visualNoiseCap > 0.95) {
      findings.add(const ValidationFinding(
        code: 'noise_cap_high',
        message: 'Finish noise cap allows too much atmosphere',
        severity: ValidationSeverity.info,
      ));
    }

    return ValidationReport(
      domain: 'visual_noise',
      findings: findings,
      passed: !findings.any((f) => f.severity == ValidationSeverity.fail),
    );
  }
}
