import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';

/// سجل تشغيل المالك — debug/profile فقط.
abstract final class MatchdayReliabilityAudit {
  static void log(String event, {Map<String, Object?>? data}) {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) return;
    if (!kDebugMode) return;
    final extra = data == null || data.isEmpty
        ? ''
        : ' ${data.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    debugPrint('[MatchdayReliability] $event$extra');
  }
}
