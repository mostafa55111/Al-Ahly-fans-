/// خطوة بروفة يوم مباراة حقيقي — تتبع يدوي للتوقيت.
enum MatchdayRehearsalStep {
  idle,
  ownerLogin,
  sessionBuild,
  publish,
  liveVoting,
  reconnectEvent,
  finalize,
  winnerReveal,
  noSessionFallback,
}

/// لقطة خطوة مع توقيت.
class RehearsalStepRecord {
  const RehearsalStepRecord({
    required this.step,
    required this.startedAtMs,
    this.completedAtMs = 0,
    this.notes = '',
    this.runtimeConfidenceOk = true,
    this.recoveryCorrect = true,
    this.smooth = true,
  });

  final MatchdayRehearsalStep step;
  final int startedAtMs;
  final int completedAtMs;
  final String notes;
  final bool runtimeConfidenceOk;
  final bool recoveryCorrect;
  final bool smooth;

  int? get durationMs =>
      completedAtMs > startedAtMs ? completedAtMs - startedAtMs : null;
}

/// تقرير البروفة التشغيلية.
class RealMatchdayRehearsalReport {
  const RealMatchdayRehearsalReport({
    required this.steps,
    required this.totalDurationMs,
    required this.allStepsRecorded,
    required this.ownerFlowSmooth,
  });

  final List<RehearsalStepRecord> steps;
  final int totalDurationMs;
  final bool allStepsRecorded;
  final bool ownerFlowSmooth;
}

/// محاكاة تدفق تشغيل كامل — بدون مسارات runtime جديدة.
class RealMatchdayRehearsal {
  final List<RehearsalStepRecord> _steps = [];
  int? _startedMs;

  static const orderedSteps = [
    MatchdayRehearsalStep.idle,
    MatchdayRehearsalStep.ownerLogin,
    MatchdayRehearsalStep.sessionBuild,
    MatchdayRehearsalStep.publish,
    MatchdayRehearsalStep.liveVoting,
    MatchdayRehearsalStep.reconnectEvent,
    MatchdayRehearsalStep.finalize,
    MatchdayRehearsalStep.winnerReveal,
    MatchdayRehearsalStep.noSessionFallback,
  ];

  void begin() {
    _startedMs = DateTime.now().millisecondsSinceEpoch;
    _steps.clear();
  }

  void recordStep({
    required MatchdayRehearsalStep step,
    int? durationMs,
    String notes = '',
    bool runtimeConfidenceOk = true,
    bool recoveryCorrect = true,
    bool smooth = true,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final start = durationMs != null ? now - durationMs : now;
    _steps.add(
      RehearsalStepRecord(
        step: step,
        startedAtMs: start,
        completedAtMs: now,
        notes: notes,
        runtimeConfidenceOk: runtimeConfidenceOk,
        recoveryCorrect: recoveryCorrect,
        smooth: smooth,
      ),
    );
  }

  RealMatchdayRehearsalReport buildReport() {
    final start = _startedMs ?? 0;
    final end = _steps.isEmpty
        ? start
        : _steps.map((s) => s.completedAtMs).reduce((a, b) => a > b ? a : b);
    final recorded = orderedSteps.every(
      (s) => _steps.any((r) => r.step == s),
    );
    final smooth = _steps.every((s) => s.smooth && s.recoveryCorrect);
    return RealMatchdayRehearsalReport(
      steps: List.unmodifiable(_steps),
      totalDurationMs: (end - start).clamp(0, 1 << 30),
      allStepsRecorded: recorded,
      ownerFlowSmooth: smooth,
    );
  }

  static String stepLabelAr(MatchdayRehearsalStep step) => switch (step) {
        MatchdayRehearsalStep.idle => 'خامل',
        MatchdayRehearsalStep.ownerLogin => 'دخول المالك',
        MatchdayRehearsalStep.sessionBuild => 'بناء الجلسة',
        MatchdayRehearsalStep.publish => 'نشر البث',
        MatchdayRehearsalStep.liveVoting => 'تصويت مباشر',
        MatchdayRehearsalStep.reconnectEvent => 'إعادة اتصال',
        MatchdayRehearsalStep.finalize => 'إنهاء',
        MatchdayRehearsalStep.winnerReveal => 'إعلان الفائز',
        MatchdayRehearsalStep.noSessionFallback => 'بدون جلسة',
      };
}
