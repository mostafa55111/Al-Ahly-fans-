import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/deterministic_vote_allocator.dart';

/// تخصيص شارد للكتابة — جاهز للتوسع دون تفعيل الهجرة بعد.
abstract class VoteShardAllocator {
  String shardForUser({required String clubTag, required String uid});
}

/// وضع العقدة الواحدة الحالي (بدون شاردات).
class SingleNodeVoteShardAllocator implements VoteShardAllocator {
  const SingleNodeVoteShardAllocator();

  @override
  String shardForUser({required String clubTag, required String uid}) => 'default';
}

/// مستقبلي: توزيع uid على N شارد.
class ShardedVoteShardAllocator implements VoteShardAllocator {
  ShardedVoteShardAllocator({required this.shardCount})
      : assert(shardCount > 0);

  final int shardCount;

  @override
  String shardForUser({required String clubTag, required String uid}) {
    return DeterministicVoteAllocator.allocate(
      clubTag: clubTag,
      matchId: '',
      playerId: '',
      uid: uid,
      shardCount: shardCount,
    ).shardId;
  }
}
