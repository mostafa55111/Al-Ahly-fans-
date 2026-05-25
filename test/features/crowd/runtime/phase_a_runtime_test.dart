import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/legacy/legacy_crowd_feature_flags.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/crowd_navigation_runtime_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/stream_lifecycle_audit.dart';

void main() {
  test('legacy flags are off in production runtime', () {
    expect(LegacyCrowdFeatureFlags.enableLegacyVoting, isFalse);
    expect(LegacyCrowdFeatureFlags.enableLegacyRoutes, isFalse);
    expect(LegacyCrowdFeatureFlags.enableLegacyStreams, isFalse);
  });

  test('StreamLifecycleAudit tracks subscribe and cancel', () {
    const id = 'test_stream';
    StreamLifecycleAudit.instance.onSubscribe(id);
    expect(StreamLifecycleAudit.instance.activeSubscriptionCount, 1);
    StreamLifecycleAudit.instance.onCancel(id);
    expect(StreamLifecycleAudit.instance.activeSubscriptionCount, 0);
  });

  test('CrowdNavigationRuntimeGuard detects duplicate crowd mount', () {
    final guard = CrowdNavigationRuntimeGuard.instance;
    expect(guard.registerCrowdScreenMount(), isTrue);
    expect(guard.registerCrowdScreenMount(), isFalse);
    guard.unregisterCrowdScreenMount();
    guard.unregisterCrowdScreenMount();
    expect(guard.crowdScreenMounts, 0);
  });
}
