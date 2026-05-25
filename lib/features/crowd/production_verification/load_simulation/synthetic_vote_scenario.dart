/// سيناريوهات تحميل اصطناعي — sandbox فقط.
enum SyntheticVoteScenario {
  derbyPeak,
  lastMinuteSpike,
  reconnectStorm,
  shardHotspotAttack,
  delayedFinalize,
  unstableNetworkWave,
}

extension SyntheticVoteScenarioX on SyntheticVoteScenario {
  String get wireName {
    switch (this) {
      case SyntheticVoteScenario.derbyPeak:
        return 'derby_peak';
      case SyntheticVoteScenario.lastMinuteSpike:
        return 'last_minute_spike';
      case SyntheticVoteScenario.reconnectStorm:
        return 'reconnect_storm';
      case SyntheticVoteScenario.shardHotspotAttack:
        return 'shard_hotspot_attack';
      case SyntheticVoteScenario.delayedFinalize:
        return 'delayed_finalize';
      case SyntheticVoteScenario.unstableNetworkWave:
        return 'unstable_network_wave';
    }
  }

  double get baseVotesPerSecond {
    switch (this) {
      case SyntheticVoteScenario.derbyPeak:
        return 2800;
      case SyntheticVoteScenario.lastMinuteSpike:
        return 5200;
      case SyntheticVoteScenario.reconnectStorm:
        return 900;
      case SyntheticVoteScenario.shardHotspotAttack:
        return 1800;
      case SyntheticVoteScenario.delayedFinalize:
        return 400;
      case SyntheticVoteScenario.unstableNetworkWave:
        return 1200;
    }
  }

  double get reconnectProbability {
    switch (this) {
      case SyntheticVoteScenario.reconnectStorm:
        return 0.35;
      case SyntheticVoteScenario.unstableNetworkWave:
        return 0.22;
      default:
        return 0.06;
    }
  }
}
