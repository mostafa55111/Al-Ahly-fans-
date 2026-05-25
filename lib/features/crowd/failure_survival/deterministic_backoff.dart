import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/deterministic_vote_allocator.dart';

/// تأخير exponential + jitter حتمي — بدون Random ولا DateTime.now.
class DeterministicBackoff {
  const DeterministicBackoff({
    this.baseMs = 400,
    this.maxMs = 60000,
    this.maxAttempts = 8,
  });

  final int baseMs;
  final int maxMs;
  final int maxAttempts;

  int delayMsForAttempt({
    required String operationId,
    required int attempt,
  }) {
    if (attempt <= 0) return 0;
    if (attempt > maxAttempts) return maxMs;
    final hash = DeterministicVoteAllocator.fnv1a64Utf8('$operationId|$attempt');
    final exp = baseMs * (1 << (attempt - 1).clamp(0, 10));
    final capped = exp > maxMs ? maxMs : exp;
    final jitter = hash % 401;
    return capped + jitter;
  }

  bool shouldRetry(int attempt) => attempt < maxAttempts;
}
