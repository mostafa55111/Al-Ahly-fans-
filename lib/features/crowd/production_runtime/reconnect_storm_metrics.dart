import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_runtime_report.dart';

/// مقاييس عاصفة إعادة الاتصال.
class ReconnectStormMetrics {
  ReconnectStormMetrics._();

  static final ReconnectStormMetrics instance = ReconnectStormMetrics._();

  int resumeBursts = 0;
  int phasedRestores = 0;
  int deferredHeavySkips = 0;

  void recordResumeBurst() {
    if (!kDebugMode) return;
    resumeBursts++;
    VoteScaleRuntimeReport.instance.recordReconnectBurst();
  }

  void recordPhasedRestore() {
    if (!kDebugMode) return;
    phasedRestores++;
  }

  void recordDeferredHeavy() {
    if (!kDebugMode) return;
    deferredHeavySkips++;
  }
}
