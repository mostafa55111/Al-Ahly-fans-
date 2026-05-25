import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/validation_finding.dart';

/// تدقيق إرهاق بصري — هدوء بعد 15+ دقيقة.
abstract final class VisualFatigueAudit {
  static ValidationReport audit({
    required BroadcastCalibrationSnapshot broadcast,
    CinematicAtmosphereSnapshot? cinematic,
  }) {
    final findings = <ValidationFinding>[];

    if (broadcast.density.glowVisibility > 0.92) {
      findings.add(const ValidationFinding(
        code: 'glow_fatigue',
        message: 'Glow visibility too high for long sessions',
        severity: ValidationSeverity.warn,
      ));
    }

    if (broadcast.density.atmosphereFxMul > 0.88 &&
        broadcast.phase != MatchNightPhase.winnerReveal) {
      findings.add(const ValidationFinding(
        code: 'fx_fatigue',
        message: 'Atmosphere FX may cause motion fatigue',
      ));
    }

    if (broadcast.readability.edgeHighlightMul > 1.02) {
      findings.add(const ValidationFinding(
        code: 'edge_aggression',
        message: 'Edge highlights aggressive for night use',
      ));
    }

    if (broadcast.motion.fadeMs < 200) {
      findings.add(const ValidationFinding(
        code: 'motion_snappy',
        message: 'Fade below calm threshold — prefer ≥200ms',
        severity: ValidationSeverity.info,
      ));
    }

    final cinematicFx = cinematic?.visibility.atmosphereFxMultiplier ?? 1.0;
    if (cinematicFx > 1.05) {
      findings.add(const ValidationFinding(
        code: 'cinematic_fx_stack',
        message: 'Cinematic FX multiplier competes with calm broadcast',
      ));
    }

    if (broadcast.density.overlayDominance > 0.82) {
      findings.add(const ValidationFinding(
        code: 'overlay_heavy',
        message: 'Overlay dominance may strain eyes in dark scenes',
      ));
    }

    final passed = !findings.any((f) => f.severity == ValidationSeverity.fail);
    return ValidationReport(
      domain: 'visual_fatigue',
      findings: findings,
      passed: passed,
    );
  }
}
