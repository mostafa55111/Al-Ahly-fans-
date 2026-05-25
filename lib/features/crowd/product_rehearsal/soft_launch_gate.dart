import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_stability_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/operational_complexity_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/owner_security_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/cold_start_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/firebase_production_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/launch_day_chaos_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/match_day_simulation_runner.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/production_recovery_drill.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/release_build_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/rehearsal_surface_gate.dart';

enum SoftLaunchDecision {
  go,
  noGo,
  conditionalGo,
}

class SoftLaunchGateResult {
  const SoftLaunchGateResult({
    required this.decision,
    required this.blockers,
    required this.checks,
  });

  final SoftLaunchDecision decision;
  final List<String> blockers;
  final Map<String, bool> checks;
}

/// بوابة الإطلاق الناعم — تجمع كل تدقيقات Phases D–G.
class SoftLaunchGate {
  SoftLaunchGate._();

  static final SoftLaunchGate instance = SoftLaunchGate._();

  SoftLaunchGateResult evaluate({
    bool requireFreezeEnabled = false,
  }) {
    final checks = <String, bool>{};
    final blockers = <String>[];

    checks['rehearsal_allowed'] = RehearsalSurfaceGate.allowDressRehearsal;

    checks['freeze_ready'] = ProductionFeatureFreeze.instance.isReady;
    if (requireFreezeEnabled &&
        !ProductionFeatureFreeze.instance.featureFreeze) {
      blockers.add('crowd_feature_freeze_not_enabled');
      checks['freeze_enabled'] = false;
    } else {
      checks['freeze_enabled'] = !requireFreezeEnabled ||
          ProductionFeatureFreeze.instance.featureFreeze;
    }

    checks['experimental_disabled'] =
        ProductionFeatureFreeze.instance.disableExperimental;

    ReleaseBuildAudit.instance.run();
    checks['release_audit_green'] =
        ReleaseBuildAudit.instance.green || !ReleaseModeGuard.isStrictRelease;

    checks['runtime_complexity_safe'] =
        OperationalComplexityReport.instance.classifyActiveServices() !=
            OperationalComplexityTier.overcomplex;

    checks['owner_security'] = OwnerSecurityAudit.instance.passedReleaseChecks;

    checks['launch_stability'] = LaunchStabilitySuite.instance.allPassed;

    checks['firebase_acceptable'] =
        FirebaseProductionAudit.instance.evaluate() !=
            FirebaseAuditVerdict.critical;

    final rehearsal = RehearsalSurfaceGate.allowDressRehearsal;
    checks['cold_start_acceptable'] = !rehearsal ||
        ColdStartAudit.instance.allAcceptable;

    checks['matchday_sim_ok'] =
        !rehearsal || MatchDaySimulationRunner.instance.allPassed;

    checks['chaos_ok'] =
        !rehearsal || LaunchDayChaosSuite.instance.allPassed;

    checks['recovery_drills_ok'] =
        !rehearsal || ProductionRecoveryDrill.instance.allPassed;

    for (final e in checks.entries) {
      if (!e.value && e.key != 'rehearsal_allowed') {
        blockers.add(e.key);
      }
    }

    final SoftLaunchDecision decision;
    if (blockers.isEmpty) {
      decision = SoftLaunchDecision.go;
    } else if (blockers.length <= 2 && checks['launch_stability'] == true) {
      decision = SoftLaunchDecision.conditionalGo;
    } else {
      decision = SoftLaunchDecision.noGo;
    }

    if (kDebugMode) {
      debugPrint('[SoftLaunchGate] decision=$decision blockers=$blockers');
    }

    return SoftLaunchGateResult(
      decision: decision,
      blockers: blockers,
      checks: checks,
    );
  }

  Future<SoftLaunchGateResult> evaluateWithRehearsal({
    bool runSimulations = true,
    bool requireFreezeEnabled = false,
  }) async {
    if (runSimulations && RehearsalSurfaceGate.allowDressRehearsal) {
      await MatchDaySimulationRunner.instance.runFullMatchDay();
      await LaunchDayChaosSuite.instance.runAll();
      await ProductionRecoveryDrill.instance.runAll();
    }
    return evaluate(requireFreezeEnabled: requireFreezeEnabled);
  }

  Map<String, dynamic> fullSnapshot() => {
        'gate': evaluate().checks,
        'matchday': MatchDaySimulationRunner.instance.snapshot(),
        'coldStart': ColdStartAudit.instance.snapshot(),
        'chaos': LaunchDayChaosSuite.instance.snapshot(),
        'recovery': ProductionRecoveryDrill.instance.snapshot(),
        'release': ReleaseBuildAudit.instance.snapshot(),
        'firebase': FirebaseProductionAudit.instance.snapshot(),
      };
}
