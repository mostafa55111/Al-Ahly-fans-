import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/chaos/chaos_fault_profile.dart';

class ChaosEvent {
  const ChaosEvent({required this.kind, required this.message, this.atMs});

  final ChaosFaultKind kind;
  final String message;
  final int? atMs;
}

class ChaosInjector {
  ChaosInjector._();

  static final ChaosInjector instance = ChaosInjector._();
  final List<ChaosEvent> _events = [];

  List<ChaosEvent> get events => List.unmodifiable(_events);

  Future<T> wrap<T>({
    required ChaosFaultKind kind,
    required Future<T> Function() action,
    T Function()? onFailure,
  }) async {
    if (!ChaosMode.enabled) return action();

    final delay = ChaosMode.latencyMs(kind);
    if (delay > 0) await Future<void>.delayed(Duration(milliseconds: delay));

    if (ChaosMode.shouldInject(kind)) {
      _record(kind, 'injected');
      if (onFailure != null) return onFailure();
      throw StateError('chaos:$kind');
    }

    try {
      return await action();
    } catch (e) {
      _record(kind, e.toString());
      rethrow;
    }
  }

  void _record(ChaosFaultKind kind, String message) {
    if (!kDebugMode) return;
    _events.add(
      ChaosEvent(
        kind: kind,
        message: message,
        atMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (_events.length > 200) _events.removeAt(0);
    debugPrint('[Chaos] $kind — $message');
  }

  void reset() => _events.clear();
}
