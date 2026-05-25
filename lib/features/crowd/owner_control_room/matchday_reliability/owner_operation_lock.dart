import 'package:flutter/foundation.dart';

/// مفاتيح عمليات المالك — نطاق غرفة التحكم فقط.
abstract final class OwnerOperationKeys {
  static const publishSession = 'publish_session';
  static const finalizeSession = 'finalize_session';
  static const emergencyClose = 'emergency_close';
  static const restoreLiveRuntime = 'restore_live_runtime';
  static const retryFinalize = 'retry_finalize';
  static const recoveryCheck = 'recovery_check';
}

/// قفل عمليات خفيف في الذاكرة — مثيل واحد لكل غرفة تحكم.
class OwnerOperationLock {
  OwnerOperationLock({Duration maxHold = const Duration(seconds: 15)})
      : _maxHold = maxHold;

  final Duration _maxHold;
  final Map<String, DateTime> _held = {};

  void _sweep() {
    final now = DateTime.now();
    _held.removeWhere((_, started) => now.difference(started) > _maxHold);
  }

  bool tryAcquire(String key) {
    _sweep();
    if (_held.containsKey(key)) {
      if (kDebugMode) {
        debugPrint('[OwnerOperationLock] rejected duplicate: $key');
      }
      return false;
    }
    _held[key] = DateTime.now();
    return true;
  }

  void release(String key) {
    _held.remove(key);
  }

  bool isHeld(String key) {
    _sweep();
    return _held.containsKey(key);
  }

  /// ينفّذ العملية مرة واحدة؛ يُرجع null عند رفض التكرار.
  Future<T?> runOnce<T>(String key, Future<T> Function() action) async {
    if (!tryAcquire(key)) return null;
    try {
      return await action();
    } finally {
      release(key);
    }
  }
}
