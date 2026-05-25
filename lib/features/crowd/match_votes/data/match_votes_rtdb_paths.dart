/// مسارات تصويت المباراة الموحّدة — جذر منفصل لكل نادٍ داخل `match_votes/`.
///
/// ```
/// match_votes/{ahly|zamalek}/
///   active_match/
///     id, title, votingEnabled, formation, createdAt
///   players/{playerId}/
///     id, name, imageUrl, rating, position, x, y, votes, team, glowColor
///   user_votes/{matchId}/{uid}/   ← مسار التصويت الثابت (مفضّل)
///   user_votes/{uid}/             ← توافق قديم
///     votedPlayerId, timestamp
/// ```
class MatchVotesRtdbPaths {
  static String root(String clubTag) =>
      'match_votes/${clubTag.trim().toLowerCase()}';

  static String activeMatch(String clubTag) => '${root(clubTag)}/active_match';

  static String players(String clubTag) => '${root(clubTag)}/players';

  static String player(String clubTag, String playerId) =>
      '${players(clubTag)}/$playerId';

  static String userVotes(String clubTag) => '${root(clubTag)}/user_votes';

  static String userVote(String clubTag, String uid) =>
      '${userVotes(clubTag)}/$uid';

  /// صوت المستخدم لجلسة محددة — غير قابل للتعديل بعد الكتابة.
  static String userVoteForMatch(
    String clubTag,
    String matchId,
    String uid,
  ) =>
      '${userVotes(clubTag)}/${matchId.trim()}/${uid.trim()}';
}
