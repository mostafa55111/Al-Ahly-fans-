import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';

class _Sample {
  _Sample(this.tMs, this.totalVotes);
  final int tMs;
  final int totalVotes;
}

/// يقيس زخم التصويت اللحظي (0→1) للطبقة الشعورية — منفصل عن [CrowdMomentumTier] في الـ UI.
class CrowdVoteMomentumController extends ChangeNotifier {
  final List<_Sample> _samples = <_Sample>[];
  final List<String> _reactionQueue = <String>[];

  String? _lastLeadId;
  int _lastTotal = 0;
  double _lastLeaderShare = 0;
  int _flipStreak = 0;
  int _burstCooldownMs = 0;

  double _momentum = 0.22;
  double _fanPulse = 0.35;
  double _screenShake = 0.0;

  double get momentumValue => _momentum;

  /// نبض جماعي 0..1 يغذي الإضاءة والـ FX.
  double get fanPulse => _fanPulse;

  /// 0..1 اهتزاز خفيف للكاميرا (يُقيَّم خارجياً حسب الميزانية).
  double get screenShake => _screenShake;

  void reset() {
    _samples.clear();
    _reactionQueue.clear();
    _lastLeadId = null;
    _lastTotal = 0;
    _lastLeaderShare = 0;
    _flipStreak = 0;
    _burstCooldownMs = 0;
    _momentum = 0.22;
    _fanPulse = 0.35;
    _screenShake = 0;
    notifyListeners();
  }

  /// يُستدعى من مستمع حالة التصويت فقط — لا يمس Firebase.
  void ingest(MatchVotingState s) {
    if (s.loading || s.match == null || s.match!.id.isEmpty) {
      _softSet(0.18, 0.28, 0);
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    final total = s.totalVotes;
    final lead = s.leadingPlayerId;
    final players = s.players.where((p) => p.visible).toList();

    var leadVotes = 0;
    var secondVotes = 0;
    if (players.isNotEmpty) {
      final sorted = List<MatchPitchPlayer>.from(players)..sort((a, b) => b.votes.compareTo(a.votes));
      leadVotes = sorted.first.votes;
      secondVotes = sorted.length > 1 ? sorted[1].votes : 0;
    }

    final share = total > 0 ? leadVotes / total : 0.0;
    final gap01 = total > 0 ? ((leadVotes - secondVotes) / total).clamp(0.0, 1.0) : 0.0;

    _samples.add(_Sample(now, total));
    while (_samples.isNotEmpty && now - _samples.first.tMs > 12000) {
      _samples.removeAt(0);
    }

    var vPerSec = 0.0;
    if (_samples.length >= 2) {
      final a = _samples.first;
      final b = _samples.last;
      final sec = (b.tMs - a.tMs) / 1000.0;
      if (sec > 0.05) {
        vPerSec = (b.totalVotes - a.totalVotes) / sec;
      }
    }
    final vel01 = (vPerSec / 22.0).clamp(0.0, 1.0);

    final dShare = share - _lastLeaderShare;
    _lastLeaderShare = share;

    var surge01 = 0.0;
    if (dShare > 0.04 && total > 8) {
      surge01 = (dShare * 6).clamp(0.0, 1.0);
    }

    var flip = false;
    if (lead != null && lead.isNotEmpty && total > 0) {
      if (_lastLeadId != null && _lastLeadId != lead) {
        flip = true;
        _flipStreak = math.min(8, _flipStreak + 1);
        if (now > _burstCooldownMs) {
          _enqueueReaction('⚡');
          _burstCooldownMs = now + 1400;
        }
      } else {
        _flipStreak = math.max(0, _flipStreak - 1);
      }
      _lastLeadId = lead;
    }

    final dv = (total - _lastTotal).abs();
    _lastTotal = total;
    final microBurst = (dv >= 3 && vel01 > 0.45);

    if (microBurst && now > _burstCooldownMs) {
      _enqueueReaction('🔥');
      _burstCooldownMs = now + 900;
    }
    if (gap01 > 0.42 && share > 0.38 && now > _burstCooldownMs) {
      _enqueueReaction('👏');
      _burstCooldownMs = now + 1600;
    }

    final mass = (math.log(1 + total) / math.log(1 + 80)).clamp(0.0, 1.0);
    final flipNudge = (flip ? 0.14 : 0.0) + _flipStreak * 0.02;

    var next = (mass * 0.22 + share * 0.28 + gap01 * 0.18 + vel01 * 0.26 + surge01 * 0.12 + flipNudge * 0.14)
        .clamp(0.08, 1.0);

    final my = s.myVotedPlayerId;
    if (my != null && my.isNotEmpty && lead == my && total > 2) {
      next = math.min(1.0, next + 0.06);
    }

    final breath = 0.5 + 0.5 * math.sin(now / 920);
    final fp = (0.45 * next + 0.55 * breath).clamp(0.12, 1.0);

    final shakeTarget = (vel01 * 0.55 + surge01 * 0.45 + (flip ? 0.35 : 0.0)).clamp(0.0, 1.0);

    _softSet(next, fp, shakeTarget);
  }

  void _enqueueReaction(String e) {
    _reactionQueue.add(e);
    while (_reactionQueue.length > 4) {
      _reactionQueue.removeAt(0);
    }
  }

  /// ردود عاطفية لمرة واحدة لكل تحديث حالة — يفرغ الطابور.
  List<String> pullReactionEmojis() {
    if (_reactionQueue.isEmpty) return const [];
    final out = List<String>.from(_reactionQueue);
    _reactionQueue.clear();
    return out;
  }

  void _softSet(double m, double fp, double shake) {
    _momentum = m;
    _fanPulse = 0.82 * _fanPulse + 0.18 * fp;
    _screenShake = 0.86 * _screenShake + 0.14 * shake;
    if (_screenShake < 0.04) {
      _screenShake = 0;
    }
    notifyListeners();
  }
}
