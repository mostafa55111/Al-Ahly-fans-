import 'dart:async';

import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/reconnect_backoff_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/socket_pressure_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/incident_severity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incidents_bridge.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/rollback/safe_rollback_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/reconnect_storm_metrics.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/read_pressure/session_read_tier.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/device_pressure_classifier.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/read_budget_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/runtime_owner_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/reconnect_cost_profile.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/read_pressure/visibility_subscription_guard.dart';

/// استعادة اشتراكات التصويت على مراحل — خفيف ثم ثقيل.
class LazyVoteSubscriptionController {
  LazyVoteSubscriptionController({
    ReconnectBackoffController? reconnectBackoff,
    SocketPressureGuard? pressureGuard,
  })  : _reconnect = reconnectBackoff ?? ReconnectBackoffController(),
        _pressure = pressureGuard ?? SocketPressureGuard.instance;

  static final LazyVoteSubscriptionController instance =
      LazyVoteSubscriptionController();

  final ReconnectBackoffController _reconnect;
  final SocketPressureGuard _pressure;

  bool _lightweightMode = false;
  bool _restoreScheduled = false;
  SessionReadTier _readTier = SessionReadTier.foregroundFull;

  bool get lightweightMode => _lightweightMode;
  SessionReadTier get readTier => _readTier;

  bool get allowsHeavyStreams =>
      _readTier.allowsPlayersStream &&
      VisibilitySubscriptionGuard.instance.shouldAttachPlayersStream() &&
      !_pressure.shouldDeferHeavyStreams &&
      !_lightweightMode &&
      ReadBudgetGuard.instance.canAcquire(ReadBudgetSurface.crowdFan, reads: 1) &&
      !DevicePressureClassifier.instance.lightweightHydration;

  void setLightweightMode(bool enabled) {
    _lightweightMode = enabled;
    if (enabled) {
      _pressure.setRuntimePressure(high: true);
    } else {
      _pressure.setRuntimePressure(high: false);
    }
  }

  void setReadTier(SessionReadTier tier) {
    _readTier = tier;
    if (tier == SessionReadTier.dormantClockOnly) {
      _lightweightMode = true;
    }
  }

  /// عند العودة من الخلفية: لا تُعاد كل الاشتراكات فوراً.
  Future<void> schedulePhasedRestore({
    required Future<void> Function() restoreLight,
    required Future<void> Function() restoreHeavy,
    bool appResumed = false,
  }) async {
    if (_restoreScheduled) {
      ReconnectCostProfile.instance.recordCollapsed();
      return;
    }
    if (!ReadBudgetGuard.instance.tryAcquire(
      ReadBudgetSurface.reconnectHydration,
      reads: 2,
    )) {
      ReconnectCostProfile.instance.recordHeavyDeferred(readsSaved: 2);
      return;
    }
    _restoreScheduled = true;
    RuntimeOwnerGuard.instance.recordReconnectOrchestration(
      'LazyVoteSubscriptionController',
    );
    try {
      if (appResumed) {
        ReconnectStormMetrics.instance.recordResumeBurst();
        ReconnectStormReport.instance.recordResumeBurst();
        ReconnectCostProfile.instance.recordResumeBurst();
        await _reconnect.runAfterResumeDelay(() async {});
      }
      ReconnectStormMetrics.instance.recordPhasedRestore();
      ReconnectStormReport.instance.recordPhasedRestore();
      ReconnectCostProfile.instance.recordLightWave(reads: 2);
      await restoreLight();
      if (_rollbackBlocksHeavy()) {
        ReconnectStormMetrics.instance.recordDeferredHeavy();
        ReconnectStormReport.instance.recordHeavyDeferred();
        ReconnectCostProfile.instance.recordHeavyDeferred();
        return;
      }
      if (!allowsHeavyStreams) {
        ReconnectStormMetrics.instance.recordDeferredHeavy();
        ReconnectStormReport.instance.recordHeavyDeferred();
        ReconnectCostProfile.instance.recordHeavyDeferred();
        return;
      }
      final heavyDelay = 180 + (_reconnect.nextResumeDelayMs() % 400);
      await Future<void>.delayed(Duration(milliseconds: heavyDelay));
      if (!allowsHeavyStreams) {
        ReconnectStormMetrics.instance.recordDeferredHeavy();
        ReconnectStormReport.instance.recordHeavyDeferred();
        return;
      }
      await restoreHeavy();
      ReconnectCostProfile.instance.recordHeavyCompleted(reads: 1);
    } finally {
      _restoreScheduled = false;
      ReadBudgetGuard.instance.release(
        ReadBudgetSurface.reconnectHydration,
        reads: 2,
      );
    }
  }

  void cancelRestore() {
    _restoreScheduled = false;
    _reconnect.cancelPending();
  }

  bool _rollbackBlocksHeavy() {
    if (!getIt.isRegistered<SafeRollbackCoordinator>()) return false;
    return getIt<SafeRollbackCoordinator>().shouldSkipHeavyPreload;
  }

  void reportReconnectCollapseIfNeeded(int deferredCount) {
    if (deferredCount < 4) return;
    unawaited(
      ProductionIncidentsBridge.record(
        type: ProductionIncidentType.reconnectCollapse,
        severity: IncidentSeverity.high,
        message: 'deferred heavy restores=$deferredCount',
      ),
    );
  }
}
