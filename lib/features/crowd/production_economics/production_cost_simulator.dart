import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';

enum CostSimulationScale {
  fans10k,
  fans100k,
  fans1m,
}

/// محاكاة تكلفة — debug/profile فقط.
class ProductionCostSimulator {
  ProductionCostSimulator._();

  static final ProductionCostSimulator instance = ProductionCostSimulator._();

  @visibleForTesting
  static bool forceEnabledForTests = false;

  Map<String, dynamic> simulate(CostSimulationScale scale) {
    if (!forceEnabledForTests &&
        !ProductionSurfaceGate.allowRuntimeDiagnostics) {
      return const {'enabled': false};
    }
    final fans = switch (scale) {
      CostSimulationScale.fans10k => 10000,
      CostSimulationScale.fans100k => 100000,
      CostSimulationScale.fans1m => 1000000,
    };

    final votesPerMinute = (fans * 0.12).round();
    final readsPerMinute = (fans * 0.35).round() + votesPerMinute;
    final writesPerMinute = votesPerMinute;
    final shardWritesPerMinute = (writesPerMinute * 0.4).round();
    final imageBandwidthMbps = (fans * 0.0008).clamp(1.0, 500.0);
    final reconnectSpikeReads = (fans * 0.05).round();

    final redZones = <String>[];
    if (readsPerMinute > 200000) redZones.add('rtdb_reads');
    if (writesPerMinute > 80000) redZones.add('vote_writes');
    if (shardWritesPerMinute > 40000) redZones.add('shard_fanout');
    if (imageBandwidthMbps > 120) redZones.add('image_bandwidth');
    if (reconnectSpikeReads > 50000) redZones.add('reconnect_hydration');

    return {
      'enabled': true,
      'scale': scale.name,
      'virtualFans': fans,
      'estimatesPerMinute': {
        'rtdbReads': readsPerMinute,
        'rtdbWrites': writesPerMinute,
        'shardWrites': shardWritesPerMinute,
        'imageBandwidthMbps': imageBandwidthMbps,
        'reconnectSpikeReads': reconnectSpikeReads,
      },
      'redZones': redZones,
      'scalingRisks': [
        if (redZones.contains('rtdb_reads'))
          'HallOfFame + players stream at scale',
        if (redZones.contains('reconnect_hydration'))
          'Resume storm without phased restore',
        if (redZones.contains('image_bandwidth'))
          'Full card promotion on low-end devices',
      ],
    };
  }

  Map<String, dynamic> compareAllScales() {
    if (!kDebugMode && !ProductionSurfaceGate.allowRuntimeDiagnostics) {
      return const {'enabled': false};
    }
    return {
      'fans10k': simulate(CostSimulationScale.fans10k),
      'fans100k': simulate(CostSimulationScale.fans100k),
      'fans1m': simulate(CostSimulationScale.fans1m),
    };
  }
}
