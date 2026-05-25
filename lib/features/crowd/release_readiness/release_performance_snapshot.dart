/// أهداف أداء الإطلاق.
abstract final class ReleasePerformanceTargets {
  static const int firstFrameMs = 1800;
  static const int interactionLatencyMs = 120;
}

class PerformanceMetricRecord {
  const PerformanceMetricRecord({
    required this.name,
    required this.durationMs,
    required this.withinTarget,
  });

  final String name;
  final int durationMs;
  final bool withinTarget;
}

/// لقطة أداء — تُسجَّل يدوياً أو من أدوات التحقق.
class ReleasePerformanceSnapshot {
  ReleasePerformanceSnapshot();

  final Map<String, int> _durations = {};

  void record(String name, int durationMs) {
    _durations[name] = durationMs;
  }

  List<PerformanceMetricRecord> build() {
    return _durations.entries.map((e) {
      final target = _targetFor(e.key);
      return PerformanceMetricRecord(
        name: e.key,
        durationMs: e.value,
        withinTarget: target == null || e.value <= target,
      );
    }).toList();
  }

  bool get allWithinTargets => build().every((m) => m.withinTarget);

  int? _targetFor(String name) => switch (name) {
        'first_frame' => ReleasePerformanceTargets.firstFrameMs,
        'vote_tap' => ReleasePerformanceTargets.interactionLatencyMs,
        'tab_switch' => ReleasePerformanceTargets.interactionLatencyMs,
        'preview_render' => ReleasePerformanceTargets.interactionLatencyMs,
        _ => null,
      };
}
