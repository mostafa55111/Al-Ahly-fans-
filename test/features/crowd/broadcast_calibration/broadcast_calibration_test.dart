import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';

void main() {
  group('BroadcastCalibrationSnapshot', () {
    test('compact phone lowers density and tightens spacing', () {
      final snap = BroadcastCalibrationSnapshot.resolve(
        viewport: const Size(340, 720),
        phase: MatchNightPhase.liveVoting,
      );
      expect(snap.device, BroadcastDeviceProfile.compactPhone);
      expect(snap.density.glowVisibility, lessThan(1.0));
      expect(snap.spacing.cardScaleMul, lessThanOrEqualTo(1.0));
      expect(snap.readability.scrimDarknessMul, greaterThan(1.0));
    });

    test('winner reveal emphasizes focus over bench', () {
      final snap = BroadcastCalibrationSnapshot.resolve(
        viewport: const Size(412, 892),
        phase: MatchNightPhase.winnerReveal,
      );
      expect(snap.focus.selectedEmphasis, 1.0);
      expect(snap.focus.nonFocusedCardOpacity, lessThan(0.7));
      expect(snap.density.benchAttention, lessThan(0.85));
    });

    test('hall tab softens competing highlights', () {
      final snap = BroadcastCalibrationSnapshot.resolve(
        viewport: const Size(412, 892),
        phase: MatchNightPhase.liveVoting,
        hallTabActive: true,
      );
      expect(snap.focus.competingHighlightReduction, lessThan(0.75));
      expect(snap.density.atmosphereFxMul, lessThan(1.0));
    });

    test('motion fade stays within broadcast cap', () {
      final snap = BroadcastCalibrationSnapshot.resolve(
        viewport: const Size(800, 1280),
        phase: MatchNightPhase.finalizing,
      );
      expect(snap.motion.fadeMs, inInclusiveRange(180, 240));
    });

    test('finish polish scales by premium feel', () {
      const finish = BroadcastFinishQuality(
        hierarchyConsistency: 0.8,
        edgeCleanliness: 1.0,
        premiumFeel: 0.95,
        visualNoiseCap: 0.9,
        sheenCap: 0.12,
      );
      expect(finish.polish(1.0), closeTo(0.95, 0.01));
    });
  });
}
