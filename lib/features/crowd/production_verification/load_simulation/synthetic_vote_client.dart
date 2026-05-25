import 'dart:math';

import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/load_simulation/synthetic_vote_scenario.dart';

class SyntheticVoteClient {
  SyntheticVoteClient({
    required this.fanId,
    required this.scenario,
    Random? random,
    this.baseLatencyMs = 40,
    this.latencyJitterMs = 120,
  }) : _random = random ?? Random(fanId.hashCode);

  final String fanId;
  final SyntheticVoteScenario scenario;
  final int baseLatencyMs;
  final int latencyJitterMs;
  final Random _random;

  int votesCast = 0;
  int reconnects = 0;
  int failures = 0;

  Duration simulatedNetworkLatency() {
    return Duration(
      milliseconds: baseLatencyMs + _random.nextInt(latencyJitterMs),
    );
  }

  bool shouldReconnect() => _random.nextDouble() < scenario.reconnectProbability;

  Future<bool> attemptVote({
    required Future<bool> Function(String fanId) voteAction,
  }) async {
    await Future<void>.delayed(simulatedNetworkLatency());
    if (shouldReconnect()) {
      reconnects++;
      await Future<void>.delayed(Duration(milliseconds: 80 + _random.nextInt(400)));
    }
    try {
      final ok = await voteAction(fanId);
      if (ok) votesCast++;
      return ok;
    } catch (_) {
      failures++;
      return false;
    }
  }
}
