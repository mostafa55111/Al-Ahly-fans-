import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/finalization_audit_trail.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_health_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/authority_verification_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/endurance_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/load_simulation/synthetic_load_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/load_simulation/synthetic_vote_scenario.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/media_pressure_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/production_readiness_evaluator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/endurance_simulator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/shard_distribution_analyzer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/readiness/go_live_readiness_evaluator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/rollback/safe_rollback_coordinator.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/verification_sandbox_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/chaos/chaos_injector.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_runtime_report.dart';

/// نقطة دخول واحدة لتشغيل حزمة التحقق التشغيلي.
class ProductionVerificationHub {
  ProductionVerificationHub({
    SyntheticLoadCoordinator? load,
    ReconnectStormValidator? reconnect,
    EnduranceSimulator? endurance,
    ProductionReadinessEvaluator? readiness,
    ShardDistributionAnalyzer? shards,
  })  : loadCoordinator = load ?? SyntheticLoadCoordinator(),
        reconnectValidator = reconnect ?? ReconnectStormValidator(),
        enduranceSimulator = endurance ?? EnduranceSimulator(),
        readinessEvaluator = readiness ?? ProductionReadinessEvaluator(),
        shardAnalyzer = shards ?? ShardDistributionAnalyzer();

  final SyntheticLoadCoordinator loadCoordinator;
  final ReconnectStormValidator reconnectValidator;
  final EnduranceSimulator enduranceSimulator;
  final ProductionReadinessEvaluator readinessEvaluator;
  final ShardDistributionAnalyzer shardAnalyzer;

  Future<ProductionReadinessResult> runQuickSuite({
    int virtualVoters = 500,
  }) async {
    if (!VerificationSandboxGuard.isVerificationAllowed) {
      throw StateError('verification only in debug');
    }

    await loadCoordinator.run(
      scenario: SyntheticVoteScenario.derbyPeak,
      virtualVoters: virtualVoters,
      maxDuration: const Duration(seconds: 8),
    );
    await reconnectValidator.simulateStorm(waves: 3);
    await enduranceSimulator.run(hours: 1, ticksPerHour: 6);

    final shard = shardAnalyzer.analyze(
      uids: List.generate(virtualVoters, (i) => 'fan_$i'),
      clubTag: 'sandbox',
    );

    final lastLoad = loadCoordinator.reports.isNotEmpty
        ? loadCoordinator.reports.last
        : null;

    return readinessEvaluator.evaluate(
      shardHealth: shard,
      load: lastLoad == null
          ? null
          : VoteLoadMetrics(peakVotesPerSecond: lastLoad.peakVotesPerSecond),
    );
  }

  Map<String, dynamic> operationalSnapshot() {
    if (!kDebugMode) return const {};
    return {
      'runtimeHealth': RuntimeHealthReport.instance.snapshot(),
      'voteScale': VoteScaleRuntimeReport.instance.snapshot(),
      'authority': AuthorityVerificationReport.instance.snapshot(),
      'reconnect': ReconnectStormReport.instance.snapshot(),
      'media': MediaPressureReport.instance.snapshot(),
      'endurance': EnduranceRuntimeReport.instance.snapshot(),
      'finalizeAudit': {
        'localFallbacks': FinalizationAuditTrail.instance.localFallbacks,
        'recent': FinalizationAuditTrail.instance.recent.length,
      },
      'chaosEvents': ChaosInjector.instance.events.length,
      'loadReports': loadCoordinator.reports.length,
      if (CrowdEnvironmentResolver.isBootstrapped)
        'environment': CrowdEnvironmentResolver.current.toJson(),
      if (ReleaseChannelResolver.isBootstrapped)
        'releaseChannel': ReleaseChannelResolver.current.wireName,
      'costGuard': FirebaseCostGuard.instance.snapshot(),
      if (getIt.isRegistered<SafeRollbackCoordinator>())
        'rollback': getIt<SafeRollbackCoordinator>().snapshot(),
      'goLive': GoLiveReadinessEvaluator().evaluateQuick().categories,
    };
  }
}
