import 'dart:math' as math;

import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/animation_budget_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_network/crowd_clusters.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_network/crowd_emotion_wave_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_network/crowd_live_atmosphere.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_runtime_guards.dart';

/// يوحّد الزخم والموجات والصوت والإضاءة — بدون listeners إضافية.
class CrowdSyncEngine {
  final CrowdEmotionWaveController wave = CrowdEmotionWaveController();

  CrowdClusterField _clusters = const CrowdClusterField(
    ultra: 0.25,
    casual: 0.35,
    newFans: 0.25,
    leaderFollowers: 0.15,
  );

  int _lastComposeMs = 0;

  void ingestMatchState(
    MatchVotingState state, {
    required double momentum01,
    required int activeReactions,
  }) {
    wave.ingest(
      state: state,
      momentum01: momentum01,
      reactionStreamLoad: activeReactions,
    );
    final total = state.totalVotes;
    var share = 0.0;
    final lead = state.leadingPlayerId;
    if (lead != null && total > 0) {
      for (final p in state.players) {
        if (p.id == lead) {
          share = p.votes / total;
          break;
        }
      }
    }
    _clusters = CrowdClusters.compute(
      totalVotes: total,
      momentum01: momentum01,
      leaderShare: share,
    );
  }

  /// يُستدعى داخل [AnimatedBuilder] الحالي للملعب فقط.
  CrowdLiveAtmosphere composeFrame({
    required double lightPhase01,
    required CrowdAnimationBudget budget,
    required CrowdRuntimeGuards guards,
    required double voteMomentum01,
    required double fanPulse01,
    required double intensity01,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = _lastComposeMs == 0
        ? 0.016
        : ((now - _lastComposeMs) / 1000.0).clamp(0.001, 0.1);
    _lastComposeMs = now;
    wave.decayAtmosphere(dt);

    var scale = switch (budget) {
      CrowdAnimationBudget.full => 1.0,
      CrowdAnimationBudget.reduced => 0.72,
      CrowdAnimationBudget.minimal => 0.38,
    };
    if (guards.strongDegrade) {
      scale *= 0.52;
    }

    final breath = 0.5 + 0.5 * math.sin(lightPhase01 * math.pi * 2);
    final collectiveBreath = (0.38 * fanPulse01 +
            0.28 * wave.emotionTemperature +
            0.22 * breath +
            0.12 * wave.atmosphereMemory01)
        .clamp(0.1, 1.0);

    final density = (0.28 +
            0.34 * wave.crowdPressure +
            0.22 * intensity01 +
            0.16 * voteMomentum01)
        .clamp(0.15, 1.0);

    return CrowdLiveAtmosphere(
      emotionTemperature: (wave.emotionTemperature * scale).clamp(0.0, 1.0),
      crowdDirectionX: wave.crowdDirectionX,
      crowdPressure: (wave.crowdPressure * scale).clamp(0.0, 1.0),
      energyWave01: (wave.energyWave01 * scale).clamp(0.0, 1.0),
      density01: (density * scale).clamp(0.1, 1.0),
      collectiveBreath01: (collectiveBreath * scale).clamp(0.1, 1.0),
      atmosphereMemory01: wave.atmosphereMemory01,
      gravityNx: wave.gravityNx,
      gravityNy: wave.gravityNy,
      runtimeScale: scale,
    );
  }

  /// موضع عائم مائل نحو جاذبية المتصدر.
  ({double dx, double dy}) reactionAnchor(math.Random r) {
    final pull = 0.55 + wave.crowdPressure * 0.25;
    return (
      dx: (wave.gravityNx * pull + r.nextDouble() * (1 - pull)).clamp(0.06, 0.94),
      dy: (wave.gravityNy * (pull * 0.9) + r.nextDouble() * (1 - pull * 0.9)).clamp(0.14, 0.78),
    );
  }

  String pickClusterReaction(math.Random r) {
    return CrowdClusters.emojiFor(_clusters.pick(r), r);
  }

  double emotionalDriveForAudio({
    required double voteMomentum01,
    required double fanEngagement01,
  }) {
    return (voteMomentum01 * 0.55 +
            wave.emotionTemperature * 0.28 +
            fanEngagement01 * 0.12 +
            wave.atmosphereMemory01 * 0.05)
        .clamp(0.0, 1.0);
  }
}
