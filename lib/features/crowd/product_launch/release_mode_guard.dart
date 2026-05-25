import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/verification_sandbox_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/experimental_feature_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/production_feature_freeze.dart';

/// تحقق وضع الإصدار — release بدون debug surfaces.
class ReleaseModeGuard {
  ReleaseModeGuard._();

  static bool get isStrictRelease => kReleaseMode && !kDebugMode;

  static bool get allowDebugOps =>
      !isStrictRelease && ProductionSurfaceGate.allowOpsDashboard;

  static bool get sandboxDisabled =>
      isStrictRelease || !VerificationSandboxGuard.isVerificationAllowed;

  static bool get experimentalDisabled =>
      isStrictRelease ||
      ProductionFeatureFreeze.instance.disableExperimental;

  static bool get productionOpsProtected => isStrictRelease || kDebugMode;

  static void verify() {
    if (!isStrictRelease) return;
    assert(
      !ProductionSurfaceGate.allowOpsDashboard,
      'ops dashboard must be hidden in release',
    );
    assert(
      !ExperimentalFeatureGuard.allowLoad(
        ExperimentalFeatureId.productionOpsSandbox,
      ),
      'sandbox must be disabled in release',
    );
  }

  static void assertNoTestSession(String sessionId) {
    if (!isStrictRelease) return;
    if (VerificationSandboxGuard.isSandboxSessionId(sessionId)) {
      throw StateError('test_session_blocked_in_release:$sessionId');
    }
  }

  static Map<String, bool> snapshot() => {
        'strictRelease': isStrictRelease,
        'allowDebugOps': allowDebugOps,
        'sandboxDisabled': sandboxDisabled,
        'experimentalDisabled': experimentalDisabled,
      };
}
