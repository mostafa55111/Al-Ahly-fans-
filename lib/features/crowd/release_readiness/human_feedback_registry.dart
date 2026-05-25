/// نوع ملاحظة المختبر.
enum HumanFeedbackKind {
  readability,
  confusion,
  visualFatigue,
  ownerFlow,
  weakNetwork,
  accidentalAction,
  emotionalClarity,
}

class HumanFeedbackEntry {
  const HumanFeedbackEntry({
    required this.id,
    required this.kind,
    required this.note,
    required this.recordedAtMs,
    this.severity = 1,
  });

  final String id;
  final HumanFeedbackKind kind;
  final String note;
  final int recordedAtMs;
  final int severity;
}

/// سجل ملاحظات المختبرين — داخلي فقط.
class HumanFeedbackRegistry {
  final List<HumanFeedbackEntry> _entries = [];

  List<HumanFeedbackEntry> get entries => List.unmodifiable(_entries);

  void add({
    required HumanFeedbackKind kind,
    required String note,
    int severity = 1,
  }) {
    _entries.add(
      HumanFeedbackEntry(
        id: 'fb_${_entries.length + 1}',
        kind: kind,
        note: note,
        recordedAtMs: DateTime.now().millisecondsSinceEpoch,
        severity: severity.clamp(1, 5),
      ),
    );
  }

  bool get hasBlockingIssues =>
      _entries.any((e) => e.severity >= 4);

  int countByKind(HumanFeedbackKind kind) =>
      _entries.where((e) => e.kind == kind).length;
}
