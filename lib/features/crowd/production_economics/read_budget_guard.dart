import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/device_pressure_classifier.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/production_cost_surface_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/read_pressure/visibility_subscription_guard.dart';

/// سطح ميزانية القراءة.
enum ReadBudgetSurface {
  crowdFan,
  hallOfFame,
  cmsAdmin,
  reconnectHydration,
  finalizeAggregation,
}

/// يمنع عواصف القراءة — degrade بدون crash.
class ReadBudgetGuard {
  ReadBudgetGuard._();

  static final ReadBudgetGuard instance = ReadBudgetGuard._();

  static const int crowdMaxConcurrentReads = 6;
  static const int hallOfFameMaxReadsPerOpen = 10;
  static const int cmsMaxReadsPerTab = 24;
  static const int reconnectMaxReadsPerWave = 4;

  final Map<ReadBudgetSurface, int> _windowCounts = {};
  int _crowdConcurrent = 0;
  int _budgetExceeded = 0;

  int get budgetExceededCount => _budgetExceeded;

  bool tryAcquire(ReadBudgetSurface surface, {int reads = 1}) {
    if (!canAcquire(surface, reads: reads)) {
      _budgetExceeded++;
      return false;
    }
    _windowCounts[surface] = (_windowCounts[surface] ?? 0) + reads;
    if (surface == ReadBudgetSurface.crowdFan) {
      _crowdConcurrent += reads;
    }
    FirebaseCostGuard.instance.recordRead(count: reads);
    _mapToCostPath(surface, reads);
    return true;
  }

  void release(ReadBudgetSurface surface, {int reads = 1}) {
    _windowCounts[surface] =
        ((_windowCounts[surface] ?? 0) - reads).clamp(0, 9999);
    if (surface == ReadBudgetSurface.crowdFan) {
      _crowdConcurrent = (_crowdConcurrent - reads).clamp(0, 99);
    }
  }

  bool canAcquire(ReadBudgetSurface surface, {int reads = 1}) {
    if (FirebaseCostGuard.instance.level == CostPressureLevel.critical) {
      return surface == ReadBudgetSurface.crowdFan && reads <= 2;
    }
    final tier = DevicePressureClassifier.instance.currentTier;
    if (tier == DevicePressureTier.lowEnd &&
        surface != ReadBudgetSurface.crowdFan) {
      return false;
    }

    final used = _windowCounts[surface] ?? 0;
    final limit = switch (surface) {
      ReadBudgetSurface.crowdFan => crowdMaxConcurrentReads,
      ReadBudgetSurface.hallOfFame => hallOfFameMaxReadsPerOpen,
      ReadBudgetSurface.cmsAdmin => cmsMaxReadsPerTab,
      ReadBudgetSurface.reconnectHydration => reconnectMaxReadsPerWave,
      ReadBudgetSurface.finalizeAggregation => 8,
    };

    if (surface == ReadBudgetSurface.crowdFan) {
      if (_crowdConcurrent + reads > limit) return false;
      if (!VisibilitySubscriptionGuard.instance.stadiumTabVisible &&
          reads > 2) {
        return false;
      }
    } else if (used + reads > limit) {
      return false;
    }
    return true;
  }

  void resetSurface(ReadBudgetSurface surface) {
    if (surface == ReadBudgetSurface.crowdFan) {
      _crowdConcurrent = 0;
    }
    _windowCounts.remove(surface);
  }

  @visibleForTesting
  void resetAll() {
    _windowCounts.clear();
    _crowdConcurrent = 0;
    _budgetExceeded = 0;
  }

  void _mapToCostPath(ReadBudgetSurface surface, int reads) {
    final path = switch (surface) {
      ReadBudgetSurface.crowdFan => CostSurfacePath.matchSessionStream,
      ReadBudgetSurface.hallOfFame => CostSurfacePath.hallOfFameFeatured,
      ReadBudgetSurface.cmsAdmin => CostSurfacePath.cmsBundleWatch,
      ReadBudgetSurface.reconnectHydration => CostSurfacePath.reconnectHydration,
      ReadBudgetSurface.finalizeAggregation => CostSurfacePath.shardAggregation,
    };
    ProductionCostSurfaceReport.instance.recordRead(path, count: reads);
  }
}
