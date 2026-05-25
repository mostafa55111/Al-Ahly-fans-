import 'dart:math' as math;

import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';

/// موجات المشاعر الجماعية — يُحدَّث من مستمع التصويت فقط.
class CrowdEmotionWaveController {
  final List<_VoteTick> _ticks = <_VoteTick>[];

  double emotionTemperature = 0.22;
  double crowdDirectionX = 0;
  double crowdPressure = 0;
  double energyWave01 = 0;
  double atmosphereMemory01 = 0;

  double gravityNx = 0.5;
  double gravityNy = 0.5;

  String? _lastLeadId;
  double _lastLeaderShare = 0;
  int _lastTotal = 0;
  int _lastMemoryBumpMs = 0;

  void ingest({
    required MatchVotingState state,
    required double momentum01,
    required int reactionStreamLoad,
  }) {
    if (state.loading || state.match == null || state.match!.id.isEmpty) {
      _softReset();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final total = state.totalVotes;
    final lead = state.leadingPlayerId;
    final players = state.players.where((p) => p.visible).toList();

    var leadVotes = 0;
    var secondVotes = 0;
    MatchPitchPlayer? leadPlayer;
    if (players.isNotEmpty) {
      final sorted = List<MatchPitchPlayer>.from(players)..sort((a, b) => b.votes.compareTo(a.votes));
      leadPlayer = sorted.first;
      leadVotes = sorted.first.votes;
      secondVotes = sorted.length > 1 ? sorted[1].votes : 0;
    }

    final share = total > 0 ? leadVotes / total : 0.0;
    final gap01 = total > 0 ? ((leadVotes - secondVotes) / total).clamp(0.0, 1.0) : 0.0;

    if (leadPlayer != null) {
      gravityNx = leadPlayer.x.clamp(0.04, 0.96);
      gravityNy = leadPlayer.y.clamp(0.06, 0.94);
    }

    _ticks.add(_VoteTick(now, total));
    while (_ticks.isNotEmpty && now - _ticks.first.tMs > 14000) {
      _ticks.removeAt(0);
    }

    var vel = 0.0;
    if (_ticks.length >= 2) {
      final a = _ticks.first;
      final b = _ticks.last;
      final sec = (b.tMs - a.tMs) / 1000.0;
      if (sec > 0.05) vel = (b.total - a.total) / sec;
    }
    final vel01 = (vel / 24.0).clamp(0.0, 1.0);
    final reactionLoad01 = (reactionStreamLoad / 8.0).clamp(0.0, 1.0);

    final dShare = share - _lastLeaderShare;
    _lastLeaderShare = share;

    var flip = false;
    if (lead != null && _lastLeadId != null && _lastLeadId != lead && total > 4) {
      flip = true;
      _bumpMemory(0.72, now);
    }
    _lastLeadId = lead;

    final dv = total - _lastTotal;
    _lastTotal = total;

    if (dv >= 6 && vel01 > 0.4) {
      _bumpMemory(0.65, now);
    }
    if (gap01 > 0.38 && share > 0.42) {
      _bumpMemory(0.58, now);
    }
    if (flip) {
      crowdDirectionX = (dShare > 0 ? 1.0 : dShare < 0 ? -1.0 : dirBiasFromGravity()).clamp(-1.0, 1.0);
    } else {
      crowdDirectionX = (0.86 * crowdDirectionX + 0.14 * ((gravityNx - 0.5) * 2)).clamp(-1.0, 1.0);
    }

    final mass = (math.log(1 + total) / math.log(1 + 90)).clamp(0.0, 1.0);
    emotionTemperature = (mass * 0.24 +
            share * 0.22 +
            gap01 * 0.16 +
            vel01 * 0.22 +
            momentum01 * 0.2 +
            reactionLoad01 * 0.12 +
            atmosphereMemory01 * 0.18)
        .clamp(0.08, 1.0);

    crowdPressure = (vel01 * 0.38 + mass * 0.32 + gap01 * 0.2 + reactionLoad01 * 0.1).clamp(0.0, 1.0);
    energyWave01 = (0.45 * emotionTemperature + 0.35 * vel01 + 0.2 * math.sin(now / 680)).clamp(0.0, 1.0);
  }

  void decayAtmosphere(double dtSeconds) {
    if (dtSeconds <= 0) return;
    final factor = math.pow(0.9, dtSeconds * 5.5).toDouble();
    atmosphereMemory01 = (atmosphereMemory01 * factor).clamp(0.0, 1.0);
    emotionTemperature = (emotionTemperature * 0.992 + atmosphereMemory01 * 0.008).clamp(0.08, 1.0);
  }

  void _bumpMemory(double amount, int nowMs) {
    if (nowMs - _lastMemoryBumpMs < 800) return;
    _lastMemoryBumpMs = nowMs;
    atmosphereMemory01 = math.min(1.0, atmosphereMemory01 + amount);
  }

  void _softReset() {
    emotionTemperature = 0.18;
    crowdPressure = 0.12;
    energyWave01 = 0.1;
    crowdDirectionX = 0;
  }

  double dirBiasFromGravity() => ((gravityNx - 0.5) * 2).clamp(-1.0, 1.0);
}

class _VoteTick {
  _VoteTick(this.tMs, this.total);
  final int tMs;
  final int total;
}
