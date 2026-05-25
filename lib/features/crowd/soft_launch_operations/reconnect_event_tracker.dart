import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/reconnect_storm_metrics.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_surface_gate.dart';

class ReconnectEventSummary {
  const ReconnectEventSummary({
    required this.reconnectCount,
    required this.restoreDurationMsAvg,
    required this.stormDetected,
    required this.degradedReconnects,
    required this.repeatedHydrationAttempts,
  });

  final int reconnectCount;
  final double restoreDurationMsAvg;
  final bool stormDetected;
  final int degradedReconnects;
  final int repeatedHydrationAttempts;
}

/// تتبع أحداث إعادة الاتصال — لا أنظمة reconnect جديدة.
class ReconnectEventTracker {
  ReconnectEventTracker._();

  static final ReconnectEventTracker instance = ReconnectEventTracker._();

  int _reconnectCount = 0;
  int _degradedCount = 0;
  int _hydrationRetries = 0;
  final List<int> _restoreDurationsMs = [];

  void recordReconnect({bool degraded = false}) {
    if (!SoftLaunchSurfaceGate.visible) return;
    _reconnectCount++;
    if (degraded) _degradedCount++;
  }

  void recordRestoreDuration(int ms) {
    if (!SoftLaunchSurfaceGate.visible) return;
    _restoreDurationsMs.add(ms);
    if (_restoreDurationsMs.length > 100) {
      _restoreDurationsMs.removeAt(0);
    }
  }

  void recordHydrationRetry() {
    if (!SoftLaunchSurfaceGate.visible) return;
    _hydrationRetries++;
  }

  ReconnectEventSummary snapshot() {
    final storm = ReconnectStormReport.instance;
    final metrics = ReconnectStormMetrics.instance;
    final avg = _restoreDurationsMs.isEmpty
        ? 0.0
        : _restoreDurationsMs.reduce((a, b) => a + b) /
            _restoreDurationsMs.length;
    return ReconnectEventSummary(
      reconnectCount: _reconnectCount,
      restoreDurationMsAvg: avg,
      stormDetected: storm.stabilizationRate < 0.5 && _reconnectCount >= 5,
      degradedReconnects: _degradedCount,
      repeatedHydrationAttempts: _hydrationRetries + metrics.deferredHeavySkips,
    );
  }

  @visibleForTesting
  void resetForTests() {
    _reconnectCount = 0;
    _degradedCount = 0;
    _hydrationRetries = 0;
    _restoreDurationsMs.clear();
  }
}
