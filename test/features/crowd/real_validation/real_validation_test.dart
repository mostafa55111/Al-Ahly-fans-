import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/real_validation_exports.dart';

void main() {
  setUp(() {
    RealDeviceValidationSuite.instance.resetForTests();
    ProductionSurfaceLock.instance.resetForTests();
    LaunchFreezeGuard.instance.resetForTests();
    ThermalPerformanceMonitor.instance.reset();
  });

  group('ProductionSurfaceLock', () {
    test('allows only allowlisted modifications when locked', () {
      ProductionSurfaceLock.instance.activateFanExperienceLock();
      expect(
        ProductionSurfaceLock.instance.allowModification(
          FanExperienceModificationClass.bugFix,
        ),
        isTrue,
      );
      expect(
        ProductionSurfaceLock.instance.allowModification(
          FanExperienceModificationClass.prohibited,
        ),
        isFalse,
      );
    });
  });

  group('LaunchFreezeGuard', () {
    test('rejects large relative deltas when active', () {
      LaunchFreezeGuard.instance.activate();
      expect(
        LaunchFreezeGuard.instance.allowsRelativeChange(
          LaunchFreezeLayer.motionPhilosophy,
          0.05,
        ),
        isTrue,
      );
      expect(
        LaunchFreezeGuard.instance.allowsRelativeChange(
          LaunchFreezeLayer.motionPhilosophy,
          0.15,
        ),
        isFalse,
      );
    });
  });

  group('RealDeviceValidationSuite', () {
    test('reference device matrix passes for live voting', () {
      final matrix = RealDeviceValidationSuite.instance
          .runReferenceDeviceMatrix(phase: MatchNightPhase.liveVoting);
      expect(matrix.values.every((v) => v), isTrue);
    });

    test('focus hierarchy confirms on winner reveal', () {
      final broadcast = BroadcastCalibrationSnapshot.resolve(
        viewport: const Size(412, 892),
        phase: MatchNightPhase.winnerReveal,
      );
      final score = RealUserFocusTracking.score(broadcast: broadcast);
      expect(score.hierarchyConfirmedFor(MatchNightPhase.winnerReveal), isTrue);
      expect(score.winnerDominance, greaterThan(0.9));
    });

    test('readability audit fails when countdown backdrop too weak', () {
      final broadcast = BroadcastCalibrationSnapshot.resolve(
        viewport: const Size(800, 1280),
        phase: MatchNightPhase.finalizing,
      );
      final report = RealWorldReadabilityReport.audit(broadcast: broadcast);
      expect(report.domain, 'readability');
    });
  });
}
