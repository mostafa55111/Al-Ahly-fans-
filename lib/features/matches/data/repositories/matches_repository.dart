import 'package:flutter/foundation.dart';

import 'package:gomhor_alahly_clean_new/features/matches/data/datasources/football_api_service.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/fixture.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/league_table_entry.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';

/// ═════════════════════════════════════════════════════════════════
/// MatchesRepository
/// ═════════════════════════════════════════════════════════════════
/// - بيانات من TheSportsDB (موسمان مدمجان) + كاش مباريات 10 دقائق.
/// - جدول الترتيب: كاش منفصل 10 دقائق لكل (leagueId+season).
class MatchesRepository {
  final FootballApiService _api;

  List<Fixture>? _seasonCache;
  DateTime? _seasonCacheAt;
  static const Duration _seasonTtl = Duration(minutes: 10);

  final Map<String, List<LeagueTableEntry>> _tableCache = {};
  final Map<String, DateTime> _tableCacheAt = {};
  static const Duration _tableTtl = Duration(minutes: 10);

  MatchesRepository({FootballApiService? api})
      : _api = api ?? FootballApiService();

  // ══════════════════════════════════════════════
  // موسم مدمج (2025-26 + 2024-25)
  // ══════════════════════════════════════════════

  Future<List<Fixture>> getAllSeasonFixtures({bool force = false}) async {
    if (!force &&
        _seasonCache != null &&
        _seasonCacheAt != null &&
        DateTime.now().difference(_seasonCacheAt!) < _seasonTtl) {
      return _seasonCache!;
    }
    final raw = await _api.fetchAllAhlyMatchesMerged();
    final list = _parseMaps(raw);
    _seasonCache = list;
    _seasonCacheAt = DateTime.now();
    return list;
  }

