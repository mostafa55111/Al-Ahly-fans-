import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_health_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/device_validation/device_compatibility_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident_store.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/authority_verification_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/endurance_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/media_pressure_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/production_readiness_evaluator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/shard_distribution_analyzer.dart';

enum GoLiveReadinessClass {
  internalOnly,
  limitedBeta,
  controlledLaunch,
  productionReady,
  massEventReady,
}

class GoLiveReadinessResult {
  const GoLiveReadinessResult({
    required this.score,
    required this.classification,
    required this.categories,
  });

  final int score;
  final GoLiveReadinessClass classification;
  final Map<String, double> categories;
}

class GoLiveReadinessEvaluator {
  GoLiveReadinessResult evaluate({
    ProductionReadinessResult? phase6,
    List<DeviceCompatibilityReport>? deviceReports,
    ProductionIncidentStore? incidents,
  }) {
    final categories = <String, double>{};

    final phase6Score = phase6?.score ?? 70;
    categories['stability'] = phase6Score.toDouble();

    final authority = AuthorityVerificationReport.instance;
    categories['authoritySafety'] = (100 -
            authority.hybridMismatches * 20 -
            authority.localFallbacks * 3)
        .clamp(0, 100)
        .toDouble();

    final reconnect = ReconnectStormReport.instance;
    categories['reconnectResilience'] =
        (reconnect.stabilizationRate * 100).clamp(0, 100);

    final cost = FirebaseCostGuard.instance;
    categories['firebasePressure'] = switch (cost.level) {
      CostPressureLevel.normal => 95,
      CostPressureLevel.elevated => 75,
      CostPressureLevel.high => 50,
      CostPressureLevel.critical => 25,
    }.toDouble();

    final health = RuntimeHealthReport.instance;
    categories['crashRate'] = health.finalizeAttempts <= 0
        ? 88
        : (health.finalizeSuccess / health.finalizeAttempts * 100)
            .clamp(0, 100);

    final endurance = EnduranceRuntimeReport.instance;
    categories['memorySafety'] = endurance.listenerLeaksDetected == 0
        ? 90
        : 40;

    final criticalOpen =
        incidents?.criticalUnacknowledged.length ?? 0;
    categories['operationalRecovery'] =
        (100 - criticalOpen * 25).clamp(0, 100).toDouble();

    final env = CrowdEnvironmentResolver.isBootstrapped &&
            CrowdEnvironmentResolver.current.isProductionData
        ? 92
        : 70;
    categories['deploymentSafety'] = env.toDouble();

    if (deviceReports != null && deviceReports.isNotEmpty) {
      final passRate = deviceReports.where((r) => r.passed).length /
          deviceReports.length;
      categories['deviceCompatibility'] = passRate * 100;
    } else {
      categories['deviceCompatibility'] = 65;
    }

    final media = MediaPressureReport.instance;
    categories['mediaSafety'] =
        (100 - media.decodeSlowFrames * 2).clamp(0, 100).toDouble();

    final avg = categories.values.fold<double>(0, (a, b) => a + b) /
        categories.length;
    final score = avg.round().clamp(0, 100);

    return GoLiveReadinessResult(
      score: score,
      classification: _classify(score),
      categories: categories,
    );
  }

  GoLiveReadinessResult evaluateQuick() {
    final shard = ShardDistributionAnalyzer().analyze(
      uids: List.generate(500, (i) => 'uid_$i'),
      clubTag: 'launch_probe',
    );
    final phase6 = ProductionReadinessEvaluator().evaluate(shardHealth: shard);
    return evaluate(phase6: phase6);
  }

  GoLiveReadinessClass _classify(int score) {
    if (score >= 92) return GoLiveReadinessClass.massEventReady;
    if (score >= 84) return GoLiveReadinessClass.productionReady;
    if (score >= 72) return GoLiveReadinessClass.controlledLaunch;
    if (score >= 55) return GoLiveReadinessClass.limitedBeta;
    return GoLiveReadinessClass.internalOnly;
  }
}
