import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_animation_budget.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_audio_engine.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_runtime_telemetry_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/overlay_runtime_registry.dart';

/// حراس وقت التشغيل: تخفيض تلقائي للـ FX تحت الضغط — بدون Firebase.
class CrowdRuntimeGuards extends ChangeNotifier {
  CrowdRuntimeGuards({
    CrowdRuntimeTelemetryService? telemetry,
    OverlayRuntimeRegistry? registry,
  })  : _telemetry = telemetry ?? CrowdRuntimeTelemetryService.instance,
        _registry = registry ?? OverlayRuntimeRegistry.instance;

  final CrowdRuntimeTelemetryService _telemetry;
  final OverlayRuntimeRegistry _registry;

  VoidCallback? _telemetryListener;
  VoidCallback? _registryListener;

  CrowdAnimationBudget _guardTier = CrowdAnimationBudget.full;
  int _heavyStreak = 0;
  int _lightStreak = 0;

  CrowdAudioEngine? _audio;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  CrowdAnimationBudget get guardTier => _guardTier;

  /// ضغط شديد: أولوية أعلى لخفض الـ overlays على الكروت الخلفية.
  bool get strongDegrade =>
      _guardTier == CrowdAnimationBudget.minimal || _telemetry.snapshot.currentFps < 32;

  void start({
    required CrowdAudioEngine? audio,
  }) {
    _audio = audio;
    _telemetryListener ??= _onTelemetryTick;
    _registryListener ??= _onTelemetryTick;
    _telemetry.addListener(_telemetryListener!);
    _registry.addListener(_registryListener!);
    _recompute();
  }

  void setLifecycle(AppLifecycleState s) {
    if (_lifecycle == s) return;
    _lifecycle = s;
    _applyAudioStress();
    _recompute();
  }

  @override
  void dispose() {
    if (_telemetryListener != null) {
      _telemetry.removeListener(_telemetryListener!);
      _telemetryListener = null;
    }
    if (_registryListener != null) {
      _registry.removeListener(_registryListener!);
      _registryListener = null;
    }
    _audio?.setRuntimeGuardStress(1.0);
    _audio = null;
    super.dispose();
  }

  void _onTelemetryTick() {
    _recompute();
  }

  void _recompute() {
    final snap = _telemetry.snapshot;
    var heavy = false;

    if (snap.currentFps > 0 && snap.currentFps < 45) {
      heavy = true;
    }
    if (snap.avgFrameTimeMs > 20.0) {
      heavy = true;
    }
    if (snap.droppedFramesWindow > 28) {
      heavy = true;
    }
    if (_registry.isHeavyAnimatedOverBudget) {
      heavy = true;
    }
    if (snap.memoryPressure01 > 0.82) {
      heavy = true;
    }

    if (heavy) {
      _heavyStreak = math.min(200, _heavyStreak + 2);
      _lightStreak = 0;
    } else {
      _lightStreak = math.min(400, _lightStreak + 1);
      _heavyStreak = math.max(0, _heavyStreak - 1);
    }

    CrowdAnimationBudget next = _guardTier;
    if (_heavyStreak >= 8) {
      next = CrowdAnimationBudget.minimal;
    } else if (_heavyStreak >= 4 && _guardTier == CrowdAnimationBudget.full) {
      next = CrowdAnimationBudget.reduced;
    } else if (_lightStreak >= 90 && _guardTier != CrowdAnimationBudget.full) {
      next = _guardTier == CrowdAnimationBudget.minimal
          ? CrowdAnimationBudget.reduced
          : CrowdAnimationBudget.full;
      _heavyStreak = 0;
    }

    if (next != _guardTier) {
      _guardTier = next;
      notifyListeners();
    }

    _applyAudioStress();
  }

  void _applyAudioStress() {
    final audio = _audio;
    if (audio == null) return;
    if (_lifecycle != AppLifecycleState.resumed) {
      audio.setRuntimeGuardStress(0.45);
      return;
    }
    final snap = _telemetry.snapshot;
    var stress = 1.0;
    if (snap.currentFps > 0 && snap.currentFps < 48) {
      stress = math.min(stress, 0.72);
    }
    if (snap.droppedFramesWindow > 18) {
      stress = math.min(stress, 0.62);
    }
    if (_registry.isHeavyAnimatedOverBudget) {
      stress = math.min(stress, 0.68);
    }
    if (snap.memoryPressure01 > 0.75) {
      stress = math.min(stress, 0.58);
    }
    if (_guardTier == CrowdAnimationBudget.minimal) {
      stress = math.min(stress, 0.52);
    } else if (_guardTier == CrowdAnimationBudget.reduced) {
      stress = math.min(stress, 0.78);
    }
    audio.setRuntimeGuardStress(stress);
  }
}
