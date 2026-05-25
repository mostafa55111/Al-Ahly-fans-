import 'dart:convert';

import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/device_pressure_classifier.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/production_cost_surface_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/read_budget_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/read_pressure/visibility_subscription_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سياسة اقتصاد قاعة الشرف — featured أولاً، timeline مؤجل، cache لزج.
class HallOfFameBudgetPolicy {
  HallOfFameBudgetPolicy(this._prefs);

  static const _cacheKeyPrefix = 'hof_snapshot_v1_';
  static const _cacheTtlMs = 1000 * 60 * 30;

  final SharedPreferences _prefs;
  final Set<String> _hydrationInFlight = {};

  bool shouldOpenFeaturedOnly() => true;

  bool shouldHydrateFullTimeline({
    required String clubTag,
    required bool tabVisible,
  }) {
    if (!tabVisible) return false;
    if (FirebaseCostGuard.instance.shouldReduceHofPreload) return false;
    if (DevicePressureClassifier.instance.lightweightHydration) return false;
    if (!ReadBudgetGuard.instance.canAcquire(
      ReadBudgetSurface.hallOfFame,
      reads: 4,
    )) {
      return false;
    }
    final key = '$clubTag:timeline';
    if (_hydrationInFlight.contains(key)) return false;
    return true;
  }

  bool beginTimelineHydration(String clubTag) {
    final key = '$clubTag:timeline';
    if (_hydrationInFlight.contains(key)) return false;
    _hydrationInFlight.add(key);
    return ReadBudgetGuard.instance.tryAcquire(
      ReadBudgetSurface.hallOfFame,
      reads: 4,
    );
  }

  void endTimelineHydration(String clubTag) {
    _hydrationInFlight.remove('$clubTag:timeline');
  }

  String? readCachedSnapshot(String clubTag) {
    final raw = _prefs.getString('$_cacheKeyPrefix$clubTag');
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final at = (map['atMs'] as num?)?.toInt() ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - at > _cacheTtlMs) {
        return null;
      }
      return map['payload']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeCachedSnapshot({
    required String clubTag,
    required String payloadJson,
  }) async {
    await _prefs.setString(
      '$_cacheKeyPrefix$clubTag',
      jsonEncode({
        'atMs': DateTime.now().millisecondsSinceEpoch,
        'payload': payloadJson,
      }),
    );
    ProductionCostSurfaceReport.instance.recordRead(
      CostSurfacePath.hallOfFameTimeline,
      count: 0,
    );
  }

  bool hallTabVisible() =>
      !VisibilitySubscriptionGuard.instance.stadiumTabVisible;
}
