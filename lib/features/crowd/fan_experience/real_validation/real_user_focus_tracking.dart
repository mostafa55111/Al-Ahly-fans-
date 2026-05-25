import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/validation_finding.dart';

/// تسلسل انتباه متوقع للمشجع.
class FocusHierarchyScore {
  const FocusHierarchyScore({
    required this.selectedCardClarity,
    required this.countdownClarity,
    required this.winnerDominance,
    required this.benchDistraction,
    required this.formationClarity,
  });

  final double selectedCardClarity;
  final double countdownClarity;
  final double winnerDominance;
  final double benchDistraction;
  final double formationClarity;

  bool hierarchyConfirmedFor(MatchNightPhase phase) {
    final countdownOk = phase == MatchNightPhase.winnerReveal ||
        phase == MatchNightPhase.hallOfFame ||
        countdownClarity >= 0.68;
    final formationMin = phase == MatchNightPhase.winnerReveal ? 0.68 : 0.75;
    return selectedCardClarity >= 0.85 &&
        countdownOk &&
        benchDistraction <= 0.85 &&
        formationClarity >= formationMin;
  }
}

/// تحليل أولوية النظرة — بدون تتبع حقيقي للعين (heuristic).
abstract final class RealUserFocusTracking {
  static FocusHierarchyScore score({
    required BroadcastCalibrationSnapshot broadcast,
    CinematicAtmosphereSnapshot? cinematic,
  }) {
    final focus = broadcast.focus;
    final selectedCardClarity = focus.selectedEmphasis *
        broadcast.density.cardProminence *
        broadcast.finish.premiumFeel;

    final countdownClarity = focus.countdownPriority *
        broadcast.harmony.countdownBackdropAlpha;

    var winnerDominance = focus.selectedEmphasis;
    if (broadcast.phase == MatchNightPhase.winnerReveal) {
      winnerDominance = (winnerDominance * 1.05).clamp(0.0, 1.2);
    }

    final benchDistraction = broadcast.density.benchAttention *
        focus.benchWeight;

    final formationClarity = focus.formationClarity *
        broadcast.spacing.formationSpreadMul.clamp(0.96, 1.04);

    return FocusHierarchyScore(
      selectedCardClarity: selectedCardClarity.clamp(0.0, 1.2),
      countdownClarity: countdownClarity.clamp(0.0, 1.2),
      winnerDominance: winnerDominance,
      benchDistraction: benchDistraction,
      formationClarity: formationClarity,
    );
  }

  static ValidationReport audit({
    required BroadcastCalibrationSnapshot broadcast,
    CinematicAtmosphereSnapshot? cinematic,
  }) {
    final s = score(broadcast: broadcast, cinematic: cinematic);
    final findings = <ValidationFinding>[];

    if (s.selectedCardClarity < 0.82) {
      findings.add(ValidationFinding(
        code: 'selected_card_weak',
        message:
            'Selected card clarity ${s.selectedCardClarity.toStringAsFixed(2)} < 0.82',
        severity: ValidationSeverity.fail,
      ));
    }

    final needsCountdown = broadcast.phase == MatchNightPhase.liveVoting ||
        broadcast.phase == MatchNightPhase.closingSoon ||
        broadcast.phase == MatchNightPhase.finalizing;
    if (needsCountdown && s.countdownClarity < 0.70) {
      findings.add(ValidationFinding(
        code: 'countdown_weak',
        message: 'Countdown priority too low for live phases',
        severity: ValidationSeverity.fail,
      ));
    }

    if (broadcast.phase == MatchNightPhase.winnerReveal &&
        s.winnerDominance < 0.9) {
      findings.add(const ValidationFinding(
        code: 'winner_not_dominant',
        message: 'Winner reveal should dominate attention',
        severity: ValidationSeverity.fail,
      ));
    }

    if (s.benchDistraction > 0.88 &&
        broadcast.phase != MatchNightPhase.hallOfFame) {
      findings.add(const ValidationFinding(
        code: 'bench_distracting',
        message: 'Bench rail competes with pitch focus',
      ));
    }

    if (!s.hierarchyConfirmedFor(broadcast.phase) && findings.isEmpty) {
      findings.add(const ValidationFinding(
        code: 'hierarchy_marginal',
        message: 'Attention hierarchy marginal — review calibration',
        severity: ValidationSeverity.info,
      ));
    }

    return ValidationReport(
      domain: 'focus_tracking',
      findings: findings,
      passed: !findings.any((f) => f.severity == ValidationSeverity.fail),
    );
  }
}
