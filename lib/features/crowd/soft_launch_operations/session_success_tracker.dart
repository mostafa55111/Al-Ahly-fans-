import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/live_incident_tracker.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_metrics.dart';

/// حكم نجاح الجلسة التشغيلية.
enum SessionSuccessVerdict {
  success,
  partial,
  failed,
}

class SessionSuccessReport {
  const SessionSuccessReport({
    required this.verdict,
    required this.published,
    required this.votingStable,
    required this.finalizeCompleted,
    required this.winnerVisible,
    required this.noCriticalIncident,
    required this.summaryAr,
  });

  final SessionSuccessVerdict verdict;
  final bool published;
  final bool votingStable;
  final bool finalizeCompleted;
  final bool winnerVisible;
  final bool noCriticalIncident;
  final String summaryAr;
}

/// جلسة ناجحة فقط عند استيفاء كل المعايير التشغيلية.
class SessionSuccessTracker {
  SessionSuccessTracker({
    LiveIncidentTracker? incidents,
    SoftLaunchMetrics? metrics,
  })  : _incidents = incidents ?? LiveIncidentTracker.instance,
        _metrics = metrics ?? SoftLaunchMetrics.instance;

  final LiveIncidentTracker _incidents;
  final SoftLaunchMetrics _metrics;

  SessionSuccessReport evaluate({
    required bool published,
    required bool votingStable,
    required bool finalizeCompleted,
    required bool winnerVisible,
  }) {
    final noCritical = !_incidents.hasCriticalActive;
    final allCore = published &&
        votingStable &&
        finalizeCompleted &&
        winnerVisible &&
        noCritical;

    SessionSuccessVerdict verdict;
    String summary;
    if (allCore) {
      verdict = SessionSuccessVerdict.success;
      summary = 'جلسة ناجحة — كل المعايير مستوفاة';
    } else if (published && votingStable) {
      verdict = SessionSuccessVerdict.partial;
      summary = 'جلسة جزئية — تحقق من finalize أو الفائز';
    } else {
      verdict = SessionSuccessVerdict.failed;
      summary = 'جلسة فاشلة — مراجعة تشغيلية مطلوبة';
    }

    if (allCore) {
      _metrics.recordFinalize(success: true);
    }

    return SessionSuccessReport(
      verdict: verdict,
      published: published,
      votingStable: votingStable,
      finalizeCompleted: finalizeCompleted,
      winnerVisible: winnerVisible,
      noCriticalIncident: noCritical,
      summaryAr: summary,
    );
  }
}
