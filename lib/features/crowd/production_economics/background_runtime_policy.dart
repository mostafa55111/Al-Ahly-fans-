import 'package:flutter/widgets.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/infrastructure_degradation_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/lazy_vote_subscription_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/socket_pressure_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/device_pressure_classifier.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/media_economics_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_policy_matrix.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/read_pressure/session_read_tier.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/read_pressure/visibility_subscription_guard.dart';

/// قمع runtime في الخلفية — لا streams ثقيلة ولا preload.
class BackgroundRuntimePolicy {
  BackgroundRuntimePolicy._();

  static final BackgroundRuntimePolicy instance = BackgroundRuntimePolicy._();

  final RuntimePolicyMatrix _matrix = const RuntimePolicyMatrix();

  void onAppBackgrounded() {
    SocketPressureGuard.instance.setAppBackgrounded(true);
    LazyVoteSubscriptionController.instance
      ..setLightweightMode(true)
      ..setReadTier(SessionReadTier.backgroundLight)
      ..cancelRestore();
    DevicePressureClassifier.instance.refresh(appBackgrounded: true);
    MediaEconomicsReport.instance.recordPreloadSuppressed();
  }

  void onAppForegrounded() {
    SocketPressureGuard.instance.setAppBackgrounded(false);
    LazyVoteSubscriptionController.instance
      ..setLightweightMode(false)
      ..setReadTier(SessionReadTier.foregroundFull);
    DevicePressureClassifier.instance.refresh(appBackgrounded: false);
  }

  bool allowHeavyWork({
    required AppLifecycleState lifecycle,
    required int visibleTabIndex,
  }) {
    if (lifecycle != AppLifecycleState.resumed) return false;
    VisibilitySubscriptionGuard.instance.setVisibleTab(visibleTabIndex);
    final phase = _matrix.reduce(
      CrowdRuntimePolicyInput(
        infrastructureMode: CrowdInfrastructureRuntimeMode.lightweightRuntime,
        appBackgrounded: SocketPressureGuard.instance.isAppBackgrounded,
      ),
    );
    return _matrix.allowHeavySubscriptions(phase);
  }

  bool allowMediaPreload() =>
      !SocketPressureGuard.instance.isAppBackgrounded &&
      !DevicePressureClassifier.instance.reducePreloadConcurrency;
}
