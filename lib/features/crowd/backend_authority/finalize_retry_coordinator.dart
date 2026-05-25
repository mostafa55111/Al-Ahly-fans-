import 'dart:math';

import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_runtime_report.dart';

/// إعادة محاولة إغلاق الجلسة — تأخيرات ثابتة + jitter، بدون Timer.periodic.
class FinalizeRetryCoordinator {
  FinalizeRetryCoordinator({
    Random? random,
    List<int>? delaysMs,
  })  : _random = random ?? Random(),
        _delaysMs = delaysMs ?? const [2000, 5000, 15000];

  final Random _random;
  final List<int> _delaysMs;
  static const _maxJitterMs = 400;

  final Set<String> _inFlightKeys = {};

  /// يشغّل [attempt] مرة فوراً ثم حتى 3 إعادات (2s، 5s، 15s).
  Future<bool> runWithRetry({
    required String dedupeKey,
    required Future<bool> Function() attempt,
    bool Function()? shouldAbort,
  }) async {
    if (_inFlightKeys.contains(dedupeKey)) return false;
    _inFlightKeys.add(dedupeKey);
    try {
      for (var i = 0; i <= _delaysMs.length; i++) {
        if (shouldAbort?.call() == true) return false;
        final ok = await attempt();
        if (ok) return true;
        if (i >= _delaysMs.length) break;
        final jitter = _random.nextInt(_maxJitterMs);
        await Future<void>.delayed(
          Duration(milliseconds: _delaysMs[i] + jitter),
        );
      }
      VoteScaleRuntimeReport.instance.recordRetryExhausted();
      return false;
    } finally {
      _inFlightKeys.remove(dedupeKey);
    }
  }

  void reset() => _inFlightKeys.clear();
}
