import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/crowd_production_bootstrap.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/config/crowd_deployment_config_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident_store.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/observability/crashlytics_bootstrap.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident_logger.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/rollback/safe_rollback_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/cold_start_audit.dart';

/// تهيئة مرحلة الإطلاق: بيئة، قناة، حوادث، Crashlytics، rollback.
class CrowdDeploymentBootstrap {
  CrowdDeploymentBootstrap._();

  static final Stopwatch _appLaunchStopwatch = Stopwatch()..start();

  static Future<void> initialize() async {
    try {
      if (!CrowdEnvironmentResolver.isBootstrapped) {
        await CrowdEnvironmentResolver.bootstrap();
      }

      if (getIt.isRegistered<CrowdDeploymentConfigService>()) {
        await getIt<CrowdDeploymentConfigService>().bootstrap();
        if (kReleaseMode) {
          getIt<CrowdDeploymentConfigService>().validateProductionSanity();
        }
      }

      await ReleaseChannelResolver.bootstrap();

      if (getIt.isRegistered<OwnerSessionGuard>()) {
        await getIt<OwnerSessionGuard>().start();
      }

      if (getIt.isRegistered<ProductionIncidentStore>()) {
        await getIt<ProductionIncidentStore>().load();
      }

      if (getIt.isRegistered<ProductionIncidentLogger>()) {
        await CrashlyticsBootstrap.initialize(
          incidentLogger: getIt<ProductionIncidentLogger>(),
        );
      } else {
        await CrashlyticsBootstrap.initialize();
      }

      if (getIt.isRegistered<SafeRollbackCoordinator>()) {
        await getIt<SafeRollbackCoordinator>().bootstrap();
      }

      await CrowdProductionBootstrap.initialize();

      ColdStartAudit.instance.record(
        'app_launch',
        _appLaunchStopwatch.elapsedMilliseconds,
      );

      debugPrint(
        '[CrowdDeployment] ready env='
        '${CrowdEnvironmentResolver.current.environment.name} '
        'channel=${ReleaseChannelResolver.current.wireName}',
      );
    } catch (e, st) {
      debugPrint('[CrowdDeployment] bootstrap failed: $e\n$st');
    }
  }
}
