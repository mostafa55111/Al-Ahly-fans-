import 'dart:collection';

/// يحدّ من محاولات التصويت السريعة المتكررة.
class VoteVelocityGuard {
  VoteVelocityGuard({
    this.maxAttemptsPerWindow = 6,
    this.windowMs = 8000,
  });

  final int maxAttemptsPerWindow;
  final int windowMs;

  final Queue<int> _attemptTimestamps = Queue();

  bool allowAttempt(int nowMs) {
    _prune(nowMs);
    if (_attemptTimestamps.length >= maxAttemptsPerWindow) {
      return false;
    }
    _attemptTimestamps.add(nowMs);
    return true;
  }

  void _prune(int nowMs) {
    while (_attemptTimestamps.isNotEmpty &&
        nowMs - _attemptTimestamps.first > windowMs) {
      _attemptTimestamps.removeFirst();
    }
  }

  void reset() => _attemptTimestamps.clear();
}
