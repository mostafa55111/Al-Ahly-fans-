import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_device_profiles.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';

/// ضبط الكثافة البصرية — شاشة نظيفة قابلة للتنفس.
class BroadcastDensityTune {
  const BroadcastDensityTune({
    required this.glowVisibility,
    required this.cardProminence,
    required this.benchAttention,
    required this.overlayDominance,
    required this.textDensity,
    required this.atmosphereFxMul,
  });

  final double glowVisibility;
  final double cardProminence;
  final double benchAttention;
  final double overlayDominance;
  final double textDensity;
  final double atmosphereFxMul;

  static BroadcastDensityTune forContext({
    required BroadcastDeviceProfile device,
    required MatchNightPhase phase,
    required bool hallTab,
  }) {
    var glow = 0.82;
    var cards = 1.0;
    var bench = 0.88;
    var overlay = 0.78;
    var text = 1.0;
    var fx = BroadcastDeviceProfiles.fxMul(device);

    switch (phase) {
      case MatchNightPhase.liveVoting:
        cards = 1.02;
        bench = 0.86;
      case MatchNightPhase.closingSoon:
        glow = 0.88;
        cards = 1.04;
      case MatchNightPhase.finalizing:
        overlay = 0.55;
        bench = 0.72;
        fx = fx * 0.65;
      case MatchNightPhase.winnerReveal:
        cards = 1.06;
        bench = 0.62;
        glow = 0.9;
      case MatchNightPhase.hallOfFame:
        overlay = 0.68;
        bench = 0.8;
      case MatchNightPhase.preMatch:
        cards = 0.96;
        bench = 0.9;
    }

    if (hallTab) {
      bench = 0.75;
      overlay = 0.7;
      fx = fx * 0.8;
    }

    if (device == BroadcastDeviceProfile.compactPhone) {
      text = 1.04;
      bench = bench * 0.94;
    }

    return BroadcastDensityTune(
      glowVisibility: glow.clamp(0.65, 1.0),
      cardProminence: cards.clamp(0.92, 1.08),
      benchAttention: bench.clamp(0.55, 1.0),
      overlayDominance: overlay.clamp(0.5, 0.9),
      textDensity: text.clamp(0.96, 1.06),
      atmosphereFxMul: fx.clamp(0.45, 1.0),
    );
  }
}
