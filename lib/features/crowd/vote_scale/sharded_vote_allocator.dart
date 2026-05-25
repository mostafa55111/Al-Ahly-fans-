import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/deterministic_vote_allocator.dart';

/// توزيع كتابة الصوت على شاردات — حتمي 100% (FNV-1a).
class ShardedVoteAllocator {
  ShardedVoteAllocator({
    this.shardCount = DeterministicVoteAllocator.defaultShardCount,
  }) : assert(shardCount > 0);

  final int shardCount;

  /// نفس club + match + player + uid => نفس shardId دائماً.
  String pickShardId({
    required String uid,
    required String clubTag,
    String? matchId,
    String? playerId,
  }) {
    return DeterministicVoteAllocator.allocate(
      clubTag: clubTag,
      matchId: matchId ?? '',
      playerId: playerId ?? '',
      uid: uid,
      shardCount: shardCount,
    ).shardId;
  }

  DeterministicShardAllocationResult allocate({
    required String uid,
    required String clubTag,
    required String matchId,
    required String playerId,
  }) {
    return DeterministicVoteAllocator.allocate(
      clubTag: clubTag,
      matchId: matchId,
      playerId: playerId,
      uid: uid,
      shardCount: shardCount,
    );
  }

  /// للاختبارات — توزيع محاكى على عيّنة من uids.
  Map<String, int> simulateDistribution({
    required Iterable<String> uids,
    required String clubTag,
    String matchId = '_sim_match',
    String playerId = '_sim_player',
  }) {
    final counts = <String, int>{};
    for (final uid in uids) {
      final id = pickShardId(
        uid: uid,
        clubTag: clubTag,
        matchId: matchId,
        playerId: playerId,
      );
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }
}
