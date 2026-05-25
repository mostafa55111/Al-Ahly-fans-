import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/production_cost_surface_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/read_budget_guard.dart';

/// يحدّ تكلفة تجميع الإغلاق — timeout + منع إعادة حساب شهرية مكررة.
class AggregationCostGuard {
  AggregationCostGuard._();

  static final AggregationCostGuard instance = AggregationCostGuard._();

  static const Duration aggregationTimeout = Duration(seconds: 45);
  static const int maxFinalizeAggregationAttempts = 3;

  final Set<String> _monthlyComputed = {};
  final Set<String> _seasonComputed = {};
  final Map<String, int> _attempts = {};

  bool tryBeginFinalizeAggregation(String matchId) {
    final n = (_attempts[matchId] ?? 0) + 1;
    if (n > maxFinalizeAggregationAttempts) return false;
    _attempts[matchId] = n;
    return ReadBudgetGuard.instance.tryAcquire(
      ReadBudgetSurface.finalizeAggregation,
      reads: 2,
    );
  }

  void endFinalizeAggregation(String matchId) {
    ReadBudgetGuard.instance.release(
      ReadBudgetSurface.finalizeAggregation,
      reads: 2,
    );
  }

  bool shouldSkipMonthlyRecompute({
    required String clubTag,
    required String monthKey,
  }) {
    final key = '$clubTag:$monthKey';
    if (_monthlyComputed.contains(key)) return true;
    _monthlyComputed.add(key);
    return false;
  }

  bool shouldSkipSeasonRecompute({
    required String clubTag,
    required String seasonKey,
  }) {
    final key = '$clubTag:$seasonKey';
    if (_seasonComputed.contains(key)) return true;
    _seasonComputed.add(key);
    return false;
  }

  Future<T> runBounded<T>({
    required String matchId,
    required Future<T> Function() work,
  }) async {
    if (!tryBeginFinalizeAggregation(matchId)) {
      throw TimeoutException('aggregation_budget_exceeded');
    }
    try {
      ProductionCostSurfaceReport.instance.recordRead(
        CostSurfacePath.shardAggregation,
        count: 1,
      );
      return await work().timeout(aggregationTimeout);
    } finally {
      endFinalizeAggregation(matchId);
    }
  }

  @visibleForTesting
  void reset() {
    _monthlyComputed.clear();
    _seasonComputed.clear();
    _attempts.clear();
  }
}
