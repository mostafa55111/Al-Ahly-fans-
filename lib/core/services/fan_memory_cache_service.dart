import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// ذاكرة مشجع محلية بسيطة للتخصيص السريع (ريلز + متجر).
class FanMemoryCacheService {
  FanMemoryCacheService(this._prefs);

  final SharedPreferences _prefs;

  String _k(String uid, String suffix) => 'fan_memory.$uid.$suffix';

  Future<void> recordFavoritePlayer({
    required String uid,
    required String playerName,
  }) async {
    final v = playerName.trim().toLowerCase();
    if (v.isEmpty) return;
    final set = {..._readStringList(_k(uid, 'favorite_players')), v}.toList();
    await _prefs.setStringList(_k(uid, 'favorite_players'), set);
  }

  Future<void> recordWatchedVideo({
    required String uid,
    required String videoId,
  }) async {
    await _incrementMapCounter(_k(uid, 'watched_videos'), videoId);
  }

  Future<void> recordLikedVideo({
    required String uid,
    required String videoId,
  }) async {
    await _incrementMapCounter(_k(uid, 'liked_videos'), videoId);
  }

  List<String> favoritePlayers(String uid) => _readStringList(_k(uid, 'favorite_players'));

  /// كلمات تفضيل بسيطة تساعد ترتيب منتجات المتجر.
  List<String> marketplaceKeywords(String uid) {
    final players = favoritePlayers(uid);
    final watched = _readMapCounter(_k(uid, 'watched_videos'));
    final topVideoTokens = watched.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final ids = topVideoTokens.take(6).map((e) => e.key.toLowerCase());
    return {...players, ...ids}.toList(growable: false);
  }

  Future<void> _incrementMapCounter(String key, String item) async {
    final cleaned = item.trim();
    if (cleaned.isEmpty) return;
    final map = _readMapCounter(key);
    map[cleaned] = (map[cleaned] ?? 0) + 1;
    await _prefs.setString(key, jsonEncode(map));
  }

  Map<String, int> _readMapCounter(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return map.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return <String, int>{};
    }
  }

  List<String> _readStringList(String key) => _prefs.getStringList(key) ?? const <String>[];
}
