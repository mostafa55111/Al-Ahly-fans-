import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/deterministic_backoff.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/lazy_vote_subscription_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/reconnect_backoff_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/socket_pressure_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/device_pressure_classifier.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/read_budget_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/read_pressure/visibility_subscription_guard.dart';

void main() {
  setUp(() {
    ReadBudgetGuard.instance.resetAll();
    DevicePressureClassifier.instance.reset();
    VisibilitySubscriptionGuard.instance.setVisibleTab(0);
    SocketPressureGuard.instance.reset();
  });

  tearDown(() {
    SocketPressureGuard.instance.reset();
    ReadBudgetGuard.instance.resetAll();
  });

  test('phased restore runs light before heavy', () async {
    final order = <String>[];
    final controller = LazyVoteSubscriptionController(
      reconnectBackoff: ReconnectBackoffController(
        backoff: const DeterministicBackoff(baseMs: 1, maxMs: 1),
      ),
    );
    await controller.schedulePhasedRestore(
      restoreLight: () async => order.add('light'),
      restoreHeavy: () async => order.add('heavy'),
    );
    expect(order, ['light', 'heavy']);
  });

  test('lightweight mode skips heavy restore', () async {
    final order = <String>[];
    final controller = LazyVoteSubscriptionController(
      reconnectBackoff: ReconnectBackoffController(
        backoff: const DeterministicBackoff(baseMs: 1, maxMs: 1),
      ),
    );
    controller.setLightweightMode(true);
    await controller.schedulePhasedRestore(
      restoreLight: () async => order.add('light'),
      restoreHeavy: () async => order.add('heavy'),
    );
    expect(order, ['light']);
  });

  test('socket pressure defers heavy streams', () async {
    SocketPressureGuard.instance.setRuntimePressure(high: true);
    expect(SocketPressureGuard.instance.shouldDeferHeavyStreams, isTrue);
  });
}
