import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_execution_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/crowd_authority_config_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_recovery/dead_session_recovery_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_authority_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/product_launch_bootstrap.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/cold_start_audit.dart';

/// تهيئة سلطة الإنتاج + المالك + استرداد الطابور.
class CrowdProductionBootstrap {
  CrowdProductionBootstrap._();

  static Future<void> initialize() async {
    if (!getIt.isRegistered<CrowdAuthorityConfigService>()) return;
    final bootstrapSw = Stopwatch()..start();
    try {
      await getIt<CrowdAuthorityConfigService>().bootstrap();
      if (getIt.isRegistered<AuthorityOrchestrator>()) {
        getIt<AuthorityOrchestrator>().setMode(
          getIt<CrowdAuthorityConfigService>().resolveExecutionMode(),
        );
      }
      if (getIt.isRegistered<OwnerAuthorityService>()) {
        await getIt<OwnerAuthorityService>().bootstrap();
      }
      if (getIt.isRegistered<DeadSessionRecoveryService>()) {
        await getIt<DeadSessionRecoveryService>().replayQueuedTasks();
      }
      await ProductLaunchBootstrap.initialize();
      ColdStartAudit.instance.record(
        'session_bootstrap',
        bootstrapSw.elapsedMilliseconds,
      );
      debugPrint(
        '[CrowdProduction] ready — authority='
        '${getIt<CrowdAuthorityConfigService>().mode.wireName}, '
        'owner=${getIt<OwnerAuthorityService>().isCurrentUserOwner()}',
      );
    } catch (e, st) {
      debugPrint('[CrowdProduction] bootstrap failed: $e\n$st');
    }
  }

  static String leaseOwnerId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return 'client:$uid';
    return 'client:anonymous';
  }
}
