import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/deterministic_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/deterministic_vote_allocator.dart';

/// نوع عملية التصويت — للبصمة الحتمية.
enum VoteOperationType {
  castVote,
  reconnectReplay,
  finalize,
  aggregation,
}

/// بصمة عملية — digest ثابت.
class VoteOperationFingerprint {
  VoteOperationFingerprint({
    required this.uid,
    required this.playerId,
    required this.matchId,
    required this.clubTag,
    required this.operationType,
    required this.createdAtBucket,
  });

  final String uid;
  final String playerId;
  final String matchId;
  final String clubTag;
  final VoteOperationType operationType;

  /// bucket زمني (مثلاً ms / 60000) — يمنع replay ضيق دون منع إعادة محاولة لاحقة.
  final int createdAtBucket;

  String get deterministicDigest {
    final raw =
        '${operationType.name}|${clubTag.trim().toLowerCase()}|$matchId|$playerId|$uid|$createdAtBucket';
    return DeterministicVoteAllocator.fnv1a64Utf8(raw).toRadixString(16).padLeft(16, '0');
  }

  static int bucketFromMs(int epochMs, {int bucketMs = 60000}) {
    if (bucketMs <= 0) return epochMs;
    return epochMs ~/ bucketMs;
  }
}

/// LRU محلي — منع replay / duplicate finalize (debug metrics).
class VoteIdempotencyGuard {
  VoteIdempotencyGuard({this.maxEntries = 4096});

  final int maxEntries;
  final Map<String, int> _order = {};
  int _seq = 0;

  int get size => _order.length;

  /// false = عملية مكررة (محظورة).
  bool tryAcquire(VoteOperationFingerprint fingerprint) {
    final key = fingerprint.deterministicDigest;
    if (_order.containsKey(key)) {
      DeterministicRuntimeReport.instance.recordReplayBlocked();
      return false;
    }
    _evictIfNeeded();
    _order[key] = ++_seq;
    return true;
  }

  void release(VoteOperationFingerprint fingerprint) {
    _order.remove(fingerprint.deterministicDigest);
  }

  void clear() => _order.clear();

  /// عمليات التصويت (محلي — لا يستبدل معاملة RTDB).
  static final VoteIdempotencyGuard castVotes = VoteIdempotencyGuard();

  /// إغلاق الجلسة.
  static final VoteIdempotencyGuard finalize = VoteIdempotencyGuard(maxEntries: 512);

  void _evictIfNeeded() {
    while (_order.length >= maxEntries) {
      String? oldest;
      var minSeq = 0x7FFFFFFFFFFFFFFF;
      _order.forEach((k, seq) {
        if (seq < minSeq) {
          minSeq = seq;
          oldest = k;
        }
      });
      if (oldest == null) break;
      _order.remove(oldest);
    }
  }
}
