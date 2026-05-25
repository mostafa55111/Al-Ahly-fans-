import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/socket_pressure_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/reconnect_storm_metrics.dart';

/// أوضاع التشغيل تحت تدهور البنية التحتية.
enum CrowdInfrastructureRuntimeMode {
  normal,
  degradedReads,
  authorityFallback,
  lightweightRuntime,
  recoveryMode,
}

class InfrastructureSignals {
  const InfrastructureSignals({
    this.rtdbSlow = false,
    this.authorityTimeout = false,
    this.partialShardReads = false,
    this.reconnectStorm = false,
    this.mediaPreloadPressure = false,
    this.repeatedAuthRefresh = false,
    this.recoveryQueueDepth = 0,
  });

  final bool rtdbSlow;
  final bool authorityTimeout;
  final bool partialShardReads;
  final bool reconnectStorm;
  final bool mediaPreloadPressure;
  final bool repeatedAuthRefresh;
  final int recoveryQueueDepth;
}

/// يختار وضع التشغيل ويُطبّق سياسات خفيفة — بدون UI.
class InfrastructureDegradationResolver {
  InfrastructureDegradationResolver._();

  static final InfrastructureDegradationResolver instance =
      InfrastructureDegradationResolver._();

  CrowdInfrastructureRuntimeMode _mode = CrowdInfrastructureRuntimeMode.normal;
  int _duplicateRecoveryAttempts = 0;

  CrowdInfrastructureRuntimeMode get mode => _mode;

  bool get isLightweight =>
      _mode == CrowdInfrastructureRuntimeMode.lightweightRuntime ||
      _mode == CrowdInfrastructureRuntimeMode.recoveryMode;

  bool get suppressHeavyPreload =>
      isLightweight || _mode == CrowdInfrastructureRuntimeMode.degradedReads;

  bool get allowPhasedRestoreOnly => _mode != CrowdInfrastructureRuntimeMode.normal;

  CrowdInfrastructureRuntimeMode resolve(InfrastructureSignals signals) {
    if (signals.recoveryQueueDepth > 0 &&
        (signals.authorityTimeout || signals.partialShardReads)) {
      _mode = CrowdInfrastructureRuntimeMode.recoveryMode;
    } else if (signals.authorityTimeout) {
      _mode = CrowdInfrastructureRuntimeMode.authorityFallback;
      FailureSurvivalRuntimeReport.instance.recordAuthorityFallback();
    } else if (signals.reconnectStorm ||
        SocketPressureGuard.instance.isAppBackgrounded) {
      _mode = CrowdInfrastructureRuntimeMode.lightweightRuntime;
    } else if (signals.rtdbSlow ||
        signals.partialShardReads ||
        signals.mediaPreloadPressure) {
      _mode = CrowdInfrastructureRuntimeMode.degradedReads;
    } else {
      _mode = CrowdInfrastructureRuntimeMode.normal;
    }

    if (_mode != CrowdInfrastructureRuntimeMode.normal) {
      FailureSurvivalRuntimeReport.instance.recordDegradedRuntime();
    }
    return _mode;
  }

  /// يمنع محاولات استرداد مكررة متزامنة.
  bool tryEnterRecovery(String dedupeKey) {
    if (_duplicateRecoveryAttempts > 0) {
      FailureSurvivalRuntimeReport.instance.recordDuplicateRecoveryPrevented();
      return false;
    }
    _duplicateRecoveryAttempts++;
    return true;
  }

  void leaveRecovery() {
    if (_duplicateRecoveryAttempts > 0) _duplicateRecoveryAttempts--;
  }

  void recordReconnectSuppression() {
    FailureSurvivalRuntimeReport.instance.recordReconnectSuppression();
    ReconnectStormMetrics.instance.recordDeferredHeavy();
  }

  InfrastructureSignals collectLiveSignals({int recoveryQueueDepth = 0}) {
    final pressure = SocketPressureGuard.instance;
    return InfrastructureSignals(
      rtdbSlow: pressure.shouldDeferHeavyStreams,
      reconnectStorm: ReconnectStormMetrics.instance.resumeBursts > 3,
      mediaPreloadPressure: pressure.runtimePressureHigh,
      recoveryQueueDepth: recoveryQueueDepth,
    );
  }
}
