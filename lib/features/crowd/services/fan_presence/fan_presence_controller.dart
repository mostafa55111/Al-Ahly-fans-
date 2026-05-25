import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/fan_presence/fan_crowd_rank_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/fan_presence/fan_legacy_moment.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/fan_presence/fan_presence_profile.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/fan_presence/fan_presence_store.dart';

/// تحكم بحضور المشجع — لا يُستمع له من AnimatedBuilder الرئيسي للملعب.
class FanPresenceController extends ChangeNotifier {
  FanPresenceController({
    required FanPresenceStore store,
    required bool isAhlyClub,
  })  : _store = store,
        _isAhlyClub = isAhlyClub;

  final FanPresenceStore _store;
  final bool _isAhlyClub;

  FanPresenceProfile? _profile;
  FanCrowdRank _rank = FanCrowdRank.rookie;
  FanPresenceAuraStyle _aura = const FanPresenceAuraStyle(
    strength: 0.1,
    pulseSpeed: 1,
    reactionBias: ['👏'],
    prioritySync: false,
  );

  String? _uid;
  String? _lastMatchId;
  int _lastObservedTotal = 0;
  String? _lastObservedLeader;
  bool _matchCounted = false;

  FanPresenceProfile? get profile => _profile;

  FanCrowdRank get rank => _rank;

  FanPresenceAuraStyle get aura => _aura;

  String get rankTitle => FanCrowdRankSystem.title(_rank, isAhlyClub: _isAhlyClub);

  bool get isActive => _profile != null && _uid != null;

  Future<void> bind(String? uid) async {
    _uid = uid;
    if (uid == null || uid.isEmpty) {
      _profile = null;
      _recomputeMeta();
      notifyListeners();
      return;
    }
    _profile = await _store.load(uid);
    _profile ??= FanPresenceProfile(createdAtMs: DateTime.now().millisecondsSinceEpoch);
    _touchAttendance();
    await _persist();
  }

  void onStadiumSessionOpened(String? matchId) {
    if (matchId == null || matchId.isEmpty) return;
    if (_lastMatchId == matchId) return;
    _lastMatchId = matchId;
    _matchCounted = false;
    _lastObservedTotal = 0;
    _lastObservedLeader = null;
  }

  /// مراقبة خفيفة لحظات legacy — يُستدعى من BlocListener (ليس كل frame).
  void observeMatchState(MatchVotingState state) {
    final p = _profile;
    if (p == null) return;
    final match = state.match;
    if (match == null || match.id.isEmpty) return;

    if (!_matchCounted) {
      _matchCounted = true;
      p.matchParticipationCount++;
    }

    final total = state.totalVotes;
    final lead = state.leadingPlayerId;
    final my = state.myVotedPlayerId;

    if (lead != null && my == lead && total > 0 && total <= 12 && _lastObservedTotal < total) {
      _addLegacy(
        FanLegacyMoment(
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          playerId: lead,
          eventType: FanLegacyEventType.earlyLeaderPick,
          emotionalScore: 0.72,
          matchId: match.id,
        ),
      );
    }

    if (_lastObservedLeader != null &&
        lead != null &&
        _lastObservedLeader != lead &&
        my == lead) {
      _addLegacy(
        FanLegacyMoment(
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          playerId: lead,
          eventType: FanLegacyEventType.comebackPick,
          emotionalScore: 0.8,
          matchId: match.id,
        ),
      );
    }

    if (total - _lastObservedTotal >= 8 && _lastObservedTotal > 0) {
      _addLegacy(
        FanLegacyMoment(
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          eventType: FanLegacyEventType.voteBurstWitness,
          emotionalScore: 0.65,
          matchId: match.id,
        ),
      );
    }

    if (lead != null && total > 20) {
      var leadVotes = 0;
      for (final x in state.players) {
        if (x.id == lead) {
          leadVotes = x.votes;
          break;
        }
      }
      if (leadVotes / total > 0.45) {
        _addLegacy(
          FanLegacyMoment(
            timestampMs: DateTime.now().millisecondsSinceEpoch,
            playerId: lead,
            eventType: FanLegacyEventType.dominanceWave,
            emotionalScore: 0.7,
            matchId: match.id,
          ),
          cooldownMs: 120000,
        );
      }
    }

    _lastObservedTotal = total;
    _lastObservedLeader = lead;
    _persist();
  }

