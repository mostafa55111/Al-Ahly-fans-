import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/socket_pressure_guard.dart';

/// حالة الشبكة لغرفة التحكم — بدون polling.
enum MatchdayNetworkState {
  healthy,
  degraded,
  reconnecting,
  unstable,
  offline,
}

/// عملية مالك معلّقة تتطلب إعادة محاولة يدوية.
class PendingOwnerAction {
  const PendingOwnerAction({
    required this.key,
    required this.label,
    required this.recordedAtMs,
  });

  final String key;
  final String label;
  final int recordedAtMs;
}

/// مرونة الشبكة — قراءات آمنة فقط تُعاد تلقائياً.
class MatchdayNetworkResilience {
  MatchdayNetworkResilience({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  PendingOwnerAction? _pending;

  PendingOwnerAction? get pendingAction => _pending;

  void setPending(PendingOwnerAction action) => _pending = action;

  void clearPending() => _pending = null;

  Future<MatchdayNetworkState> evaluate() async {
    final results = await _connectivity.checkConnectivity();
    final hasLink = _hasConnectivity(results);
    if (!hasLink) return MatchdayNetworkState.offline;

    final pressure = SocketPressureGuard.instance;
    if (pressure.isAppBackgrounded) {
      return MatchdayNetworkState.reconnecting;
    }
    if (pressure.runtimePressureHigh) {
      return MatchdayNetworkState.unstable;
    }
    return MatchdayNetworkState.healthy;
  }

  bool _hasConnectivity(dynamic results) {
    if (results is List) {
      for (final item in results) {
        if (item != ConnectivityResult.none) return true;
      }
      return false;
    }
    return results != ConnectivityResult.none;
  }

  /// قراءة آمنة — إعادة محاولة مرة عند التدهور فقط.
  Future<T?> runRetrySafeRead<T>({
    required Future<T> Function() read,
    int maxAttempts = 2,
  }) async {
    var attempt = 0;
    while (attempt < maxAttempts) {
      attempt++;
      final state = await evaluate();
      if (state == MatchdayNetworkState.offline) return null;
      try {
        return await read();
      } catch (_) {
        if (attempt >= maxAttempts) rethrow;
        if (state == MatchdayNetworkState.healthy) break;
      }
    }
    return null;
  }

  /// كتابة — لا إعادة تلقائية؛ تُسجَّل كمعلّقة عند الفشل.
  Future<T?> runOwnerWrite<T>({
    required String pendingKey,
    required String pendingLabel,
    required Future<T> Function() write,
  }) async {
    final state = await evaluate();
    if (state == MatchdayNetworkState.offline) {
      setPending(
        PendingOwnerAction(
          key: pendingKey,
          label: pendingLabel,
          recordedAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return null;
    }
    try {
      final result = await write();
      clearPending();
      return result;
    } catch (_) {
      setPending(
        PendingOwnerAction(
          key: pendingKey,
          label: pendingLabel,
          recordedAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      rethrow;
    }
  }

  static String labelAr(MatchdayNetworkState state) => switch (state) {
        MatchdayNetworkState.healthy => 'اتصال سليم',
        MatchdayNetworkState.degraded => 'اتصال ضعيف',
        MatchdayNetworkState.reconnecting => 'إعادة اتصال',
        MatchdayNetworkState.unstable => 'غير مستقر',
        MatchdayNetworkState.offline => 'بدون اتصال',
      };
}
