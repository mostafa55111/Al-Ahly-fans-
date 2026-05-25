import 'package:shared_preferences/shared_preferences.dart';

/// لقطة سياق تشغيل المالك — استئناف بعد إغلاق التطبيق.
class LiveSessionPersistenceSnapshot {
  const LiveSessionPersistenceSnapshot({
    this.activeMatchId = '',
    this.phaseWire = '',
    this.formation = '4-3-3',
    this.draftId = '',
    this.operationalTabIndex = 1,
    this.savedAtMs = 0,
  });

  final String activeMatchId;
  final String phaseWire;
  final String formation;
  final String draftId;
  final int operationalTabIndex;
  final int savedAtMs;

  bool get hasLiveContext =>
      activeMatchId.isNotEmpty && operationalTabIndex >= 0;
}

/// حفظ خفيف محلي — لا يُعيد نشر ولا finalize.
class LiveSessionPersistence {
  LiveSessionPersistence(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String club) => 'owner_matchday_ctx_$club';

  Future<void> save({
    required String clubTag,
    required LiveSessionPersistenceSnapshot snapshot,
  }) async {
    await _prefs.setString('${_key(clubTag)}_match', snapshot.activeMatchId);
    await _prefs.setString('${_key(clubTag)}_phase', snapshot.phaseWire);
    await _prefs.setString('${_key(clubTag)}_formation', snapshot.formation);
    await _prefs.setString('${_key(clubTag)}_draft', snapshot.draftId);
    await _prefs.setInt('${_key(clubTag)}_tab', snapshot.operationalTabIndex);
    await _prefs.setInt(
      '${_key(clubTag)}_at',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  LiveSessionPersistenceSnapshot load(String clubTag) {
    return LiveSessionPersistenceSnapshot(
      activeMatchId: _prefs.getString('${_key(clubTag)}_match') ?? '',
      phaseWire: _prefs.getString('${_key(clubTag)}_phase') ?? '',
      formation: _prefs.getString('${_key(clubTag)}_formation') ?? '4-3-3',
      draftId: _prefs.getString('${_key(clubTag)}_draft') ?? '',
      operationalTabIndex: _prefs.getInt('${_key(clubTag)}_tab') ?? 1,
      savedAtMs: _prefs.getInt('${_key(clubTag)}_at') ?? 0,
    );
  }

  Future<void> clear(String clubTag) async {
    await _prefs.remove('${_key(clubTag)}_match');
    await _prefs.remove('${_key(clubTag)}_phase');
    await _prefs.remove('${_key(clubTag)}_formation');
    await _prefs.remove('${_key(clubTag)}_draft');
    await _prefs.remove('${_key(clubTag)}_tab');
    await _prefs.remove('${_key(clubTag)}_at');
  }
}
