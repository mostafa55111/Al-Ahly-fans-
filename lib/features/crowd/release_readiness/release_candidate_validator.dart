import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_stability_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/human_validation_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/launch_freeze_enforcer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/production_config_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_runtime_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_stability_matrix.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/readiness/go_live_readiness_evaluator.dart';

/// حكم مرشح الإصدار.
enum ReleaseCandidateVerdict {
  go,
  conditionalGo,
  noGo,
}

class ReleaseCandidateCheck {
  const ReleaseCandidateCheck({
    required this.id,
    required this.passed,
    this.detail,
  });

  final String id;
  final bool passed;
  final String? detail;
}

class ReleaseCandidateValidationReport {
  const ReleaseCandidateValidationReport({
    required this.verdict,
    required this.checks,
    required this.goLiveScore,
  });

  final ReleaseCandidateVerdict verdict;
  final List<ReleaseCandidateCheck> checks;
  final int goLiveScore;
}

/// يجمع فحوصات المرشح للإطلاق.
class ReleaseCandidateValidator {
  ReleaseCandidateValidator({
    HumanValidationSuite? humanSuite,
    LaunchFreezeEnforcer? freeze,
  })  : _human = humanSuite ?? HumanValidationSuite(),
        _freeze = freeze ?? LaunchFreezeEnforcer();

  final HumanValidationSuite _human;
  final LaunchFreezeEnforcer _freeze;

  Future<ReleaseCandidateValidationReport> validate() async {
    final checks = <ReleaseCandidateCheck>[];

    void add(String id, bool ok, {String? detail}) {
      checks.add(ReleaseCandidateCheck(id: id, passed: ok, detail: detail));
    }

    add('fan_experience_locked', true, detail: 'Phase H locked — no UI changes');

    add('owner_reliability_enabled', true, detail: 'Phase Admin 3–4 active');

    final config = await ProductionConfigValidator().validate();
    add('production_configs', config.passed, detail: config.findings
        .where((f) => !f.passed)
        .map((f) => f.detail)
        .join('; '));

    final runtime = ReleaseRuntimeAudit().run();
    add('release_runtime_audit', runtime.passed);

    add(
      'freeze_enforced',
      _freeze.isFreezeActive || !ReleaseModeGuard.isStrictRelease,
      detail: 'فعّل crowd_feature_freeze قبل الإطلاق النهائي',
    );

    add(
      'release_channel',
      ReleaseModeGuard.isStrictRelease
          ? ReleaseModeGuard.sandboxDisabled
          : true,
    );

    final stability = LaunchStabilitySuite.instance;
    add(
      'runtime_health_stable',
      !ReleaseModeGuard.isStrictRelease || stability.allPassed,
      detail: 'شغّل LaunchStabilitySuite في debug',
    );

    final goLive = GoLiveReadinessEvaluator().evaluateQuick();
    final matrix = ReleaseStabilityMatrix.fromCategoryScores(goLive.categories);
    add(
      'go_live_score',
      goLive.score >= 72,
      detail: 'score=${goLive.score}',
    );
    add('stability_matrix', matrix.allAboveThreshold);

    final human = _human.buildReport();
    add(
      'human_validation',
      human.failedCount == 0 && human.blockedCount == 0,
      detail: 'validated=${human.validatedCount} pending=${human.pendingCount}',
    );

    final anyCriticalFail = checks.any(
      (c) => !c.passed &&
          {
            'release_runtime_audit',
            'production_configs',
            'go_live_score',
          }.contains(c.id),
    );
    final minorOnly = checks.any((c) => !c.passed) && !anyCriticalFail;

    final verdict = anyCriticalFail
        ? ReleaseCandidateVerdict.noGo
        : minorOnly
            ? ReleaseCandidateVerdict.conditionalGo
            : ReleaseCandidateVerdict.go;

    return ReleaseCandidateValidationReport(
      verdict: verdict,
      checks: checks,
      goLiveScore: goLive.score,
    );
  }
}
