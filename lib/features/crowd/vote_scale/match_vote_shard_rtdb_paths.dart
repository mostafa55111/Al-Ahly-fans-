/// مسارات عدّادات الشارد — منفصلة عن `match_votes/` لتقليل الضغط.
///
/// ```
/// match_vote_shards/{club}/{matchId}/{playerId}/{shardId}/count
/// ```
class MatchVoteShardRtdbPaths {
  static String root(String clubTag) =>
      'match_vote_shards/${clubTag.trim().toLowerCase()}';

  static String match(String clubTag, String matchId) =>
      '${root(clubTag)}/${matchId.trim()}';

  static String player(String clubTag, String matchId, String playerId) =>
      '${match(clubTag, matchId)}/${playerId.trim()}';

  static String shardCount(
    String clubTag,
    String matchId,
    String playerId,
    String shardId,
  ) =>
      '${player(clubTag, matchId, playerId)}/${shardId.trim()}/count';
}
