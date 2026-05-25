import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/verification_sandbox_guard.dart';

/// عزل أسطح التشغيل/التحقق عن runtime الإنتاج.
class ProductionSurfaceGate {
  ProductionSurfaceGate._();

  /// لوحة ops + محاكاة — debug + قناة داخلية فقط.
  static bool get allowOpsDashboard =>
      kDebugMode && VerificationSandboxGuard.isVerificationAllowed;

  /// تقارير runtime (topology / memory / policy) — debug أو profile.
  static bool get allowRuntimeDiagnostics => kDebugMode || kProfileMode;

  static void assertSandboxOnly(String sessionId) {
    VerificationSandboxGuard.assertSandboxSession(sessionId);
  }
}
