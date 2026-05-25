import 'package:shared_preferences/shared_preferences.dart';

/// تخزين محلي لمعرّفات الريلز التي اختار المستخدم «غير مهتم» لتصفيتها من الفيد.
class IgnoredReelsStorage {
  IgnoredReelsStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'ignored_reels_v1';

  /// قراءة المجموعة من التخزين (متزامنة).
  Set<String> readCached() {
    final list = _prefs.getStringList(_key);
    if (list == null || list.isEmpty) return {};
    return list.toSet();
  }

  Future<void> addIgnored(String reelId) async {
    if (reelId.isEmpty) return;
    final next = readCached()..add(reelId);
    await _prefs.setStringList(_key, next.toList(growable: false));
  }

  Future<void> clearAll() async => _prefs.remove(_key);
}