  Future<void> recordVote({
    required String playerId,
    required String playerName,
    required String matchId,
    required bool pickedCurrentLeader,
    required int totalVotesAfter,
  }) async {
    final p = _profile;
    if (p == null) return;

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final hour = now.hour;

    p.totalVotes++;
    p.voteStreak = math.min(999, p.voteStreak + 1);
    p.favoritePlayers[playerId] = (p.favoritePlayers[playerId] ?? 0) + 1;
    if (pickedCurrentLeader) {
      p.leaderVotes++;
    }
    p.lastActiveAtMs = nowMs;
    p.preferredHourBucket = ((p.preferredHourBucket * 3 + hour) / 4).round().clamp(0, 23);
    if (totalVotesAfter <= 8) {
      p.fastReactionCount++;
    }

    p.emotionalEngagementScore = (p.emotionalEngagementScore * 0.82 + 0.18 * (0.55 + p.voteStreak * 0.04))
        .clamp(0.1, 1.0);

    _touchAttendance();
    _checkStreakLegacy(matchId, playerId, playerName);
    await _persist(notify: true);
  }

  void _checkStreakLegacy(String matchId, String playerId, String playerName) {
    final p = _profile;
    if (p == null) return;
    const milestones = {3, 7, 14, 30};
    if (!milestones.contains(p.voteStreak)) return;
    _addLegacy(
      FanLegacyMoment(
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        playerId: playerId,
        playerName: playerName,
        eventType: FanLegacyEventType.streakMilestone,
        emotionalScore: 0.75,
        matchId: matchId,
      ),
    );
  }

  void _addLegacy(FanLegacyMoment moment, {int cooldownMs = 45000}) {
    final p = _profile;
    if (p == null) return;
    final recent = p.legacyMoments.where(
      (m) =>
          m.eventType == moment.eventType &&
          DateTime.now().millisecondsSinceEpoch - m.timestampMs < cooldownMs,
    );
    if (recent.isNotEmpty) return;
    p.legacyMoments.insert(0, moment);
    while (p.legacyMoments.length > 24) {
      p.legacyMoments.removeLast();
    }
    p.emotionalEngagementScore = math.min(1.0, p.emotionalEngagementScore + 0.04);
  }

  void _touchAttendance() {
    final p = _profile;
    if (p == null) return;
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    if (p.lastAttendanceDayKey != dayKey) {
      p.lastAttendanceDayKey = dayKey;
      p.attendanceDays++;
    }
    if (p.createdAtMs <= 0) {
      p.createdAtMs = now.millisecondsSinceEpoch;
    }
    final ageDays = now.difference(DateTime.fromMillisecondsSinceEpoch(p.createdAtMs)).inDays;
    p.accountAgeDays = math.max(0, ageDays);
  }

  Future<void> _persist({bool notify = false}) async {
    final p = _profile;
    if (p == null) return;
    p.crowdLevel = FanCrowdRankSystem.crowdLevelFor(p);
    _recomputeMeta();
    await _store.save(p);
    if (notify) {
      notifyListeners();
    }
  }

  void _recomputeMeta() {
    final p = _profile;
    if (p == null) {
      _rank = FanCrowdRank.rookie;
      _aura = const FanPresenceAuraStyle(
        strength: 0.08,
        pulseSpeed: 1,
        reactionBias: ['👏'],
        prioritySync: false,
      );
      return;
    }
    _rank = FanCrowdRankSystem.rankFor(p);
    _aura = FanCrowdRankSystem.auraFor(p, _rank);
    if (_isAhlyClub && _rank == FanCrowdRank.ultraElite) {
      _aura = FanPresenceAuraStyle(
        strength: _aura.strength,
        pulseSpeed: _aura.pulseSpeed,
        reactionBias: const ['🔥', '⚡', '🦅'],
        prioritySync: _aura.prioritySync,
      );
    } else if (!_isAhlyClub && _rank == FanCrowdRank.ultraElite) {
      _aura = FanPresenceAuraStyle(
        strength: _aura.strength,
        pulseSpeed: _aura.pulseSpeed,
        reactionBias: const ['🔥', '⚡', '🐎'],
        prioritySync: _aura.prioritySync,
      );
    }
  }

  /// رمز عاطفي مفضّل عند رد فعل المستخدم (تصويت).
  String pickPersonalReaction(math.Random r) {
    final bias = _aura.reactionBias;
    if (bias.isEmpty) return '👏';
    return bias[r.nextInt(bias.length)];
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }
}
