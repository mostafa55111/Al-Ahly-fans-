import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';

/// شدة الجو (0..1) للصوت وتأثيرات الملعب — لا يمس منطق التصويت.
class CrowdIntensityController extends ChangeNotifier {
  CrowdIntensityController();

  double _value = 0.28;
  int _lastTotal = 0;
  int _lastTickMs = 0;

  double get value => _value;

  void reset() {
    _value = 0.28;
    _lastTotal = 0;
    _lastTickMs = 0;
    notifyListeners();
  }

  void updateFromMatchState(MatchVotingState s) {
    if (s.loading || s.match == null || s.match!.id.isEmpty) {
      if (_value != 0.22) {
        _value = 0.22;
        notifyListeners();
      }
      return;
    }

    final players = s.players.where((p) => p.visible).toList();
    final total = s.totalVotes;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = math.max(40, now - (_lastTickMs == 0 ? now : _lastTickMs));
    _lastTickMs = now;

    final dv = (total - _lastTotal).abs();
    _lastTotal = total;
    final rate = dv / dt * 1000.0;

    var leadV = 0;
    var secondV = 0;
    if (players.isNotEmpty) {
      final sorted = List<MatchPitchPlayer>.from(players)..sort((a, b) => b.votes.compareTo(a.votes));
      leadV = sorted.first.votes;
      secondV = sorted.length > 1 ? sorted[1].votes : 0;
    }
    final gap = (leadV - secondV).clamp(0, total);
    final share = total > 0 ? leadV / total : 0.0;

    final mass = (math.log(1 + total) / math.log(1 + 42)).clamp(0.0, 1.0);
    final pace = (rate / 14).clamp(0.0, 1.0);
    final leadDom = total > 0 ? (gap / total).clamp(0.0, 1.0) : 0.0;

    final next = (mass * 0.28 + share * 0.34 + leadDom * 0.22 + pace * 0.16).clamp(0.08, 1.0);
    if ((next - _value).abs() > 0.015) {
      _value = next;
      notifyListeners();
    }
  }
}
