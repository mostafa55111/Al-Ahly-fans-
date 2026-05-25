import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_surface_gate.dart';

/// شدة الحادث التشغيلي.
enum LiveIncidentSeverity {
  low,
  medium,
  high,
  critical,
}

/// نوع حادث الإنتاج.
enum LiveIncidentType {
  finalizeFailure,
  reconnectStorm,
  uploadFailure,
  ownerDisconnect,
  degradedReads,
  emergencyClose,
  recoveryActivation,
}

class LiveIncidentRecord {
  const LiveIncidentRecord({
    required this.type,
    required this.severity,
    required this.message,
    required this.at,
  });

  final LiveIncidentType type;
  final LiveIncidentSeverity severity;
  final String message;
  final DateTime at;
}

/// تتبع حوادث الإنتاج — debug/profile فقط.
class LiveIncidentTracker {
  LiveIncidentTracker._();

  static final LiveIncidentTracker instance = LiveIncidentTracker._();

  final List<LiveIncidentRecord> _incidents = [];

  List<LiveIncidentRecord> get incidents => List.unmodifiable(_incidents);

  void record({
    required LiveIncidentType type,
    required LiveIncidentSeverity severity,
    required String message,
  }) {
    if (!SoftLaunchSurfaceGate.visible) return;
    final rec = LiveIncidentRecord(
      type: type,
      severity: severity,
      message: message,
      at: DateTime.now(),
    );
    _incidents.add(rec);
    if (kDebugMode) {
      debugPrint('[LiveIncident] $type $severity: $message');
    }
    if (_incidents.length > 200) {
      _incidents.removeRange(0, _incidents.length - 200);
    }
  }

  int countBySeverity(LiveIncidentSeverity s) =>
      _incidents.where((i) => i.severity == s).length;

  bool get hasCriticalActive => _incidents.any(
        (i) =>
            i.severity == LiveIncidentSeverity.critical &&
            DateTime.now().difference(i.at).inHours < 2,
      );

  bool get hasHighReconnectStorm => _incidents
          .where((i) => i.type == LiveIncidentType.reconnectStorm)
          .where((i) => i.severity.index >= LiveIncidentSeverity.high.index)
          .length >=
      3;

  @visibleForTesting
  void resetForTests() => _incidents.clear();
}
