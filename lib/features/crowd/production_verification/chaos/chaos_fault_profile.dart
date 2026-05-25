import 'package:flutter/foundation.dart';

enum ChaosFaultKind {
  rtdbLatency,
  disconnect,
  reconnectFlood,
  duplicateFinalize,
  cloudFunctionTimeout,
  staleLease,
  shardWriteFailure,
  partialAggregation,
}

class ChaosFaultProfile {
  const ChaosFaultProfile({
    required this.kind,
    this.probability = 0.1,
    this.extraLatencyMs = 0,
    this.enabled = true,
  });

  final ChaosFaultKind kind;
  final double probability;
  final int extraLatencyMs;
  final bool enabled;
}

/// حقن أعطال — debug فقط، مستحيل في release.
class ChaosMode {
  ChaosMode._();

  static bool get enabled => kDebugMode && _active;
  static bool _active = false;
  static final List<ChaosFaultProfile> _profiles = [];

  static void activate(List<ChaosFaultProfile> profiles) {
    if (!kDebugMode) return;
    _active = true;
    _profiles
      ..clear()
      ..addAll(profiles);
  }

  static void deactivate() {
    _active = false;
    _profiles.clear();
  }

  static bool shouldInject(ChaosFaultKind kind) {
    if (!enabled) return false;
    for (final p in _profiles) {
      if (p.enabled && p.kind == kind && _roll(p.probability)) return true;
    }
    return false;
  }

  static int latencyMs(ChaosFaultKind kind) {
    if (!enabled) return 0;
    for (final p in _profiles) {
      if (p.enabled && p.kind == kind) return p.extraLatencyMs;
    }
    return 0;
  }

  static bool _roll(double p) {
    if (p <= 0) return false;
    return DateTime.now().microsecond % 1000 < (p * 1000);
  }
}
