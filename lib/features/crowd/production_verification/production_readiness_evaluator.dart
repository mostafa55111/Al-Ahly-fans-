import 'dart:math' as math;

import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_health_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/authority_verification_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/endurance_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/media_pressure_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/shard_distribution_analyzer.dart';

enum ProductionReadinessClass {
  experimental,
  beta,
  productionCandidate,
  productionReady,
  massScaleReady,
}

class ProductionReadinessResult {
  const ProductionReadinessResult({
    required this.score,
    required this.classification,
    required this.factors,
  });

  final int score;
  final ProductionReadinessClass classification;
  final Map<String, double> factors;
}

class ProductionReadinessEvaluator {
  ProductionReadinessResult evaluate({
    ShardDistributionReport? shardHealth,
    VoteLoadMetrics? load,
  }) {
    final factors = <String, double>{};

    final shard = shardHealth;
    factors['shardHealth'] = shard == null
        ? 70
        : (shard.isHealthy ? 95 : math.max(20.0, 95 - shard.skewPercent));

    final reconnect = ReconnectStormReport.instance;
    factors['reconnectStability'] =
        (reconnect.stabilizationRate * 100).clamp(0, 100);

    final authority = AuthorityVerificationReport.instance;
    final divergencePenalty = authority.hybridMismatches * 15;
    factors['authorityAlignment'] =
        (100 - divergencePenalty - authority.localFallbacks * 2)
            .clamp(0, 100)
            .toDouble();

    factors['finalizeReliability'] = RuntimeHealthReport
                .instance.finalizeAttempts <=
            0
        ? 85
        : (RuntimeHealthReport.instance.finalizeSuccess /
                RuntimeHealthReport.instance.finalizeAttempts *
                100)
            .clamp(0, 100);

    factors['cloudLatency'] = authority.averageRemoteMs <= 0
        ? 80
        : (authority.averageRemoteMs < 2000 ? 90 : 55).toDouble();

    final media = MediaPressureReport.instance;
    factors['mediaPressure'] =
        (100 - media.decodeSlowFrames * 2 - media.memoryPressureSignals * 5)
            .clamp(0, 100)
            .toDouble();

    final endurance = EnduranceRuntimeReport.instance;
    factors['memoryStability'] = endurance.cacheStabilized &&
            endurance.listenerLeaksDetected == 0
        ? 92
        : 45;

    if (load != null) {
      factors['loadThroughput'] =
          (load.peakVotesPerSecond / 1000 * 100).clamp(0, 100);
    } else {
      factors['loadThroughput'] = 75;
    }

    final avg = factors.values.fold<double>(0, (a, b) => a + b) / factors.length;
    final score = avg.round().clamp(0, 100);

    return ProductionReadinessResult(
      score: score,
      classification: _classify(score),
      factors: factors,
    );
  }

  ProductionReadinessClass _classify(int score) {
    if (score >= 92) return ProductionReadinessClass.massScaleReady;
    if (score >= 82) return ProductionReadinessClass.productionReady;
    if (score >= 68) return ProductionReadinessClass.productionCandidate;
    if (score >= 45) return ProductionReadinessClass.beta;
    return ProductionReadinessClass.experimental;
  }
}

class VoteLoadMetrics {
  const VoteLoadMetrics({required this.peakVotesPerSecond});

  final double peakVotesPerSecond;
}
