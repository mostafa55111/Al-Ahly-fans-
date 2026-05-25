import 'dart:convert';

/// نتيجة تخصيص شارد حتمي.
class DeterministicShardAllocationResult {
  const DeterministicShardAllocationResult({
    required this.shardId,
    required this.hash,
    required this.shardCount,
    required this.deterministicKey,
  });

  final String shardId;
  final int hash;
  final int shardCount;
  final String deterministicKey;
}

/// FNV-1a 64-bit — نفس المدخلات => نفس الشارد على كل المنصات.
class DeterministicVoteAllocator {
  DeterministicVoteAllocator._();

  static const int fnvOffsetBasis = 0xcbf29ce484222325;
  static const int fnvPrime = 0x100000001b3;
  static const int defaultShardCount = 32;

  /// UTF-8 FNV-1a — لا يعتمد على `String.hashCode`.
  static int fnv1a64Utf8(String input) {
    var hash = fnvOffsetBasis;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash;
  }

  static int positiveModulo(int hash, int modulus) {
    assert(modulus > 0);
    final unsigned = hash & 0x7FFFFFFFFFFFFFFF;
    return unsigned % modulus;
  }

  /// `clubTag|matchId|playerId|uid` => shardId ثابت.
  static DeterministicShardAllocationResult allocate({
    required String clubTag,
    required String matchId,
    required String playerId,
    required String uid,
    int shardCount = defaultShardCount,
  }) {
    assert(shardCount > 0);
    final club = clubTag.trim().toLowerCase();
    final match = matchId.trim();
    final player = playerId.trim();
    final user = uid.trim();
    final key = '$club|$match|$player|$user';
    final hash = fnv1a64Utf8(key);
    final index = positiveModulo(hash, shardCount);
    return DeterministicShardAllocationResult(
      shardId: 's$index',
      hash: hash,
      shardCount: shardCount,
      deterministicKey: key,
    );
  }
}
