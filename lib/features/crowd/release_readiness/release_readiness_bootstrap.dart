import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_observability_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_readiness_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_runtime_audit.dart';

/// تهيئة انضباط الإطلاق — Phase Launch 1.
class ReleaseReadinessBootstrap {
  ReleaseReadinessBootstrap._();

  static Future<void> initialize() async {
    if (ReleaseReadinessSurfaceGate.visible) {
      final audit = ReleaseRuntimeAudit().run();
      debugPrint(
        '[ReleaseReadiness] runtime_audit passed=${audit.passed} '
        'findings=${audit.findings.length}',
      );
      final obs = ReleaseObservabilityReport().capture();
      if (obs != null) {
        ReleaseObservabilityReport().logSnapshot(obs);
      }
    }
  }
}
