import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';

/// محرك صوت الملعب: Ambient + Cheer + Leader + كتم + دورة حياة التطبيق + تدرج شدة.
class CrowdAudioEngine {
  CrowdAudioEngine({CrowdAppIdentity? identity})
      : _identity = identity ?? CrowdAppIdentity.current;

  final CrowdAppIdentity _identity;
  final AudioPlayer _oneShot = AudioPlayer();
  AudioPlayer? _ambience;
  bool _muted = false;
  double _intensity = 0.35;
  AppLifecycleState? _lifecycle;
  double _runtimeGuardStress = 1.0;
  DateTime? _lastCheerAt;
  double _emotionDrive = 0.35;

  bool get muted => _muted;

  /// حلقات صوتية نشطة تقريبية (خلفية فقط) — للتليمتري.
  int get activeAudioLoops {
    if (_muted) return 0;
    if (_lifecycle == AppLifecycleState.paused ||
        _lifecycle == AppLifecycleState.detached ||
        _lifecycle == AppLifecycleState.hidden) {
      return 0;
    }
    try {
      if (_ambience != null) return 1;
    } catch (_) {}
    return 0;
  }

  set muted(bool v) {
    _muted = v;
    if (v) {
      try {
        _ambience?.setVolume(0);
      } catch (_) {}
      _ambience?.pause();
    } else {
      unawaited(_startOrResumeAmbience());
    }
  }

  void setIntensity(double v) {
    _intensity = v.clamp(0.0, 1.0);
    _applyAmbienceTargetVolume();
  }

  /// مضاعف 0..1 من طبقة الحماية وقت التشغيل (FPS / overlays / الخلفية).
  void setRuntimeGuardStress(double v) {
    final n = v.clamp(0.2, 1.0);
    if ((n - _runtimeGuardStress).abs() < 0.02) return;
    _runtimeGuardStress = n;
    _applyAmbienceTargetVolume();
  }

  /// طبقة شعورية 0..1 — تُمزج مع الصوت المحيطي دون تعارض مع [setRuntimeGuardStress].
  void setEmotionalDrive(double v) {
    final n = v.clamp(0.0, 1.0);
    if ((n - _emotionDrive).abs() < 0.04) return;
    _emotionDrive = n;
    _applyAmbienceTargetVolume();
  }

  void handleAppLifecycle(AppLifecycleState state) {
    _lifecycle = state;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_muted) {
          unawaited(_startOrResumeAmbience());
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        try {
          _ambience?.pause();
        } catch (_) {}
        break;
    }
  }

  double _ambienceBaseVolume() {
    final pack = _identity.audio;
    final i = 0.42 + 0.58 * _intensity;
    final emotion = 0.82 + 0.18 * _emotionDrive;
    return (pack.ambienceGain * i * _runtimeGuardStress * emotion).clamp(0.0, 1.0);
  }

  void _applyAmbienceTargetVolume() {
    final v = _muted ? 0.0 : _ambienceBaseVolume();
    try {
      _ambience?.setVolume(v);
    } catch (_) {}
  }

  Future<void> _startOrResumeAmbience() async {
    if (_muted || _lifecycle == AppLifecycleState.paused) return;
    try {
      _ambience ??= AudioPlayer();
      await _ambience!.setReleaseMode(ReleaseMode.loop);
      _applyAmbienceTargetVolume();
      await _ambience!.play(AssetSource(_identity.audio.ambienceAsset));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrowdAudioEngine] ambience: $e');
      }
    }
  }

  Future<void> startAmbienceLoop() async {
    await _startOrResumeAmbience();
  }

  Future<void> playCheer() async {
    if (_muted || _lifecycle == AppLifecycleState.paused) return;
    final now = DateTime.now();
    if (_runtimeGuardStress < 0.65 &&
        _lastCheerAt != null &&
        now.difference(_lastCheerAt!) < const Duration(milliseconds: 420)) {
      return;
    }
    _lastCheerAt = now;
    try {
      final pack = _identity.audio;
      await _oneShot.stop();
      await _oneShot.setVolume(
          (0.38 + 0.34 * _intensity) * pack.cheerGain * _runtimeGuardStress * (0.88 + 0.12 * _emotionDrive));
      try {
        await _oneShot.setPlaybackRate(pack.cheerPlaybackRate);
      } catch (_) {}
      await _oneShot.play(AssetSource(pack.cheerAsset));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrowdAudioEngine] cheer: $e');
      }
    }
  }

  Future<void> playLeaderSting() async {
    if (_muted || _lifecycle == AppLifecycleState.paused) return;
    if (_runtimeGuardStress < 0.55) {
      return;
    }
    try {
      final pack = _identity.audio;
      await _oneShot.stop();
      await _oneShot.setVolume(
          (0.48 + 0.26 * _intensity) * pack.leaderGain * _runtimeGuardStress * (0.9 + 0.1 * _emotionDrive));
      try {
        await _oneShot.setPlaybackRate(pack.leaderPlaybackRate);
      } catch (_) {}
      await _oneShot.play(AssetSource(pack.leaderStingAsset));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrowdAudioEngine] leader: $e');
      }
    }
  }

  Future<void> dispose() async {
    await _ambience?.dispose();
    await _oneShot.dispose();
  }
}

/// توافق مع الاسم السابق في الشاشات.
typedef CrowdStadiumAudioService = CrowdAudioEngine;
