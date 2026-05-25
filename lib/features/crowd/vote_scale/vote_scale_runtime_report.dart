import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_metrics.dart';

/// تقرير تشغيل debug — إعادة اتصال، وسائط، سلطة، إغلاق.
class VoteScaleRuntimeReport {
  VoteScaleRuntimeReport._();

  static final VoteScaleRuntimeReport instance = VoteScaleRuntimeReport._();

  int reconnectBursts = 0;
  int preloadQueueSize = 0;
  int imageValidationFailures = 0;
  int retryExhaustions = 0;
  String lastAuthorityMode = 'local_client_authority';
  Duration averageFinalizeDuration = Duration.zero;
  int _finalizeSamples = 0;

  VoteScaleMetrics get metrics => VoteScaleMetrics.instance;

  void recordReconnectBurst() {
    if (!kDebugMode) return;
    reconnectBursts++;
  }

  void recordPreloadQueueSize(int size) {
    if (!kDebugMode) return;
    preloadQueueSize = size;
  }

  void recordFinalizeDuration(Duration d) {
    if (!kDebugMode) return;
    _finalizeSamples++;
    final totalMs =
        averageFinalizeDuration.inMilliseconds * (_finalizeSamples - 1) +
            d.inMilliseconds;
    averageFinalizeDuration =
        Duration(milliseconds: totalMs ~/ _finalizeSamples);
    metrics.recordFinalize(d, success: true);
  }

  void recordImageValidationFailure() {
    if (!kDebugMode) return;
    imageValidationFailures++;
  }

  void recordRetryExhausted() {
    if (!kDebugMode) return;
    retryExhaustions++;
  }

  void recordAuthorityMode(String mode) {
    if (!kDebugMode) return;
    lastAuthorityMode = mode;
  }

  Map<String, dynamic> snapshot() {
    if (!kDebugMode) return const {};
    return {
      'reconnectBursts': reconnectBursts,
      'preloadQueueSize': preloadQueueSize,
      'averageFinalizeMs': averageFinalizeDuration.inMilliseconds,
      'imageValidationFailures': imageValidationFailures,
      'retryExhaustions': retryExhaustions,
      'authorityMode': lastAuthorityMode,
      'metrics': {
        'finalizeSuccess': metrics.finalizeSuccess,
        'aggregationRuns': metrics.aggregationRuns,
      },
    };
  }

  @visibleForTesting
  void reset() {
    reconnectBursts = 0;
    preloadQueueSize = 0;
    imageValidationFailures = 0;
    retryExhaustions = 0;
    lastAuthorityMode = 'local_client_authority';
    averageFinalizeDuration = Duration.zero;
    _finalizeSamples = 0;
  }
}
