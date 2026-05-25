import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';

/// ملف تكلفة إعادة الاتصال — phased restore economics.
class ReconnectCostProfile {
  ReconnectCostProfile._();

  static final ReconnectCostProfile instance = ReconnectCostProfile._();

  int resumeBursts = 0;
  int lightWaves = 0;
  int heavyDeferred = 0;
  int heavyCompleted = 0;
  int collapsedRequests = 0;
  int estimatedReadsSaved = 0;

  void recordResumeBurst() => resumeBursts++;
  void recordLightWave({int reads = 2}) {
    lightWaves++;
    _trackReads(reads);
  }

  void recordHeavyDeferred({int readsSaved = 1}) {
    heavyDeferred++;
    estimatedReadsSaved += readsSaved;
  }

  void recordHeavyCompleted({int reads = 1}) {
    heavyCompleted++;
    _trackReads(reads);
  }

  void recordCollapsed() => collapsedRequests++;

  void _trackReads(int reads) {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) return;
  }

  Map<String, dynamic> snapshot() {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) {
      return const {'enabled': false};
    }
    return {
      'enabled': true,
      'resumeBursts': resumeBursts,
      'lightWaves': lightWaves,
      'heavyDeferred': heavyDeferred,
      'heavyCompleted': heavyCompleted,
      'collapsedRequests': collapsedRequests,
      'estimatedReadsSaved': estimatedReadsSaved,
    };
  }

  @visibleForTesting
  void reset() {
    resumeBursts = 0;
    lightWaves = 0;
    heavyDeferred = 0;
    heavyCompleted = 0;
    collapsedRequests = 0;
    estimatedReadsSaved = 0;
  }
}
