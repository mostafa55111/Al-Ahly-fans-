import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/rehearsal_surface_gate.dart';

enum ColdStartTier {
  elite,
  good,
  risky,
}

class ColdStartMetric {
  const ColdStartMetric({
    required this.name,
    required this.durationMs,
    required this.tier,
  });

  final String name;
  final int durationMs;
  final ColdStartTier tier;
}

/// قياس أوقات البداية — يُسجَّل من bootstrap hooks.
class ColdStartAudit {
  ColdStartAudit._();

  static final ColdStartAudit instance = ColdStartAudit._();

  final Map<String, int> _samplesMs = {};

  void record(String name, int durationMs) {
    if (!RehearsalSurfaceGate.allowDressRehearsal) return;
    _samplesMs[name] = durationMs;
  }

  void recordStopwatch(String name, Stopwatch sw) =>
      record(name, sw.elapsedMilliseconds);

  ColdStartTier tierFor(String name, {int eliteMs = 800, int goodMs = 2000}) {
    final ms = _samplesMs[name] ?? 99999;
    if (ms <= eliteMs) return ColdStartTier.elite;
    if (ms <= goodMs) return ColdStartTier.good;
    return ColdStartTier.risky;
  }

  List<ColdStartMetric> metrics() {
    return _samplesMs.entries
        .map(
          (e) => ColdStartMetric(
            name: e.key,
            durationMs: e.value,
            tier: tierFor(e.key),
          ),
        )
        .toList();
  }

  bool get allAcceptable =>
      metrics().every((m) => m.tier != ColdStartTier.risky);

  Map<String, dynamic> snapshot() {
    if (!RehearsalSurfaceGate.allowDressRehearsal) {
      return const {'enabled': false};
    }
    return {
      'enabled': true,
      'allAcceptable': allAcceptable,
      'metrics': metrics()
          .map(
            (m) => {
              'name': m.name,
              'durationMs': m.durationMs,
              'tier': m.tier.name,
            },
          )
          .toList(),
    };
  }

  @visibleForTesting
  void reset() => _samplesMs.clear();
}
