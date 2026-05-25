import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';

/// أدوات الإطلاق الناعم — مالك / debug / profile فقط.
abstract final class SoftLaunchSurfaceGate {
  static bool get visible =>
      !ReleaseModeGuard.isStrictRelease &&
      ProductionSurfaceGate.allowRuntimeDiagnostics;

  static bool get ownerOpsVisible => visible && (kDebugMode || kProfileMode);
}
