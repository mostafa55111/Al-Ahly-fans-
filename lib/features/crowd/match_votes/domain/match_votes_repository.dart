import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// لقطة لحظية من RTDB لشاشة التصويت.
class MatchVotesBundle {
  const MatchVotesBundle({
    this.match,
    this.players = const [],
  });

  final MatchActiveSession? match;
  final List<MatchPitchPlayer> players;

  int get totalVotes => players.fold<int>(0, (a, p) => a + p.votes);

  String? get leadingPlayerId {
    if (players.isEmpty) return null;
    var best = players.first;
    for (final p in players.skip(1)) {
      if (p.votes > best.votes) best = p;
    }
    return best.votes > 0 ? best.id : null;
  }
}

/// مستودع تصويت المباراة — Realtime Database فقط (لا بيانات وهمية).
abstract class MatchVotesRepository {
  Stream<MatchVotesBundle> watchBundle(String clubTag);

  /// قراءة لمرة واحدة — للإغلاق والتجميع فقط.
  Future<MatchVotesBundle> getBundle(String clubTag);

  Stream<String?> watchMyVotedPlayerId(
    String clubTag,
    String uid, {
    String? matchId,
  });

  /// بث الجلسة فقط — أخف من جذر `match_votes/{club}`.
  Stream<MatchActiveSession?> watchActiveSession(String clubTag);

  /// بث اللاعبين (يشمل تحديثات التخطيط؛ الأصوات تُخفى في الـ UI أثناء التصويت).
  Stream<List<MatchPitchPlayer>> watchPlayers(String clubTag);

  /// تسجيل صوت لمرة واحدة عبر transaction فقط — غير قابل للتعديل.
  Future<void> castVoteImmutableTransaction({
    required String clubTag,
    required String matchId,
    required String playerId,
    required String uid,
  });

  /// @deprecated استخدم [castVoteImmutableTransaction]
  Future<void> castVote({
    required String clubTag,
    required String matchId,
    required String playerId,
    required String uid,
  });

  Future<void> adminSetActiveMatch({
    required String clubTag,
    required MatchActiveSession session,
  });

  Future<void> adminSetVotingEnabled(String clubTag, bool enabled);

  Future<void> adminSetVotingFrozen({
    required String clubTag,
    required bool frozen,
  });

  /// تفعيل التصويت مع طوابع خادم Firebase.
  Future<void> adminOpenVotingSession({
    required String clubTag,
    required int closesAtServerMs,
  });

  /// تحديث حالة الجلسة (draft/live/closing/finalizing/closed).
  Future<void> adminUpdateSessionStatus({
    required String clubTag,
    required String status,
    bool? votingEnabled,
  });

  Future<void> adminUpsertPlayer({
    required String clubTag,
    required MatchPitchPlayer player,
  });

  Future<void> adminRemovePlayer(String clubTag, String playerId);

  /// حذف كل لاعبي جلسة التصويت (لا يمسّ user_votes — استخدم مع [adminResetVotes] إن لزم).
  Future<void> adminRemoveAllPlayers(String clubTag);

  Future<void> adminResetVotes(String clubTag);

  Future<void> adminApplyFormation({
    required String clubTag,
    required String formation,
    required List<String> orderedPlayerIds,
  });
}
