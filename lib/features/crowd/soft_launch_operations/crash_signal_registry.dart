import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/observability/crashlytics_bootstrap.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_surface_gate.dart';

/// إشارة تعطل داخلية — لا نظام crash مخصص.
enum CrashSignalKind {
  startup,
  voteInteraction,
  finalize,
  ownerPanel,
  restore,
}

class CrashSignalRecord {
  const CrashSignalRecord({
    required this.kind,
    required this.message,
    required this.at,
  });

  final CrashSignalKind kind;
  final String message;
  final DateTime at;
}

/// يسجّل الإشارات ويرسل غير القاتلة عبر CrashlyticsBootstrap فقط.
class CrashSignalRegistry {
  CrashSignalRegistry._();

  static final CrashSignalRegistry instance = CrashSignalRegistry._();

  final List<CrashSignalRecord> _signals = [];

  List<CrashSignalRecord> get signals => List.unmodifiable(_signals);

  int countInWindow(Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return _signals.where((s) => s.at.isAfter(cutoff)).length;
  }

  bool get spikeDetected => countInWindow(const Duration(hours: 1)) >= 5;

  Future<void> record({
    required CrashSignalKind kind,
    required String message,
    Object? error,
    StackTrace? stack,
    bool fatal = false,
  }) async {
    if (!SoftLaunchSurfaceGate.visible) return;
    _signals.add(
      CrashSignalRecord(kind: kind, message: message, at: DateTime.now()),
    );
    if (_signals.length > 100) {
      _signals.removeRange(0, _signals.length - 100);
    }
    if (!CrashlyticsBootstrap.isReady) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error ?? Exception('[$kind] $message'),
        stack ?? StackTrace.current,
        fatal: fatal,
        reason: kind.name,
      );
    } catch (e) {
      debugPrint('[CrashSignalRegistry] record failed: $e');
    }
  }

  @visibleForTesting
  void resetForTests() => _signals.clear();
}
