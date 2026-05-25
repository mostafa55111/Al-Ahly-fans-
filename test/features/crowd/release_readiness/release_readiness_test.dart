import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/human_validation_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/launch_freeze_enforcer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/real_matchday_rehearsal.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/production_config_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_candidate_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_go_live_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_performance_snapshot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_runtime_audit.dart';

void main() {
  group('LaunchFreezeEnforcer', () {
    test('blocks new features when freeze active', () {
      ProductionFeatureFreeze.instance.resetForTests(freeze: true, lock: true);
      final enforcer = LaunchFreezeEnforcer();
      final v = enforcer.evaluateChange(LaunchFreezeChangeKind.feature);
      expect(v.allowed, isFalse);
    });

    test('allows bug fixes when freeze active', () {
      ProductionFeatureFreeze.instance.resetForTests(freeze: true);
      final enforcer = LaunchFreezeEnforcer();
      final v = enforcer.evaluateChange(LaunchFreezeChangeKind.bugFix);
      expect(v.allowed, isTrue);
    });
  });

  group('HumanValidationSuite', () {
    test('state flow tracks validated items', () {
      final suite = HumanValidationSuite();
      suite.setStatus('fan_stadium_load', HumanValidationStatus.validated);
      suite.setStatus('fan_vote_live', HumanValidationStatus.failed);
      final report = suite.buildReport();
      expect(report.validatedCount, 1);
      expect(report.failedCount, 1);
      expect(report.readyForGoLive, isFalse);
    });
  });

  group('ReleaseRuntimeAudit', () {
    test('audit produces findings', () {
      final report = ReleaseRuntimeAudit().run();
      expect(report.findings, isNotEmpty);
    });
  });

  group('ReleasePerformanceSnapshot', () {
    test('flags slow first frame', () {
      final snap = ReleasePerformanceSnapshot();
      snap.record('first_frame', 2500);
      final metrics = snap.build();
      expect(metrics.first.withinTarget, isFalse);
    });

    test('accepts fast interaction', () {
      final snap = ReleasePerformanceSnapshot();
      snap.record('vote_tap', 80);
      expect(snap.allWithinTargets, isTrue);
    });
  });

  group('RealMatchdayRehearsal', () {
    test('tracks ordered steps', () {
      final rehearsal = RealMatchdayRehearsal();
      rehearsal.begin();
      for (final step in RealMatchdayRehearsal.orderedSteps) {
        rehearsal.recordStep(step: step, durationMs: 100);
      }
      final report = rehearsal.buildReport();
      expect(report.allStepsRecorded, isTrue);
      expect(report.ownerFlowSmooth, isTrue);
    });
  });

  group('ProductionConfigValidator', () {
    test('freeze_ready passes when freeze bootstrapped', () async {
      ProductionFeatureFreeze.instance.resetForTests();
      final report = await ProductionConfigValidator().validate(
        freeze: ProductionFeatureFreeze.instance,
        owners: null,
      );
      final freezeFinding = report.findings
          .firstWhere((f) => f.id == 'freeze_ready');
      expect(freezeFinding.passed, isTrue);
    });
  });

  group('ReleaseGoLiveGate', () {
    test('verdict labels', () {
      expect(
        ReleaseGoLiveGate.verdictLabelAr(ReleaseGoLiveVerdict.go),
        'GO',
      );
      expect(
        ReleaseGoLiveGate.verdictLabelAr(ReleaseGoLiveVerdict.noGo),
        'NO-GO',
      );
    });

    test('NO_GO when candidate has critical failure', () async {
      final gateReport = await ReleaseGoLiveGate().evaluate(
        candidate: const ReleaseCandidateValidationReport(
          verdict: ReleaseCandidateVerdict.noGo,
          checks: [
            ReleaseCandidateCheck(
              id: 'production_configs',
              passed: false,
              detail: 'owner_emails',
            ),
          ],
          goLiveScore: 40,
        ),
        human: const HumanValidationReport(
          items: [],
          validatedCount: 0,
          failedCount: 0,
          blockedCount: 0,
          pendingCount: 8,
          readyForGoLive: false,
        ),
      );
      expect(gateReport.verdict, ReleaseGoLiveVerdict.noGo);
      expect(gateReport.blockers, isNotEmpty);
    });
  });
}
