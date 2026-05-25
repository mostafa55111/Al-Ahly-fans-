import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_friction_kind.dart';

class StadiumCmsFrictionEvent extends Equatable {
  const StadiumCmsFrictionEvent({
    required this.kind,
    required this.atMs,
    this.detail = '',
  });

  final StadiumCmsFrictionKind kind;
  final int atMs;
  final String detail;

  factory StadiumCmsFrictionEvent.fromMap(Map<dynamic, dynamic> m) {
    final kindRaw = m['kind']?.toString() ?? '';
    final kind = StadiumCmsFrictionKind.values.firstWhere(
      (e) => e.name == kindRaw,
      orElse: () => StadiumCmsFrictionKind.hesitation,
    );
    return StadiumCmsFrictionEvent(
      kind: kind,
      atMs: (m['atMs'] as num?)?.toInt() ?? 0,
      detail: m['detail']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'kind': kind.name,
        'atMs': atMs,
        'detail': detail,
      };

  @override
  List<Object?> get props => [kind, atMs, detail];
}

/// قياس TTMA + انقطاعات معرفية — ملخص `interruptionSummary` لقرار UX.
class StadiumCmsOperatorRun extends Equatable {
  const StadiumCmsOperatorRun({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.totalMs,
    required this.published,
    required this.playerEdits,
    required this.cognitiveInterruptions,
    required this.interruptionSummary,
    required this.phaseMarks,
    this.outcome = 'abandoned',
  });

  final String id;
  final int startedAt;
  final int completedAt;
  final int totalMs;
  final bool published;
  final int playerEdits;
  final List<StadiumCmsFrictionEvent> cognitiveInterruptions;
  final Map<String, int> interruptionSummary;
  final Map<String, int> phaseMarks;
  final String outcome;

  int get cognitiveInterruptionCount => cognitiveInterruptions.length;

  bool get reachedEliteWindow =>
      totalMs > 0 && totalMs <= 90000 && cognitiveInterruptionCount <= 3;

  factory StadiumCmsOperatorRun.fromMap(String id, Map<dynamic, dynamic> m) {
    final raw = m['cognitiveInterruptions'] ?? m['frictions'];
    final interruptions = <StadiumCmsFrictionEvent>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          interruptions.add(StadiumCmsFrictionEvent.fromMap(Map<dynamic, dynamic>.from(e)));
        }
      }
    }
    final summaryRaw = m['interruptionSummary'];
    final summary = <String, int>{};
    if (summaryRaw is Map) {
      summaryRaw.forEach((k, v) {
        summary[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    } else {
      for (final e in interruptions) {
        summary[e.kind.name] = (summary[e.kind.name] ?? 0) + 1;
      }
    }
    final phasesRaw = m['phaseMarks'];
    final phases = <String, int>{};
    if (phasesRaw is Map) {
      phasesRaw.forEach((k, v) {
        phases[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }
    return StadiumCmsOperatorRun(
      id: id,
      startedAt: (m['startedAt'] as num?)?.toInt() ?? 0,
      completedAt: (m['completedAt'] as num?)?.toInt() ?? 0,
      totalMs: (m['totalMs'] as num?)?.toInt() ?? 0,
      published: m['published'] == true || m['published'] == 1,
      playerEdits: (m['playerEdits'] as num?)?.toInt() ?? 0,
      cognitiveInterruptions: interruptions,
      interruptionSummary: summary,
      phaseMarks: phases,
      outcome: m['outcome']?.toString() ?? 'abandoned',
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'startedAt': startedAt,
        'completedAt': completedAt,
        'totalMs': totalMs,
        'published': published,
        'playerEdits': playerEdits,
        'cognitiveInterruptionCount': cognitiveInterruptionCount,
        'cognitiveInterruptions': cognitiveInterruptions.map((e) => e.toWriteMap()).toList(),
        'frictions': cognitiveInterruptions.map((e) => e.toWriteMap()).toList(),
        'interruptionSummary': interruptionSummary,
        'phaseMarks': phaseMarks,
        'outcome': outcome,
        'reachedEliteWindow': reachedEliteWindow,
      };

  @override
  List<Object?> get props => [
        id,
        startedAt,
        completedAt,
        totalMs,
        published,
        playerEdits,
        cognitiveInterruptions,
        interruptionSummary,
        phaseMarks,
        outcome,
      ];
}
