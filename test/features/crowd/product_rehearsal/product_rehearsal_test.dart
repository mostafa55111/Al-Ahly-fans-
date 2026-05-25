import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_stability_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/owner_security_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/runtime_owner_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/cold_start_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/firebase_production_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/launch_day_chaos_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/match_day_simulation_runner.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/owner_matchday_protocol.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/production_recovery_drill.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/release_build_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/soft_launch_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/read_budget_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/chaos/chaos_injector.dart';

void main() {
  setUp(() {
    RuntimeOwnerGuard.instance.reset();
    RuntimeOwnerGuard.instance.seedFromLaunchMatrix();
    LaunchStabilitySuite.instance.reset();
    ProductionFeatureFreeze.instance.resetForTests();
    OwnerSecurityAudit.instance.runReleaseChecks();
    ColdStartAudit.instance.reset();
    MatchDaySimulationRunner.instance.reset();
    LaunchDayChaosSuite.instance.reset();
    ProductionRecoveryDrill.instance.reset();
    ReleaseBuildAudit.instance.reset();
    OwnerMatchdayProtocol.instance.reset();
    ChaosInjector.instance.reset();
    ReadBudgetGuard.instance.resetAll();
  });

  test('cold start tiers classify elite and risky', () {
    ColdStartAudit.instance.record('fast', 100);
    ColdStartAudit.instance.record('slow', 5000);
    expect(ColdStartAudit.instance.tierFor('fast'), ColdStartTier.elite);
    expect(ColdStartAudit.instance.tierFor('slow'), ColdStartTier.risky);
    expect(ColdStartAudit.instance.allAcceptable, isFalse);
  });

  test('match day simulation runs all twelve steps', () async {
    final snap = await MatchDaySimulationRunner.instance.runFullMatchDay(
      stepExecutor: (_) async => true,
    );
    expect(snap['allPassed'], isTrue);
    expect((snap['steps'] as List).length, 12);
  });

  test('launch day chaos suite completes scenarios', () async {
    final snap = await LaunchDayChaosSuite.instance.runAll();
    expect(snap['allPassed'], isTrue);
    expect((snap['scenarios'] as List).length, 8);
  });

  test('production recovery drills pass', () async {
    final snap = await ProductionRecoveryDrill.instance.runAll();
    expect(snap['allPassed'], isTrue);
  });

  test('owner protocol records TTMA', () {
    OwnerMatchdayProtocol.instance.beginRehearsal();
    OwnerMatchdayProtocol.instance.recordStep(
      step: OwnerProtocolStep.login,
      durationMs: 120,
    );
    OwnerMatchdayProtocol.instance.recordStep(
      step: OwnerProtocolStep.publishSession,
      durationMs: 340,
    );
    final snap = OwnerMatchdayProtocol.instance.snapshot();
    expect(snap['ttmaMs'], 460);
  });

  test('release build audit runs checks', () {
    ReleaseBuildAudit.instance.run();
    expect(ReleaseBuildAudit.instance.findings, isNotEmpty);
  });

  test('firebase production audit returns verdict', () {
    expect(
      FirebaseProductionAudit.instance.evaluate(),
      isNot(FirebaseAuditVerdict.critical),
    );
  });

  test('soft launch gate passes after rehearsal suites', () async {
    ColdStartAudit.instance.record('app_launch', 400);
    ColdStartAudit.instance.record('crowd_screen_hydration', 300);
    ColdStartAudit.instance.record('hof_first_render', 500);
    ColdStartAudit.instance.record('session_bootstrap', 600);
    ColdStartAudit.instance.record('image_preload_latency', 700);

    await MatchDaySimulationRunner.instance.runFullMatchDay(
      stepExecutor: (_) async => true,
    );
    await LaunchDayChaosSuite.instance.runAll();
    await ProductionRecoveryDrill.instance.runAll();
    await LaunchStabilitySuite.instance.runLogicGates();
    ReleaseBuildAudit.instance.run();

    final gate = SoftLaunchGate.instance.evaluate();
    expect(gate.blockers, isEmpty);
    expect(gate.decision, SoftLaunchDecision.go);
  });
}
