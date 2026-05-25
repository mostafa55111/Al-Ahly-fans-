import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/stream_lifecycle_audit.dart';

/// تدقيق ذاكرة/دورة حياة — debug/profile فقط.
class RuntimeMemoryAudit {
  RuntimeMemoryAudit._();

  static final RuntimeMemoryAudit instance = RuntimeMemoryAudit._();

  final List<String> _orphanWarnings = [];

  void recordOrphanWarning(String source, String detail) {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) return;
    final line = '$source: $detail';
    _orphanWarnings.add(line);
    if (_orphanWarnings.length > 32) _orphanWarnings.removeAt(0);
    debugPrint('[RuntimeMemoryAudit] $line');
  }

  Map<String, dynamic> snapshot() {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) {
      return const {'enabled': false};
    }
    return {
      'enabled': true,
      'streamAudit': StreamLifecycleAudit.instance.snapshot(),
      'pendingVoteIntents':
          FailureSurvivalRuntimeReport.instance.pendingQueueDepth,
      'orphanWarnings': List<String>.from(_orphanWarnings),
    };
  }

  @visibleForTesting
  void reset() => _orphanWarnings.clear();
}
