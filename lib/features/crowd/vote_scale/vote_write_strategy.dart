/// استراتيجية كتابة الصوت — single-node اليوم، sharded لاحقاً.
abstract class VoteWriteStrategy {
  String userVotePath({
    required String clubTag,
    required String matchId,
    required String uid,
  });
}

class SingleNodeVoteWriteStrategy implements VoteWriteStrategy {
  const SingleNodeVoteWriteStrategy();

  @override
  String userVotePath({
    required String clubTag,
    required String matchId,
    required String uid,
  }) =>
      'match_votes/${clubTag.trim().toLowerCase()}/user_votes/$matchId/$uid';
}

/// مسار مستقبلي عند تفعيل الشاردات (غير مفعّل).
class ShardedVoteWriteStrategy implements VoteWriteStrategy {
  const ShardedVoteWriteStrategy(this.allocator);

  final dynamic allocator;

  @override
  String userVotePath({
    required String clubTag,
    required String matchId,
    required String uid,
  }) {
    throw UnimplementedError('Sharded vote writes are not enabled yet');
  }
}
