import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gomhor_alahly_clean_new/features/crowd/services/fan_presence/fan_presence_profile.dart';

/// تخزين محلي + مزامنة RTDB مؤجّلة تحت `users/{uid}/fanPresence/{clubTag}`.
class FanPresenceStore {
  FanPresenceStore({
    required SharedPreferences prefs,
    FirebaseDatabase? database,
    required this.clubTag,
    this.syncDebounce = const Duration(seconds: 4),
  })  : _prefs = prefs,
        _database = database;

  final SharedPreferences _prefs;
  final FirebaseDatabase? _database;
  final String clubTag;
  final Duration syncDebounce;

  Timer? _syncTimer;
  String? _uid;
  FanPresenceProfile? _cached;

  String _localKey(String uid) => 'fan_presence_v1_${clubTag}_$uid';

  String? _remotePath(String uid) => 'users/$uid/fanPresence/$clubTag';

  FanPresenceProfile? get cached => _cached;

  Future<FanPresenceProfile?> load(String? uid) async {
    _uid = uid;
    if (uid == null || uid.isEmpty) {
      _cached = null;
      return null;
    }
    final raw = _prefs.getString(_localKey(uid));
    if (raw != null && raw.isNotEmpty) {
      try {
        _cached = FanPresenceProfile.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[FanPresenceStore] local parse: $e');
        }
      }
    }
    unawaited(_pullRemote(uid));
    return _cached;
  }

  Future<void> save(FanPresenceProfile profile) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    _cached = profile;
    await _prefs.setString(_localKey(uid), jsonEncode(profile.toJson()));
    _scheduleSync();
  }

  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(syncDebounce, () {
      unawaited(_pushRemote());
    });
  }

  Future<void> _pullRemote(String uid) async {
    final db = _database;
    if (db == null) return;
    try {
      final snap = await db.ref(_remotePath(uid)).get();
      if (!snap.exists || snap.value == null) return;
      final remote = FanPresenceProfile.fromJson(
        Map<String, dynamic>.from(snap.value as Map),
      );
      final local = _cached;
      if (local == null || remote.lastActiveAtMs >= local.lastActiveAtMs) {
        _cached = remote;
        await _prefs.setString(_localKey(uid), jsonEncode(remote.toJson()));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FanPresenceStore] pull: $e');
      }
    }
  }

  Future<void> _pushRemote() async {
    final uid = _uid;
    final profile = _cached;
    final db = _database;
    if (uid == null || profile == null || db == null) return;
    try {
      await db.ref(_remotePath(uid)).set(profile.toJson());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FanPresenceStore] push: $e');
      }
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
    if (_cached != null && _uid != null) {
      unawaited(_pushRemote());
    }
  }
}
