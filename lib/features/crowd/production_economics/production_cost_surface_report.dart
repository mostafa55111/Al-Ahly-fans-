import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';

/// تصنيف تكلفة مسار runtime.
enum CostSurfaceTier {
  low,
  medium,
  high,
}

/// مسارات قابلة للقياس — debug/profile فقط.
enum CostSurfacePath {
  matchSessionStream,
  matchPlayersStream,
  matchMyVoteStream,
  reconnectHydration,
  hallOfFameFeatured,
  hallOfFameTimeline,
  hallOfFameRollups,
  cmsBundleWatch,
  voteWrite,
  shardAggregation,
  imagePreload,
  imagePromotion,
  monthlyAggregation,
  seasonAggregation,
}

class ProductionCostSurfaceReport {
  ProductionCostSurfaceReport._();

  static final ProductionCostSurfaceReport instance =
      ProductionCostSurfaceReport._();

  final Map<CostSurfacePath, int> _reads = {};
  final Map<CostSurfacePath, int> _writes = {};
  final Map<String, int> _bandwidthKb = {};

  void recordRead(CostSurfacePath path, {int count = 1}) {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) return;
    _reads[path] = (_reads[path] ?? 0) + count;
  }

  void recordWrite(CostSurfacePath path, {int count = 1}) {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) return;
    _writes[path] = (_writes[path] ?? 0) + count;
  }

  void recordBandwidth(String feature, {int kilobytes = 1}) {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) return;
    _bandwidthKb[feature] = (_bandwidthKb[feature] ?? 0) + kilobytes;
  }

  CostSurfaceTier tierFor(CostSurfacePath path) {
    final reads = _reads[path] ?? 0;
    return switch (path) {
      CostSurfacePath.matchPlayersStream ||
      CostSurfacePath.hallOfFameTimeline ||
      CostSurfacePath.cmsBundleWatch ||
      CostSurfacePath.shardAggregation =>
        reads > 40 ? CostSurfaceTier.high : reads > 15 ? CostSurfaceTier.medium : CostSurfaceTier.low,
      CostSurfacePath.reconnectHydration ||
      CostSurfacePath.imagePreload ||
      CostSurfacePath.imagePromotion =>
        reads > 25 ? CostSurfaceTier.high : reads > 8 ? CostSurfaceTier.medium : CostSurfaceTier.low,
      _ => reads > 60 ? CostSurfaceTier.high : reads > 20 ? CostSurfaceTier.medium : CostSurfaceTier.low,
    };
  }

  Map<String, dynamic> snapshot() {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) {
      return const {'enabled': false};
    }
    final paths = <String, dynamic>{};
    for (final p in CostSurfacePath.values) {
      paths[p.name] = {
        'reads': _reads[p] ?? 0,
        'writes': _writes[p] ?? 0,
        'tier': tierFor(p).name,
      };
    }
    return {
      'enabled': true,
      'paths': paths,
      'bandwidthKb': Map<String, int>.from(_bandwidthKb),
    };
  }

  @visibleForTesting
  void reset() {
    _reads.clear();
    _writes.clear();
    _bandwidthKb.clear();
  }
}
