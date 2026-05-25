import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';

/// من يُسمح له برؤية أدوات الجاهزية للإطلاق.
abstract final class ReleaseReadinessSurfaceGate {
  static bool get visible =>
      !ReleaseModeGuard.isStrictRelease &&
      ProductionSurfaceGate.allowRuntimeDiagnostics;

  static bool get ownerToolsInShell => visible && (kDebugMode || kProfileMode);
}
