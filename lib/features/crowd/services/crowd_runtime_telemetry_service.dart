import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_animation_budget.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/overlay_runtime_registry.dart';

/// لقطة لحظية لمراقبة الأداء — للقراءة فقط من الـ HUD أو الحراس.
@immutable
class CrowdRuntimeTelemetrySnapshot {
  const CrowdRuntimeTelemetrySnapshot({
    required this.currentFps,
    required this.avgFrameTimeMs,
    required this.droppedFramesWindow,
    required this.activeOverlayCount,
    required this.activeAnimatedOverlays,
    required this.visibleCards,
    required this.memoryPressure01,
    required this.animationBudgetLevel,
    required this.activeAudioLoops,
    required this.viewportPlayersCount,
    required this.hintActiveAnimationControllers,
  });

  final double currentFps;
  final double avgFrameTimeMs;
  final int droppedFramesWindow;
  final int activeOverlayCount;
  final int activeAnimatedOverlays;
  final int visibleCards;
  final double memoryPressure01;
  final CrowdAnimationBudget animationBudgetLevel;
  final int activeAudioLoops;
  final int viewportPlayersCount;
  final int hintActiveAnimationControllers;

  static const CrowdRuntimeTelemetrySnapshot zero = CrowdRuntimeTelemetrySnapshot(
    currentFps: 0,
    avgFrameTimeMs: 0,
    droppedFramesWindow: 0,
    activeOverlayCount: 0,
    activeAnimatedOverlays: 0,
    visibleCards: 0,
    memoryPressure01: 0,
    animationBudgetLevel: CrowdAnimationBudget.full,
    activeAudioLoops: 0,
    viewportPlayersCount: 0,
    hintActiveAnimationControllers: 0,
  );
}

/// قياسات وقت التشغيل للملعب — callback واحد [SchedulerBinding.addTimingsCallback].
final class CrowdRuntimeTelemetryService extends ChangeNotifier {
  CrowdRuntimeTelemetryService._();
  static final CrowdRuntimeTelemetryService instance = CrowdRuntimeTelemetryService._();

  int _refCount = 0;
  TimingsCallback? _timingsCallback;
  final List<VoidCallback> _timingBatchListeners = [];

  DateTime? _wallLastBatch;
  final List<double> _recentFrameMs = <double>[];
  static const int _maxRecent = 180;
  int _droppedWindow = 0;
  final List<int> _dropRing = List<int>.filled(120, 0);
  int _dropRingIdx = 0;

  double _fpsEma = 60;
  double _avgFrameMsEma = 16.7;

  int _viewportPlayers = 0;
  int _audioLoops = 0;
  int _hintControllers = 0;
  CrowdAnimationBudget _hudBudget = CrowdAnimationBudget.full;

  CrowdRuntimeTelemetrySnapshot _snapshot = CrowdRuntimeTelemetrySnapshot.zero;

  CrowdRuntimeTelemetrySnapshot get snapshot => _snapshot;

  List<FrameTiming> _lastBatch = const [];

  List<FrameTiming> get lastTimingsBatch => _lastBatch;

  void addTimingBatchListener(VoidCallback listener) {
    _timingBatchListeners.add(listener);
  }

  void removeTimingBatchListener(VoidCallback listener) {
    _timingBatchListeners.remove(listener);
  }

  void setHudAnimationBudget(CrowdAnimationBudget b) {
    if (_hudBudget == b) return;
    _hudBudget = b;
    _rebuildSnapshot();
  }

  void commitSceneMetrics({
    int? viewportPlayers,
    int? activeAudioLoops,
    int? hintActiveAnimationControllers,
  }) {
    var dirty = false;
    if (viewportPlayers != null && viewportPlayers != _viewportPlayers) {
      _viewportPlayers = viewportPlayers;
      dirty = true;
    }
    if (activeAudioLoops != null && activeAudioLoops != _audioLoops) {
      _audioLoops = activeAudioLoops;
      dirty = true;
    }
    if (hintActiveAnimationControllers != null &&
        hintActiveAnimationControllers != _hintControllers) {
      _hintControllers = hintActiveAnimationControllers;
      dirty = true;
    }
    if (dirty) {
      _rebuildSnapshot();
    }
  }

  void _onRegistryChanged() {
    _rebuildSnapshot();
    notifyListeners();
  }

  void acquire() {
    _refCount++;
    if (_refCount == 1) {
      _attachTimings();
      OverlayRuntimeRegistry.instance.addListener(_onRegistryChanged);
    }
  }

  void release() {
    if (_refCount <= 0) return;
    _refCount--;
    if (_refCount == 0) {
      OverlayRuntimeRegistry.instance.removeListener(_onRegistryChanged);
      _detachTimings();
    }
  }

  void _attachTimings() {
    if (_timingsCallback != null) return;
    _timingsCallback = _onTimings;
    SchedulerBinding.instance.addTimingsCallback(_timingsCallback!);
  }

  void _detachTimings() {
    if (_timingsCallback == null) return;
    SchedulerBinding.instance.removeTimingsCallback(_timingsCallback!);
    _timingsCallback = null;
  }

  void _onTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) return;
    _lastBatch = timings;
    final now = DateTime.now();
    final wallDt = _wallLastBatch == null ? 0.001 : now.difference(_wallLastBatch!).inMicroseconds / 1e6;
    _wallLastBatch = now;

    var batchMs = 0.0;
    var dropped = 0;
    for (final t in timings) {
      final ms = (t.buildDuration + t.rasterDuration).inMicroseconds / 1000.0;
      batchMs += ms;
      _recentFrameMs.add(ms);
      while (_recentFrameMs.length > _maxRecent) {
        _recentFrameMs.removeAt(0);
      }
      if (ms > 22.0) {
        dropped++;
      }
    }
    _dropRing[_dropRingIdx % _dropRing.length] = dropped;
    _dropRingIdx++;
    _droppedWindow = _dropRing.fold<int>(0, (a, b) => a + b);

    final instFps = wallDt > 1e-6 ? timings.length / wallDt : _fpsEma;
    _fpsEma = 0.88 * _fpsEma + 0.12 * instFps.clamp(0.0, 240.0);

    final avgBatch = batchMs / timings.length;
    _avgFrameMsEma = 0.85 * _avgFrameMsEma + 0.15 * avgBatch;

    for (final l in _timingBatchListeners) {
      l();
    }

    _rebuildSnapshot();
    notifyListeners();
  }

  double _memoryPressure() {
    try {
      final ic = PaintingBinding.instance.imageCache;
      final maxB = ic.maximumSizeBytes;
      if (maxB <= 0) return 0;
      final ratio = ic.currentSizeBytes / maxB;
      return ratio.clamp(0.0, 1.0);
    } catch (_) {
      return 0;
    }
  }

  void _rebuildSnapshot() {
    final reg = OverlayRuntimeRegistry.instance;
    _snapshot = CrowdRuntimeTelemetrySnapshot(
      currentFps: _fpsEma,
      avgFrameTimeMs: _avgFrameMsEma,
      droppedFramesWindow: _droppedWindow,
      activeOverlayCount: reg.activeCount,
      activeAnimatedOverlays: reg.heavyAnimatedTotalCount,
      visibleCards: reg.visibleCount,
      memoryPressure01: _memoryPressure(),
      animationBudgetLevel: _hudBudget,
      activeAudioLoops: _audioLoops,
      viewportPlayersCount: _viewportPlayers,
      hintActiveAnimationControllers: _hintControllers,
    );
  }
}
