import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/human_feedback_registry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/human_validation_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_candidate_validator.dart';

/// الحكم النهائي للإطلاق.
enum ReleaseGoLiveVerdict {
  go,
  conditionalGo,
  noGo,
}

class ReleaseGoLiveGateReport {
  const ReleaseGoLiveGateReport({
    required this.verdict,
    required this.summaryAr,
    required this.blockers,
    required this.warnings,
  });

  final ReleaseGoLiveVerdict verdict;
  final String summaryAr;
  final List<String> blockers;
  final List<String> warnings;
}

/// بوابة GO / NO-GO النهائية.
class ReleaseGoLiveGate {
  Future<ReleaseGoLiveGateReport> evaluate({
    ReleaseCandidateValidationReport? candidate,
    HumanValidationReport? human,
    HumanFeedbackRegistry? feedback,
  }) async {
    final cand =
        candidate ?? await ReleaseCandidateValidator().validate();
    final hum = human ?? HumanValidationSuite().buildReport();
    final fb = feedback ?? HumanFeedbackRegistry();

    final blockers = <String>[];
    final warnings = <String>[];

    for (final c in cand.checks.where((x) => !x.passed)) {
      final line = '${c.id}: ${c.detail ?? "failed"}';
      if (_criticalIds.contains(c.id)) {
        blockers.add(line);
      } else {
        warnings.add(line);
      }
    }

    if (hum.failedCount > 0 || hum.blockedCount > 0) {
      blockers.add(
        'human_validation: failed=${hum.failedCount} blocked=${hum.blockedCount}',
      );
    }
    if (hum.pendingCount > 0) {
      warnings.add('human_validation: pending=${hum.pendingCount}');
    }
    if (fb.hasBlockingIssues) {
      blockers.add('human_feedback: severity>=4 entries present');
    }

    ReleaseGoLiveVerdict verdict;
    String summary;
    if (blockers.isNotEmpty || cand.verdict == ReleaseCandidateVerdict.noGo) {
      verdict = ReleaseGoLiveVerdict.noGo;
      summary = 'لا إطلاق — مخاطر runtime أو تحقق بشري';
    } else if (warnings.isNotEmpty ||
        cand.verdict == ReleaseCandidateVerdict.conditionalGo) {
      verdict = ReleaseGoLiveVerdict.conditionalGo;
      summary = 'إطلاق مشروط — معالجة التحذيرات خلال 48 ساعة';
    } else {
      verdict = ReleaseGoLiveVerdict.go;
      summary = 'جاهز للإطلاق — كل الفحوصات الحرجة خضراء';
    }

    return ReleaseGoLiveGateReport(
      verdict: verdict,
      summaryAr: summary,
      blockers: blockers,
      warnings: warnings,
    );
  }

  static const _criticalIds = {
    'release_runtime_audit',
    'production_configs',
    'go_live_score',
    'runtime_health_stable',
    'release_channel',
  };

  static String verdictLabelAr(ReleaseGoLiveVerdict v) => switch (v) {
        ReleaseGoLiveVerdict.go => 'GO',
        ReleaseGoLiveVerdict.conditionalGo => 'CONDITIONAL GO',
        ReleaseGoLiveVerdict.noGo => 'NO-GO',
      };
}
