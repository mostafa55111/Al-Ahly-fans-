import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/beta_distribution_registry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/controlled_rollout_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/crash_signal_registry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/live_incident_tracker.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/limited_rollout_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/production_rollout_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/reconnect_event_tracker.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/runtime_health_snapshot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/session_success_tracker.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_governor.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_metrics.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/release_channel_policy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_remote_config.dart';

void main() {
  setUp(() {
    ProductionFeatureFreeze.instance.resetForTests(freeze: true);
    BetaDistributionRegistry.instance.resetForTests();
    LiveIncidentTracker.instance.resetForTests();
    ReconnectEventTracker.instance.resetForTests();
    SoftLaunchMetrics.instance.resetForTests();
    CrashSignalRegistry.instance.resetForTests();
  });

  group('LimitedRolloutController', () {
    test('blocks when soft launch disabled', () {
      final ctrl = LimitedRolloutController(
        config: const InMemorySoftLaunchConfig(),
      );
      final v = ctrl.evaluateAccess(userOrDeviceKey: 'user-a');
      expect(v.allowed, isFalse);
    });

    test('allows owner when beta only', () {
      final ctrl = LimitedRolloutController(
        config: const InMemorySoftLaunchConfig(
          softLaunchEnabled: true,
          betaChannelOnly: true,
          rolloutPercentage: 5,
        ),
      );
      final v = ctrl.evaluateAccess(userOrDeviceKey: 'fan', isOwner: true);
      expect(v.allowed, isTrue);
    });

    test('emergency stop blocks all', () {
      final ctrl = LimitedRolloutController(
        config: const InMemorySoftLaunchConfig(
          softLaunchEnabled: true,
          emergencyRolloutStop: true,
        ),
      );
      expect(ctrl.evaluateAccess(userOrDeviceKey: 'x').allowed, isFalse);
    });

    test('rollout freeze blocks expansion', () {
      final ctrl = LimitedRolloutController(
        config: const InMemorySoftLaunchConfig(
          softLaunchEnabled: true,
          softLaunchFreeze: true,
          rolloutPercentage: 5,
        ),
      );
      expect(ctrl.rolloutFrozen, isTrue);
      expect(ctrl.canExpandToNextStage(), isFalse);
    });
  });

  group('LiveIncidentTracker', () {
    test('escalates critical detection', () {
      LiveIncidentTracker.instance.record(
        type: LiveIncidentType.finalizeFailure,
        severity: LiveIncidentSeverity.critical,
        message: 'test',
      );
      expect(LiveIncidentTracker.instance.hasCriticalActive, isTrue);
      expect(
        LiveIncidentTracker.instance.countBySeverity(
          LiveIncidentSeverity.critical,
        ),
        1,
      );
    });
  });

  group('ReconnectEventTracker', () {
    test('tracks reconnect count', () {
      ReconnectEventTracker.instance.recordReconnect(degraded: true);
      ReconnectEventTracker.instance.recordRestoreDuration(120);
      final snap = ReconnectEventTracker.instance.snapshot();
      expect(snap.reconnectCount, 1);
      expect(snap.degradedReconnects, 1);
    });
  });

  group('SessionSuccessTracker', () {
    test('success when all criteria met', () {
      final report = SessionSuccessTracker().evaluate(
        published: true,
        votingStable: true,
        finalizeCompleted: true,
        winnerVisible: true,
      );
      expect(report.verdict, SessionSuccessVerdict.success);
    });

    test('failed when publish missing', () {
      final report = SessionSuccessTracker().evaluate(
        published: false,
        votingStable: true,
        finalizeCompleted: true,
        winnerVisible: true,
      );
      expect(report.verdict, SessionSuccessVerdict.failed);
    });
  });

  group('SoftLaunchGovernor', () {
    test('emergency rollback phase when stop flag', () {
      final gov = SoftLaunchGovernor(
        config: const InMemorySoftLaunchConfig(
          softLaunchEnabled: true,
          emergencyRolloutStop: true,
        ),
      );
      expect(gov.currentPhase, SoftLaunchPhase.emergencyRollback);
    });

    test('launch freeze enforced from config', () {
      final gov = SoftLaunchGovernor(
        config: const InMemorySoftLaunchConfig(softLaunchFreeze: true),
      );
      expect(gov.launchFreezeEnforced, isTrue);
    });
  });

  group('ProductionRolloutGuard', () {
    test('safe when freeze and no public rollout', () {
      final report = ProductionRolloutGuard(
        config: const InMemorySoftLaunchConfig(
          publicRolloutEnabled: false,
          betaChannelOnly: true,
          softLaunchFreeze: true,
        ),
        channel: ReleaseChannelPolicy.testing(),
      ).evaluate();
      expect(report.verdict, isNot(ProductionRolloutVerdict.blocked));
    });
  });

  group('ControlledRolloutGate', () {
    test('NO_GO on critical incident', () {
      LiveIncidentTracker.instance.record(
        type: LiveIncidentType.finalizeFailure,
        severity: LiveIncidentSeverity.critical,
        message: 'x',
      );
      final report = ControlledRolloutGate(
        rolloutGuard: ProductionRolloutGuard(
          config: const InMemorySoftLaunchConfig(softLaunchFreeze: true),
          channel: ReleaseChannelPolicy.testing(),
        ),
      ).evaluate();
      expect(report.verdict, ControlledRolloutVerdict.noGo);
      expect(report.blockers, isNotEmpty);
    });
  });

  group('RuntimeHealthSnapshotBuilder', () {
    test('capture builds snapshot in debug tests', () {
      final snap = RuntimeHealthSnapshotBuilder().capture();
      expect(snap, isNotNull);
      expect(snap!.degradation, isNotNull);
    });
  });
}
