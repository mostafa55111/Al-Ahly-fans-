import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/environment_profile.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/readiness/go_live_readiness_evaluator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/verification_sandbox_guard.dart';

void main() {
  group('CrowdEnvironmentResolver', () {
    tearDown(() => CrowdEnvironmentResolver.resetForTest());

    test('staging allows sandbox sessions', () async {
      await CrowdEnvironmentResolver.bootstrap(overrideWire: 'staging');
      expect(CrowdEnvironmentResolver.current.allowsSandboxSessions, isTrue);
      expect(
        () => CrowdEnvironmentResolver.assertNotProductionSandbox('sandbox_x'),
        returnsNormally,
      );
    });

    test('production blocks sandbox session ids', () async {
      await CrowdEnvironmentResolver.bootstrap(overrideWire: 'production');
      expect(
        () => CrowdEnvironmentResolver.assertNotProductionSandbox('sandbox_x'),
        throwsStateError,
      );
    });
  });

  group('ReleaseChannel', () {
    test('production channel disables verification dashboard', () {
      expect(
        ReleaseChannel.production.allowsVerificationDashboard,
        isFalse,
      );
      expect(ReleaseChannel.internal.allowsChaosInjection, isTrue);
    });
  });

  group('FirebaseCostGuard', () {
    setUp(() => FirebaseCostGuard.instance.reset());

    test('elevates pressure on read spike', () {
      final guard = FirebaseCostGuard.instance;
      for (var i = 0; i < 200; i++) {
        guard.recordRead();
      }
      expect(guard.level.index, greaterThanOrEqualTo(1));
      expect(guard.shouldReduceThumbnailPromotion, isTrue);
    });
  });

  group('GoLiveReadinessEvaluator', () {
    test('evaluateQuick returns bounded score', () {
      final result = GoLiveReadinessEvaluator().evaluateQuick();
      expect(result.score, inInclusiveRange(0, 100));
      expect(result.categories, isNotEmpty);
    });
  });

  group('VerificationSandboxGuard + production env', () {
    tearDown(() {
      CrowdEnvironmentResolver.resetForTest();
      ReleaseChannelResolver.resetForTest();
    });

    test('blocks verification when production env resolved', () async {
      await CrowdEnvironmentResolver.bootstrap(overrideWire: 'production');
      expect(VerificationSandboxGuard.isVerificationAllowed, isFalse);
    });
  });
}
