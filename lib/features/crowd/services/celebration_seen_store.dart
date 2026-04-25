import 'package:shared_preferences/shared_preferences.dart';

/// تخزين «شوهد الاحتفال مرة» لكل مفتاح فائز
class CelebrationSeenStore {
  CelebrationSeenStore(this._prefs);

  final SharedPreferences _prefs;
  static const String _prefix = 'nesr_celebration_v1_';

  String _key(String kind, String uniqueKey) => '$_prefix${kind}_$uniqueKey';

  bool hasSeen(String kind, String uniqueKey) {
    if (uniqueKey.isEmpty) return true;
    return _prefs.getBool(_key(kind, uniqueKey)) ?? false;
  }

  Future<void> markSeen(String kind, String uniqueKey) {
    if (uniqueKey.isEmpty) return Future.value();
    return _prefs.setBool(_key(kind, uniqueKey), true);
  }
}
