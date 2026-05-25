import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/verification_sandbox_guard.dart';

/// بروفة الإنتاج — debug/staging فقط، لا release.
class RehearsalSurfaceGate {
  RehearsalSurfaceGate._();

  static bool get allowDressRehearsal =>
      ProductionSurfaceGate.allowRuntimeDiagnostics &&
      VerificationSandboxGuard.isVerificationAllowed;

  static void assertRehearsalAllowed() {
    if (!allowDressRehearsal) {
      throw StateError('dress_rehearsal_disabled_in_release');
    }
  }
}
