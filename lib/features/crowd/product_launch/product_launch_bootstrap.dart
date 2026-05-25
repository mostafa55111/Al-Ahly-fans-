import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_authority_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/experimental_feature_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_stability_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/operational_complexity_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/owner_security_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/runtime_owner_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/real_validation/real_validation_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/product_rehearsal_bootstrap.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_readiness_bootstrap.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_bootstrap.dart';

/// تهيئة انضباط الإطلاق — Phase F.
class ProductLaunchBootstrap {
  ProductLaunchBootstrap._();

  static Future<void> initialize() async {
    await ProductionFeatureFreeze.instance.bootstrap();
    ReleaseModeGuard.verify();
    RuntimeOwnerGuard.instance.seedFromLaunchMatrix();

    ExperimentalFeatureGuard.assertNotLoadedInRelease(
      ExperimentalFeatureId.legacyEagleVoting,
    );
    ExperimentalFeatureGuard.assertNotLoadedInRelease(
      ExperimentalFeatureId.productionOpsSandbox,
    );

    if (getIt.isRegistered<OwnerAuthorityService>()) {
      OwnerSecurityAudit.instance.runReleaseChecks(
        owners: getIt<OwnerAuthorityService>(),
      );
    } else {
      OwnerSecurityAudit.instance.runReleaseChecks();
    }

    if (!kReleaseMode && (kDebugMode || kProfileMode)) {
      RealDeviceValidationSuite.instance.bootstrap();
      final matrix =
          RealDeviceValidationSuite.instance.runReferenceDeviceMatrix();
      debugPrint(
        '[ProductLaunch] real_validation matrix '
        'passed=${matrix.values.where((v) => v).length}/${matrix.length}',
      );
    }

    await ReleaseReadinessBootstrap.initialize();
    await SoftLaunchBootstrap.initialize();

    if (kDebugMode) {
      await LaunchStabilitySuite.instance.runLogicGates();
      debugPrint(
        '[ProductLaunch] complexity='
        '${OperationalComplexityReport.instance.classifyActiveServices().name}',
      );
      debugPrint(
        '[ProductLaunch] ready release=${ReleaseModeGuard.isStrictRelease} '
        'stability=${LaunchStabilitySuite.instance.allPassed}',
      );
      unawaited(ProductRehearsalBootstrap.runDressRehearsalChecks());
    }
  }
}
