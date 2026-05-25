import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/release_build_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';

class ReleaseRuntimeFinding {
  const ReleaseRuntimeFinding({
    required this.id,
    required this.passed,
    this.detail,
  });

  final String id;
  final bool passed;
  final String? detail;
}

/// تقرير تدقيق runtime للإصدار.
class ReleaseRuntimeAuditReport {
  const ReleaseRuntimeAuditReport({
    required this.findings,
    required this.passed,
  });

  final List<ReleaseRuntimeFinding> findings;
  final bool passed;
}

/// تدقيق أسطح الإصدار — لا تسريب debug في release.
class ReleaseRuntimeAudit {
  ReleaseRuntimeAudit();

  ReleaseRuntimeAuditReport run() {
    final findings = <ReleaseRuntimeFinding>[];

    void check(String id, bool Function() fn, {String? failDetail}) {
      final ok = fn();
      findings.add(
        ReleaseRuntimeFinding(
          id: id,
          passed: ok,
          detail: ok ? null : failDetail,
        ),
      );
    }

    if (ReleaseModeGuard.isStrictRelease) {
      ReleaseBuildAudit.instance.run();
      for (final f in ReleaseBuildAudit.instance.findings) {
        findings.add(
          ReleaseRuntimeFinding(
            id: f.check,
            passed: f.passed,
            detail: f.detail,
          ),
        );
      }
    }

    check(
      'no_ops_dashboard_in_release',
      () => !ReleaseModeGuard.isStrictRelease ||
          !ProductionSurfaceGate.allowOpsDashboard,
      failDetail: 'ops dashboard visible in release',
    );

    check(
      'no_runtime_diagnostics_in_release',
      () => !ReleaseModeGuard.isStrictRelease ||
          !ProductionSurfaceGate.allowRuntimeDiagnostics,
      failDetail: 'runtime diagnostics in release',
    );

    check(
      'no_staging_banner_in_production',
      () {
        if (!ReleaseModeGuard.isStrictRelease) return true;
        if (!CrowdEnvironmentResolver.isBootstrapped) return true;
        return CrowdEnvironmentResolver.current.isProductionData;
      },
      failDetail: 'non-production environment in release build',
    );

    check(
      'strict_release_flag',
      () => !kReleaseMode || ReleaseModeGuard.isStrictRelease == !kDebugMode,
      failDetail: 'release mode mismatch',
    );

    check(
      'no_unsafe_owner_bypass',
      () => !ReleaseModeGuard.isStrictRelease ||
          ReleaseModeGuard.experimentalDisabled,
      failDetail: 'experimental owner bypass possible',
    );

    final passed = findings.every((f) => f.passed);
    return ReleaseRuntimeAuditReport(findings: findings, passed: passed);
  }
}
