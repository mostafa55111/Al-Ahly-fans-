import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/authority_verification_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/load_simulation/synthetic_load_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/load_simulation/synthetic_vote_scenario.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/media_pressure_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/production_readiness_evaluator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/production_verification_hub.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/shard_distribution_analyzer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/verification_sandbox_guard.dart';

void main() {
  group('VerificationSandboxGuard', () {
    test('accepts sandbox prefixes', () {
      expect(VerificationSandboxGuard.isSandboxSessionId('sandbox_x'), isTrue);
      expect(VerificationSandboxGuard.isSandboxSessionId('verify_run'), isTrue);
      expect(VerificationSandboxGuard.isSandboxSessionId('loadtest_peak'), isTrue);
    });

    test('rejects production-like session ids', () {
      expect(VerificationSandboxGuard.isSandboxSessionId('match_123'), isFalse);
      expect(
        () => VerificationSandboxGuard.assertSandboxSession('live_match'),
        throwsStateError,
      );
    });

    test('newSandboxSessionId uses sandbox prefix', () {
      final id = VerificationSandboxGuard.newSandboxSessionId('peak');
      expect(VerificationSandboxGuard.isSandboxSessionId(id), isTrue);
    });
  });

  group('ShardDistributionAnalyzer', () {
    test('healthy distribution for spread uids', () {
      final report = ShardDistributionAnalyzer().analyze(
        uids: List.generate(2000, (i) => 'uid_$i'),
        clubTag: 'test_club',
      );
      expect(report.sampleSize, 2000);
      expect(report.isHealthy, isTrue);
      expect(report.entropyBits, greaterThan(3.5));
    });
  });

  group('ProductionReadinessEvaluator', () {
    setUp(() {
      ReconnectStormReport.instance.reset();
      AuthorityVerificationReport.instance.reset();
      MediaPressureReport.instance.reset();
    });

    test('scores higher with healthy shard report', () {
      final healthy = ShardDistributionAnalyzer().analyze(
        uids: List.generate(1000, (i) => 'fan_$i'),
        clubTag: 'sandbox',
      );
      final result = ProductionReadinessEvaluator().evaluate(
        shardHealth: healthy,
        load: const VoteLoadMetrics(peakVotesPerSecond: 800),
      );
      expect(result.score, greaterThan(40));
      expect(result.factors['shardHealth'], isNotNull);
      expect(result.factors['shardHealth']!, greaterThan(0));
    });
  });

  group('SyntheticLoadCoordinator', () {
    test('runs derby peak within sandbox', () async {
      final coordinator = SyntheticLoadCoordinator();
      final report = await coordinator.run(
        scenario: SyntheticVoteScenario.derbyPeak,
        virtualVoters: 200,
        maxDuration: const Duration(seconds: 2),
        maxVotes: 500,
      );
      expect(report.votesAttempted, greaterThan(0));
      expect(report.sandboxSessionId.startsWith('sandbox_'), isTrue);
    });
  });

  group('ReconnectStormValidator', () {
    setUp(() => ReconnectStormReport.instance.reset());

    test('records stabilization after phased restore waves', () async {
      await ReconnectStormValidator().simulateStorm(waves: 2);
      final snap = ReconnectStormReport.instance.snapshot();
      expect(snap['phasedRestores'], greaterThanOrEqualTo(2));
    });
  });

  group('ProductionVerificationHub', () {
    test('quick suite returns readiness in debug', () async {
      final hub = ProductionVerificationHub();
      final result = await hub.runQuickSuite(virtualVoters: 150);
      expect(result.score, inInclusiveRange(0, 100));
      expect(hub.operationalSnapshot(), isNotEmpty);
    });
  });
}