  /// مباراة تالية: بعد الآن + ليست منتهية
  Future<List<Fixture>> getUpcomingAhly({int count = 12}) async {
    final all = await getAllSeasonFixtures();
    final now = DateTime.now();
    final list = all.where((f) => _isPlausibleUpcoming(f, now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list.take(count).toList();
  }

  /// منتهية: «Match Finished» + التاريخ سابقٌ (منطقي)
  Future<List<Fixture>> getRecentAhly({int count = 6}) async {
    final all = await getAllSeasonFixtures();
    final now = DateTime.now();
    final list = all
        .where(
          (f) => _isPlausibleFinished(f, now),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list.take(count).toList();
  }

  Future<List<Fixture>> getLiveAhly() async {
    final all = await getAllSeasonFixtures();
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 2));
    return all.where((f) => _isLiveCandidate(f, start, now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ── فلاتر جودة البيانات (TheSportsDB قد يسيء الجدولة)

  bool _isPlausibleFinished(Fixture f, DateTime now) {
    if (f.statusShort.trim() != 'Match Finished') return false;
    if (f.date.isAfter(now.add(const Duration(hours: 2)))) {
      return false; // مُتهاية بتاريخ لاحق = تناقض
    }
    return f.date.isBefore(now.add(const Duration(minutes: 1)));
  }

  bool _isPlausibleUpcoming(Fixture f, DateTime now) {
    if (f.phase == MatchPhase.finished) return false;
    if (f.statusShort.trim() == 'Match Finished') return false;
    return f.date.isAfter(now);
  }

  bool _isLiveCandidate(Fixture f, DateTime windowStart, DateTime windowEnd) {
    final st = f.statusShort.trim();
    if (st == 'Match Finished' || st == 'Not Started') return false;
    final d = f.date;
    return !d.isBefore(windowStart) && !d.isAfter(windowEnd);
  }

  /// جدول لمسابقة [fixture] — يُعاد كاملاً ثم نُبرز صف الأهلي في الواجهة
  Future<List<LeagueTableEntry>?> getLeagueTableForFixture(Fixture f) async {
    if (f.leagueId == null) return null;
    final seasons = <String>{
      if (f.seasonKey != null && f.seasonKey!.isNotEmpty) f.seasonKey!,
      FootballApiService.currentSeason,
      FootballApiService.previousSeason,
    }.toList();

    for (final season in seasons) {
      final key = '${f.leagueId}_$season';
      if (_tableValid(key)) {
        return _tableCache[key];
      }
      try {
        final table = await _api.fetchLeagueTable(f.leagueId!, season);
        if (table.isNotEmpty) {
          _tableCache[key] = table;
          _tableCacheAt[key] = DateTime.now();
          return table;
        }
      } catch (e) {
        debugPrint('getLeagueTableForFixture $season: $e');
      }
    }
    return null;
  }

  bool _tableValid(String key) {
    final at = _tableCacheAt[key];
    if (at == null) return false;
    if (DateTime.now().difference(at) > _tableTtl) {
      _tableCache.remove(key);
      _tableCacheAt.remove(key);
      return false;
    }
    return _tableCache.containsKey(key);
  }

  Future<Fixture?> getFixture(int id) async {
    try {
      final cached = await getAllSeasonFixtures();
      for (final x in cached) {
        if (x.id == id) return x;
      }
      final raw = await _api.fetchEventById(id);
      if (raw == null) return null;
      return Fixture.fromJson(raw);
    } catch (e) {
      debugPrint('getFixture: $e');
      return null;
    }
  }

  /// تحديث مباشر من [lookupevent] — بلا الاعتماد على كاش الموسم (للنتائج/الحالة لحظة بلحظة)
  Future<Fixture?> refreshFixtureById(int id) async {
    try {
      final raw = await _api.fetchEventById(id);
      if (raw == null) return null;
      return Fixture.fromJson(raw);
    } catch (e) {
      debugPrint('refreshFixtureById: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════
  // تشكيلة
  // ══════════════════════════════════════════════

  Future<List<TeamLineup>> getLineups(int fixtureId) async {
    try {
      final rows = await _api.fetchEventLineup(fixtureId);
      if (rows.isEmpty) return const [];
      final homeRows = rows
          .where(
            (r) => (r['strHome'] ?? '').toString().toLowerCase() == 'yes',
          )
          .toList();
      final awayRows = rows
          .where(
            (r) => (r['strHome'] ?? '').toString().toLowerCase() != 'yes',
          )
          .toList();
      final out = <TeamLineup>[];
      if (homeRows.isNotEmpty) {
        out.add(_lineupFromRows(homeRows));
      }
      if (awayRows.isNotEmpty) {
        out.add(_lineupFromRows(awayRows));
      }
      return out;
    } catch (e) {
      debugPrint('getLineups: $e');
      return const [];
    }
  }

  TeamLineup _lineupFromRows(List<Map<String, dynamic>> rows) {
    final tid = int.tryParse('${rows.first['idTeam'] ?? 0}') ?? 0;
    final tname = (rows.first['strTeam'] ?? '').toString();
    const String? logo = null;
    final start = <LineupPlayer>[];
    final subs = <LineupPlayer>[];
    for (final r in rows) {
      final p = _playerFromLineupRow(r);
      if ((r['strSubstitute'] ?? '').toString().toLowerCase() == 'yes') {
        subs.add(p);
      } else {
        start.add(p);
      }
    }
    return TeamLineup(
      teamId: tid,
      teamName: tname,
      teamLogo: logo,
      formation: '—',
      startXI: start,
      substitutes: subs,
    );
  }

  LineupPlayer _playerFromLineupRow(Map<String, dynamic> r) {
    return LineupPlayer(
      id: int.tryParse('${r['idPlayer'] ?? ''}'),
      name: (r['strPlayer'] ?? '—').toString(),
      number: int.tryParse('${r['intSquadNumber'] ?? ''}'),
      position: r['strPosition']?.toString(),
      photo: (r['strCutout'] ?? r['strThumb'])?.toString(),
    );
  }

  Future<List<LineupPlayer>> getAhlyParticipants(int fixtureId) async {
    final rows = await _api.fetchEventLineup(fixtureId);
    if (rows.isEmpty) return const [];
    final mine = rows.where(
      (r) =>
          (r['idTeam'] ?? '').toString() == FootballApiService.alAhlyTeamIdStr,
    );
    return mine.map(_playerFromLineupRow).toList();
  }

  void invalidateCache() {
    _seasonCache = null;
    _seasonCacheAt = null;
    _tableCache.clear();
    _tableCacheAt.clear();
  }

  List<Fixture> _parseMaps(List<Map<String, dynamic>> raw) {
    final list = <Fixture>[];
    for (final m in raw) {
      try {
        list.add(Fixture.fromJson(m));
      } catch (e) {
        debugPrint('parse fixture error: $e');
      }
    }
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}
