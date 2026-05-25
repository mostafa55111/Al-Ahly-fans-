import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/rehearsal_surface_gate.dart';

enum OwnerProtocolStep {
  login,
  openCms,
  loadTacticalKit,
  verifyLineup,
  publishSession,
  monitorCountdown,
  verifyClosure,
  verifyHallOfFame,
  closeOperations,
}

class OwnerProtocolStepRecord {
  const OwnerProtocolStepRecord({
    required this.step,
    required this.durationMs,
    this.interruptions = 0,
    this.mistakes = const [],
    this.recoveryNotes = const [],
  });

  final OwnerProtocolStep step;
  final int durationMs;
  final int interruptions;
  final List<String> mistakes;
  final List<String> recoveryNotes;
}

/// بروتوكول يوم المباراة للمالك — TTMA + أخطاء تشغيلية.
class OwnerMatchdayProtocol {
  OwnerMatchdayProtocol._();

  static final OwnerMatchdayProtocol instance = OwnerMatchdayProtocol._();

  final List<OwnerProtocolStepRecord> _records = [];
  final List<String> _globalMistakes = [];
  DateTime? _startedAt;

  List<OwnerProtocolStepRecord> get records => List.unmodifiable(_records);

  int get totalTimeToMatchActiveMs {
    if (_records.isEmpty) return 0;
    return _records.fold<int>(0, (a, r) => a + r.durationMs);
  }

  void beginRehearsal() {
    RehearsalSurfaceGate.assertRehearsalAllowed();
    _records.clear();
    _globalMistakes.clear();
    _startedAt = DateTime.now();
  }

  void recordStep({
    required OwnerProtocolStep step,
    required int durationMs,
    int interruptions = 0,
    List<String> mistakes = const [],
    List<String> recoveryNotes = const [],
  }) {
    if (!RehearsalSurfaceGate.allowDressRehearsal) return;
    _records.add(
      OwnerProtocolStepRecord(
        step: step,
        durationMs: durationMs,
        interruptions: interruptions,
        mistakes: mistakes,
        recoveryNotes: recoveryNotes,
      ),
    );
    _globalMistakes.addAll(mistakes);
  }

  void recordOperationalMistake(String description) {
    if (!kDebugMode) return;
    _globalMistakes.add(description);
    debugPrint('[OwnerProtocol] mistake: $description');
  }

  Map<String, dynamic> snapshot() {
    if (!RehearsalSurfaceGate.allowDressRehearsal) {
      return const {'enabled': false};
    }
    return {
      'enabled': true,
      'ttmaMs': totalTimeToMatchActiveMs,
      'steps': _records
          .map(
            (r) => {
              'step': r.step.name,
              'durationMs': r.durationMs,
              'interruptions': r.interruptions,
              'mistakes': r.mistakes,
              'recovery': r.recoveryNotes,
            },
          )
          .toList(),
      'mistakes': _globalMistakes,
      'startedAt': _startedAt?.toIso8601String(),
    };
  }

  @visibleForTesting
  void reset() {
    _records.clear();
    _globalMistakes.clear();
    _startedAt = null;
  }
}
