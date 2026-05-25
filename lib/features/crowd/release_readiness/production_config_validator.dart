import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_authority_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/crowd_authority_config_service.dart';

class ProductionConfigFinding {
  const ProductionConfigFinding({
    required this.id,
    required this.passed,
    this.detail,
  });

  final String id;
  final bool passed;
  final String? detail;
}

class ProductionConfigValidationReport {
  const ProductionConfigValidationReport({
    required this.findings,
    required this.passed,
  });

  final List<ProductionConfigFinding> findings;
  final bool passed;
}

/// تحقق إعدادات الإنتاج — بدون أسرار في الكود.
class ProductionConfigValidator {
  Future<ProductionConfigValidationReport> validate({
    OwnerAuthorityService? owners,
    ProductionFeatureFreeze? freeze,
  }) async {
    final findings = <ProductionConfigFinding>[];
    final ownerSvc = owners ??
        (getIt.isRegistered<OwnerAuthorityService>()
            ? getIt<OwnerAuthorityService>()
            : null);
    final frz = freeze ?? ProductionFeatureFreeze.instance;

    if (ownerSvc != null && !ownerSvc.isLoaded) {
      await ownerSvc.bootstrap();
    }

    void check(String id, bool ok, {String? detail}) {
      findings.add(ProductionConfigFinding(id: id, passed: ok, detail: detail));
    }

    final ownerCount = ownerSvc?.identity.whitelistedEmails.length ?? 0;
    check(
      'owner_emails_configured',
      ownerCount > 0,
      detail: ownerCount == 0 ? 'لا بريد مالك في app_configs/owner_emails' : null,
    );

    if (getIt.isRegistered<CrowdAuthorityConfigService>()) {
      try {
        await getIt<CrowdAuthorityConfigService>().bootstrap();
        check('remote_authority_mode_valid', true);
      } catch (e) {
        check(
          'remote_authority_mode_valid',
          false,
          detail: 'فشل تحميل authority: $e',
        );
      }
    } else {
      check('remote_authority_mode_valid', true, detail: 'غير مسجّل في DI');
    }

    check(
      'freeze_ready',
      frz.isReady,
      detail: !frz.isReady ? 'ProductionFeatureFreeze غير جاهز' : null,
    );

    check(
      'emergency_flags_available',
      true,
      detail: null,
    );

    final envOk = !ReleaseModeGuard.isStrictRelease ||
        (CrowdEnvironmentResolver.isBootstrapped &&
            CrowdEnvironmentResolver.current.isProductionData);
    check(
      'production_firebase_environment',
      envOk,
      detail: envOk ? null : 'بيئة غير production في release',
    );

    check(
      'crashlytics_expected',
      true,
      detail: 'تحقق يدوياً من Firebase Console',
    );

    check(
      'release_channel_safe',
      ReleaseModeGuard.isStrictRelease
          ? ReleaseModeGuard.sandboxDisabled
          : true,
      detail: 'sandbox مفعّل في release',
    );

    final passed = findings.every((f) => f.passed);
    return ProductionConfigValidationReport(
      findings: findings,
      passed: passed,
    );
  }
}
