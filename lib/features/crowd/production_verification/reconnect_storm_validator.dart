import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/lazy_vote_subscription_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/reconnect_backoff_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_report.dart';

/// يتحقق من استعادة الاشتراكات بعد عاصفة إعادة اتصال (sandbox).
class ReconnectStormValidator {
  Future<ReconnectStormReport> simulateStorm({
    int waves = 5,
    ReconnectBackoffController? backoff,
  }) async {
    final report = ReconnectStormReport.instance;
    final lazy = LazyVoteSubscriptionController(
      reconnectBackoff: backoff ?? ReconnectBackoffController(),
    );

    for (var w = 0; w < waves; w++) {
      report.recordResumeBurst();
      final sw = Stopwatch()..start();
      await lazy.schedulePhasedRestore(
        appResumed: true,
        restoreLight: () async {},
        restoreHeavy: () async {},
      );
      sw.stop();
      report.recordStabilization(sw.elapsed);
    }

    return report;
  }
}
