import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_animation_budget.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_runtime_telemetry_service.dart';

export 'crowd_animation_budget.dart';

/// يستمع لدُفعات [FrameTiming] من [CrowdRuntimeTelemetryService] (callback موحّد).
class CrowdAnimationBudgetController extends ChangeNotifier {
  CrowdAnimationBudget _tier = CrowdAnimationBudget.full;
  int _heavyStreak = 0;
  int _lightStreak = 0;
  VoidCallback? _listener;

  CrowdAnimationBudget get tier => _tier;

  void attach() {
    if (_listener != null) return;
    _listener = _onTelemetryBatch;
    CrowdRuntimeTelemetryService.instance.addTimingBatchListener(_listener!);
  }

  void detach() {
    if (_listener == null) return;
    CrowdRuntimeTelemetryService.instance.removeTimingBatchListener(_listener!);
    _listener = null;
  }

  void _onTelemetryBatch() {
    final batch = CrowdRuntimeTelemetryService.instance.lastTimingsBatch;
    if (batch.isEmpty) return;
    for (final t in batch) {
      final ms = t.buildDuration.inMilliseconds + t.rasterDuration.inMilliseconds;
      if (ms > 19) {
        _heavyStreak++;
        _lightStreak = 0;
      } else {
        _lightStreak++;
        _heavyStreak = math.max(0, _heavyStreak - 1);
      }
    }

    CrowdAnimationBudget next = _tier;
    if (_heavyStreak >= 10) {
      next = CrowdAnimationBudget.minimal;
    } else if (_heavyStreak >= 5 && _tier == CrowdAnimationBudget.full) {
      next = CrowdAnimationBudget.reduced;
    } else if (_lightStreak >= 120 && _tier != CrowdAnimationBudget.full) {
      next = _tier == CrowdAnimationBudget.minimal
          ? CrowdAnimationBudget.reduced
          : CrowdAnimationBudget.full;
      _heavyStreak = 0;
    }

    if (next != _tier) {
      _tier = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    detach();
    super.dispose();
  }
}
