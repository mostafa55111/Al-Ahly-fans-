/// كشف شذوذ جلسة التصويت (debug / حماية).
class SessionAnomalyDetector {
  int rapidVoteBursts = 0;
  int shardImbalanceFlags = 0;
  int replayPatternFlags = 0;

  bool flagVoteFlood({required int votesInWindow, int threshold = 12}) {
    if (votesInWindow < threshold) return false;
    rapidVoteBursts++;
    return true;
  }

  bool flagShardImbalance({required int maxShard, required int minShard}) {
    if (maxShard <= 0) return false;
    if (maxShard > minShard * 50) {
      shardImbalanceFlags++;
      return true;
    }
    return false;
  }

  bool flagReplayPattern({required int duplicateAttempts}) {
    if (duplicateAttempts < 3) return false;
    replayPatternFlags++;
    return true;
  }

  void reset() {
    rapidVoteBursts = 0;
    shardImbalanceFlags = 0;
    replayPatternFlags = 0;
  }
}
