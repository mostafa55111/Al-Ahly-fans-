import 'package:flutter/foundation.dart';

/// نوع عنصر يُسجَّل لمراقبة الضغط على وقت التشغيل.
enum CrowdOverlayKind {
  playerCard,
  stadiumFx,
  overlayAsset,
  voteRing,
  atmosphere,
  other,
}

/// تذكرة تسجيل — يجب استدعاء [dispose] عند إزالة الـ overlay من الشجرة.
class OverlayRuntimeTicket {
  OverlayRuntimeTicket._(
    this._registry,
    this.id, {
    required CrowdOverlayKind initialKind,
    required bool initialVisible,
    required bool initialHeavy,
  })  : _kind = initialKind,
        _visible = initialVisible,
        _heavyAnimated = initialHeavy;

  final OverlayRuntimeRegistry _registry;
  final String id;

  bool _alive = true;
  bool _visible;
  bool _heavyAnimated;
  CrowdOverlayKind _kind;

  bool get visible => _visible;
  bool get heavyAnimated => _heavyAnimated;
  CrowdOverlayKind get kind => _kind;

  void update({
    bool? visible,
    bool? heavyAnimated,
    CrowdOverlayKind? kind,
  }) {
    if (!_alive) return;
    var changed = false;
    if (visible != null && visible != _visible) {
      _visible = visible;
      changed = true;
    }
    if (heavyAnimated != null && heavyAnimated != _heavyAnimated) {
      _heavyAnimated = heavyAnimated;
      changed = true;
    }
    if (kind != null && kind != _kind) {
      _kind = kind;
      changed = true;
    }
    if (changed) {
      _registry._syncEntry(
        id,
        _Entry(kind: _kind, visible: _visible, heavyAnimated: _heavyAnimated),
      );
    }
  }

  void dispose() {
    if (!_alive) return;
    _alive = false;
    _registry._remove(id);
  }
}

/// سجل مركزي لعناصر الرسم الثقيلة على الملعب — بدون أي اتصال بـ Firebase.
final class OverlayRuntimeRegistry extends ChangeNotifier {
  OverlayRuntimeRegistry._();
  static final OverlayRuntimeRegistry instance = OverlayRuntimeRegistry._();

  final Map<String, _Entry> _entries = {};
  static const int maxHeavyAnimated = 10;

  int get activeCount => _entries.length;

  int get visibleCount => _entries.values.where((e) => e.visible).length;

  int get heavyAnimatedVisibleCount =>
      _entries.values.where((e) => e.visible && e.heavyAnimated).length;

  int get heavyAnimatedTotalCount =>
      _entries.values.where((e) => e.heavyAnimated).length;

  /// يُنصح بعدم تجاوز [maxHeavyAnimated] للـ heavy المتحركة المرئية دفعة واحدة.
  bool get isHeavyAnimatedOverBudget => heavyAnimatedVisibleCount > maxHeavyAnimated;

  /// تسجيل عنصر. إن وُجد [id] مسبقاً يُستبدل الإدخال (idempotent للإعادة).
  OverlayRuntimeTicket register({
    required String id,
    CrowdOverlayKind kind = CrowdOverlayKind.other,
    bool visible = true,
    bool heavyAnimated = false,
  }) {
    _entries[id] = _Entry(kind: kind, visible: visible, heavyAnimated: heavyAnimated);
    _notify();
    final ticket = OverlayRuntimeTicket._(
      this,
      id,
      initialKind: kind,
      initialVisible: visible,
      initialHeavy: heavyAnimated,
    );
    return ticket;
  }

  void _remove(String id) {
    if (_entries.remove(id) != null) {
      _notify();
    }
  }

  void _syncEntry(String id, _Entry e) {
    _entries[id] = e;
    _notify();
  }

  void _notify() {
    notifyListeners();
  }
}

class _Entry {
  _Entry({
    required this.kind,
    required this.visible,
    required this.heavyAnimated,
  });

  final CrowdOverlayKind kind;
  final bool visible;
  final bool heavyAnimated;
}
