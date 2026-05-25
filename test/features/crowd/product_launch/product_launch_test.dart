import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/experimental_feature_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_contract.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_stability_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/product_surface_registry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/runtime_owner_guard.dart';

void main() {
  setUp(() {
    LaunchContract.resetWarnings();
    RuntimeOwnerGuard.instance.reset();
    RuntimeOwnerGuard.instance.seedFromLaunchMatrix();
    ProductionFeatureFreeze.instance.resetForTests();
    LaunchStabilitySuite.instance.reset();
  });

  test('product surface registry lists launch surfaces only', () {
    expect(
      ProductSurfaceRegistry.isProductionSurface(ProductSurfaceId.crowdScreen),
      isTrue,
    );
    expect(ProductSurfaceRegistry.productionSurfaces.length, 14);
  });

  test('experimental legacy flags stay off in production', () {
    expect(ExperimentalFeatureGuard.isExperimental(
      ExperimentalFeatureId.legacyEagleVoting,
    ), isFalse);
  });

  test('launch contract records unsupported warnings', () {
    LaunchContract.warnUnsupported('vote_edits');
    expect(LaunchContract.snapshot()['warnings'], contains('vote_edits'));
  });

  test('runtime owner guard detects finalize ownership', () {
    expect(
      RuntimeOwnerGuard.instance.claim(
        RuntimeOwnershipDomain.finalize,
        'ProductionFinalizePipeline',
      ),
      isTrue,
    );
    expect(
      RuntimeOwnerGuard.instance.claim(
        RuntimeOwnershipDomain.finalize,
        'WrongService',
      ),
      isFalse,
    );
  });

  test('launch stability logic gates pass', () async {
    final gates = await LaunchStabilitySuite.instance.runLogicGates();
    expect(gates.values.every((v) => v), isTrue);
  });

  test('feature freeze blocks when enabled', () {
    ProductionFeatureFreeze.instance.resetForTests(freeze: true);
    expect(
      ProductionFeatureFreeze.instance.blocksNewCapability('multi_match'),
      isTrue,
    );
  });
}
