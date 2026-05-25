import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/match_vote_shard_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/models/sharded_vote_write.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/sharded_vote_allocator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_metrics.dart';

/// كتابة/قراءة عدّادات الشارد — لا تلمس `players/{id}/votes` أثناء التصويت الحي.
class ShardedVoteRepository {
  ShardedVoteRepository(
    this._db, {
    ShardedVoteAllocator? allocator,
  }) : _allocator = allocator ?? ShardedVoteAllocator();

  final FirebaseDatabase _db;
  final ShardedVoteAllocator _allocator;

  ShardedVoteAllocator get allocator => _allocator;

  Future<ShardedVoteWrite> incrementShard({
    required String clubTag,
    required String matchId,
    required String playerId,
    required String uid,
  }) async {
    VoteScaleMetrics.instance.recordShardWriteAttempt();
    final shardId = _allocator.pickShardId(
      uid: uid,
      clubTag: clubTag,
      matchId: matchId,
      playerId: playerId,
    );
    final ref = _db.ref(
      MatchVoteShardRtdbPaths.shardCount(
        clubTag,
        matchId,
        playerId,
        shardId,
      ),
    );
    try {
      await ref.set(ServerValue.increment(1));
      VoteScaleMetrics.instance.recordShardWriteSuccess();
      return ShardedVoteWrite(
        committed: true,
        shardId: shardId,
        playerId: playerId,
        matchId: matchId,
      );
    } catch (e) {
      VoteScaleMetrics.instance.recordFailedWrite(e);
      return ShardedVoteWrite.failure(e.toString());
    }
  }

  Future<void> rollbackShardIncrement({
    required String clubTag,
    required String matchId,
    required String playerId,
    required String shardId,
  }) async {
    if (shardId.isEmpty) return;
    try {
      final ref = _db.ref(
        MatchVoteShardRtdbPaths.shardCount(
          clubTag,
          matchId,
          playerId,
          shardId,
        ),
      );
      await ref.set(ServerValue.increment(-1));
      VoteScaleMetrics.instance.recordShardWriteRollback();
    } catch (e) {
      VoteScaleMetrics.instance.recordFailedWrite(e);
    }
  }

  /// تجميع كل شاردات لاعب واحد.
  Future<int> sumPlayerShards({
    required String clubTag,
    required String matchId,
    required String playerId,
  }) async {
    final snap = await _db
        .ref(MatchVoteShardRtdbPaths.player(clubTag, matchId, playerId))
        .get();
    if (!snap.exists || snap.value is! Map) return 0;
    var total = 0;
    Map<dynamic, dynamic>.from(snap.value! as Map).forEach((_, raw) {
      if (raw is! Map) return;
      final c = Map<dynamic, dynamic>.from(raw)['count'];
      if (c is int) {
        total += c;
      } else if (c is num) {
        total += c.toInt();
      }
    });
    return total;
  }

  /// تجميع كل اللاعبين في الجلسة — للإغلاق فقط.
  Future<Map<String, int>> aggregateMatchShards({
    required String clubTag,
    required String matchId,
    required Iterable<String> playerIds,
  }) async {
    final totals = <String, int>{};
    for (final pid in playerIds) {
      if (pid.isEmpty) continue;
      totals[pid] = await sumPlayerShards(
        clubTag: clubTag,
        matchId: matchId,
        playerId: pid,
      );
    }
    return totals;
  }

  Future<bool> hasAnyShardData({
    required String clubTag,
    required String matchId,
  }) async {
    final snap = await _db.ref(MatchVoteShardRtdbPaths.match(clubTag, matchId)).get();
    return snap.exists && snap.value != null;
  }
}
