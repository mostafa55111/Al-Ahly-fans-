import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/device_pressure_classifier.dart';

/// ملف حركة الملعب — breathing بطيء، بدون RGB/neon مبالغ.
class StadiumMotionProfile {
  const StadiumMotionProfile({
    required this.breathPeriodSec,
    required this.breathAmplitude,
    required this.glowPulseAmplitude,
    required this.allowCardPulse,
    required this.allowHeavyBlur,
  });

  final double breathPeriodSec;
  final double breathAmplitude;
  final double glowPulseAmplitude;
  final bool allowCardPulse;
  final bool allowHeavyBlur;

  static StadiumMotionProfile forPhase(MatchNightPhase phase) {
    final lowEnd =
        DevicePressureClassifier.instance.currentTier ==
        DevicePressureTier.lowEnd;

    if (lowEnd) {
      return const StadiumMotionProfile(
        breathPeriodSec: 12,
        breathAmplitude: 0.012,
        glowPulseAmplitude: 0.04,
        allowCardPulse: false,
        allowHeavyBlur: false,
      );
    }

    switch (phase) {
      case MatchNightPhase.preMatch:
        return const StadiumMotionProfile(
          breathPeriodSec: 10,
          breathAmplitude: 0.018,
          glowPulseAmplitude: 0.06,
          allowCardPulse: true,
          allowHeavyBlur: true,
        );
      case MatchNightPhase.liveVoting:
        return const StadiumMotionProfile(
          breathPeriodSec: 8,
          breathAmplitude: 0.022,
          glowPulseAmplitude: 0.10,
          allowCardPulse: true,
          allowHeavyBlur: true,
        );
      case MatchNightPhase.closingSoon:
        return const StadiumMotionProfile(
          breathPeriodSec: 6,
          breathAmplitude: 0.028,
          glowPulseAmplitude: 0.12,
          allowCardPulse: true,
          allowHeavyBlur: true,
        );
      case MatchNightPhase.finalizing:
      case MatchNightPhase.winnerReveal:
        return const StadiumMotionProfile(
          breathPeriodSec: 7,
          breathAmplitude: 0.024,
          glowPulseAmplitude: 0.14,
          allowCardPulse: false,
          allowHeavyBlur: false,
        );
      case MatchNightPhase.hallOfFame:
        return const StadiumMotionProfile(
          breathPeriodSec: 11,
          breathAmplitude: 0.014,
          glowPulseAmplitude: 0.05,
          allowCardPulse: false,
          allowHeavyBlur: true,
        );
    }
  }
}
