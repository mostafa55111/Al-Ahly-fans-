import 'package:flutter/foundation.dart';

class FinalizationAuditEntry {
  const FinalizationAuditEntry({
    required this.matchId,
    required this.success,
    required this.shadow,
    this.message,
    required this.atMs,
  });

  final String matchId;
  final bool success;
  final bool shadow;
  final String? message;
  final int atMs;
}

/// سجل إغلاق — للمقارنة بين محلي/بعيد/ظل.
class FinalizationAuditTrail {
  FinalizationAuditTrail._();

  static final FinalizationAuditTrail instance = FinalizationAuditTrail._();

  final List<FinalizationAuditEntry> _entries = [];
  int localFallbacks = 0;

  void recordRemoteFinalize({
    required String matchId,
    required bool success,
    required bool shadow,
    String? message,
  }) {
    if (!kDebugMode) return;
    _entries.add(
      FinalizationAuditEntry(
        matchId: matchId,
        success: success,
        shadow: shadow,
        message: message,
        atMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (_entries.length > 40) _entries.removeAt(0);
  }

  void recordLocalFallback({
    required String matchId,
    required String reason,
  }) {
    if (!kDebugMode) return;
    localFallbacks++;
    debugPrint('[FinalizeAudit] local_fallback match=$matchId reason=$reason');
  }

  List<FinalizationAuditEntry> get recent => List.unmodifiable(_entries);

  @visibleForTesting
  void reset() {
    _entries.clear();
    localFallbacks = 0;
  }
}
