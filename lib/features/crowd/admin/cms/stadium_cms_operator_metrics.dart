import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_friction_kind.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_operator_run.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_repository.dart';
import 'package:uuid/uuid.dart';

/// مسجّل TTMA + انقطاعات معرفية — قرارات UX فقط، لا ضوضاء.
class StadiumCmsOperatorMetrics {
  StadiumCmsOperatorMetrics({
    required StadiumCmsRepository cms,
    required String clubTag,
  })  : _cms = cms,
        _clubTag = clubTag.trim().toLowerCase(),
        _runId = const Uuid().v4(),
        _startedAt = DateTime.now();

  final StadiumCmsRepository _cms;
  final String _clubTag;
  final String _runId;
  final DateTime _startedAt;

  final List<StadiumCmsFrictionEvent> cognitiveInterruptions = [];
  final Map<String, int> phaseMarks = {};

  int _tabIndex = 0;
  int _lastTabChangeMs = 0;
  int playerEdits = 0;
  int _librarySearchCount = 0;
  int _kitLoadCount = 0;
  String? _lastKitName;
  bool _published = false;
  bool _persisted = false;

  String? _lastActionKey;
  int _lastActionAt = 0;
  int _saveActions = 0;

  /// للتوافق مع HUD القديم.
  List<StadiumCmsFrictionEvent> get frictions => cognitiveInterruptions;

  int get cognitiveInterruptionCount => cognitiveInterruptions.length;

  Map<String, int> get interruptionSummary {
    final out = <String, int>{};
    for (final e in cognitiveInterruptions) {
      final k = e.kind.name;
      out[k] = (out[k] ?? 0) + 1;
    }
    return out;
  }

  StadiumCmsFrictionKind? get dominantInterruption {
    final s = interruptionSummary;
    if (s.isEmpty) return null;
    var best = s.keys.first;
    var max = 0;
    s.forEach((k, v) {
      if (v > max) {
        max = v;
        best = k;
      }
    });
    return StadiumCmsFrictionKind.values.firstWhere(
      (e) => e.name == best,
      orElse: () => StadiumCmsFrictionKind.hesitation,
    );
  }

  void onCmsOpened() => _markPhase('cms_opened');

  void onSessionReady(String source) {
    onAction('session_$source');
    _markPhase('session_$source');
  }

  void onKitLoaded(String kitName) {
    onAction('kit_load');
    final name = kitName.trim().isEmpty ? 'unnamed' : kitName.trim();
    _kitLoadCount++;
    if (_kitLoadCount > 1) {
      _interrupt(
        StadiumCmsFrictionKind.kitSwitch,
        detail: _lastKitName != null ? '$_lastKitName → $name' : name,
      );
    }
    _lastKitName = name;
    _markPhase('kit_$name');
  }

  void onPlayerEdit() {
    onAction('player_edit');
    playerEdits++;
    _markPhase('roster_edited');
  }

  void onCardUploadAttempt() {
    onAction('card_upload');
    _markPhase('card_upload');
  }

  void onPreviewTab({required int playerCount}) {
    onAction('preview_tab');
    _markPhase('preview_opened');
    if (playerCount == 0) {
      _interrupt(
        StadiumCmsFrictionKind.previewBeforeReady,
        detail: 'معاينة بدون لاعبين',
      );
    }
  }

  void onVotingPublished() {
    onAction('publish_voting');
    _published = true;
    _markPhase('voting_published');
  }

  void onTabChanged(int index) {
    if (index == _tabIndex) return;
    final now = elapsedMs;
    if (_lastTabChangeMs > 0 && now - _lastTabChangeMs < 10000) {
      _interrupt(StadiumCmsFrictionKind.tabSwitch, detail: 'تبويب $_tabIndex → $index');
    }
    _lastTabChangeMs = now;
    _tabIndex = index;
  }

  void onLibrarySearch() {
    _librarySearchCount++;
    if (_librarySearchCount >= 2) {
      _interrupt(
        StadiumCmsFrictionKind.librarySearch,
        detail: 'بحث #$_librarySearchCount',
      );
    }
  }

  void onSaveAction(String label) {
    onAction('save_$label');
    _saveActions++;
    if (_saveActions >= 2) {
      _interrupt(StadiumCmsFrictionKind.repeatedTap, detail: 'حفظ ($label)');
    }
  }

  void onBackNavigation() {
    _interrupt(StadiumCmsFrictionKind.backNavigation, detail: 'خروج من CMS');
  }

  void onAction(String actionKey) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastActionKey == actionKey && now - _lastActionAt < 650) {
      _interrupt(StadiumCmsFrictionKind.repeatedTap, detail: actionKey);
    } else if (_lastActionAt > 0 && now - _lastActionAt > 3500) {
      final sec = ((now - _lastActionAt) / 1000).round();
      _interrupt(StadiumCmsFrictionKind.hesitation, detail: '${sec}s قبل $actionKey');
    }
    _lastActionKey = actionKey;
    _lastActionAt = now;
  }

  int get elapsedMs => DateTime.now().difference(_startedAt).inMilliseconds;

  bool get reachedEliteWindow =>
      elapsedMs <= 90000 && cognitiveInterruptionCount <= 3;

  String get elapsedLabel {
    final s = elapsedMs ~/ 1000;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  void _markPhase(String phase) {
    phaseMarks.putIfAbsent(phase, () => elapsedMs);
  }

  void _interrupt(StadiumCmsFrictionKind kind, {String detail = ''}) {
    cognitiveInterruptions.add(
      StadiumCmsFrictionEvent(kind: kind, atMs: elapsedMs, detail: detail),
    );
  }

  Future<void> persist({required bool abandoned}) async {
    if (_persisted) return;
    _persisted = true;
    final now = DateTime.now().millisecondsSinceEpoch;
    final run = StadiumCmsOperatorRun(
      id: _runId,
      startedAt: _startedAt.millisecondsSinceEpoch,
      completedAt: now,
      totalMs: elapsedMs,
      published: _published,
      playerEdits: playerEdits,
      cognitiveInterruptions: List.unmodifiable(cognitiveInterruptions),
      interruptionSummary: interruptionSummary,
      phaseMarks: Map.unmodifiable(phaseMarks),
      outcome: _published
          ? (reachedEliteWindow ? 'published_elite' : 'published_slow')
          : (abandoned ? 'abandoned' : 'exited'),
    );
    await _cms.saveActivationRun(clubTag: _clubTag, run: run);
  }
}
