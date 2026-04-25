import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:gomhor_alahly_clean_new/features/matches/data/models/league_table_entry.dart';

/// ═════════════════════════════════════════════════════════════════
/// FootballApiService — عميل HTTP لـ TheSportsDB (مفتاح عام مجاني)
/// ═════════════════════════════════════════════════════════════════
/// - لا ترويسة `x-apisports-key`.
/// - [fetchAllAhlyMatchesMerged] يدمج **موسمين** (حالي + سابق) لأن
///   TheSportsDB قد يفتقر لمباريات «منتهية» حقيقية في الموسم الجديد
///   بينما الموسم السابق يبقى مكتملاً = أقرب لـ «آخر مباراة» موثوقة.
/// - بيانات المجتمع ليست رسمية؛ للدقة القصوى يلزم API رياضي مدفوع.
class FootballApiService {
  static const String _basePath =
      'https://www.thesportsdb.com/api/v1/json/3';

  static const String alAhlyTeamIdStr = '138995';
  static const int alAhlyTeamId = 138995;

  /// الموسم الحالي (نطاق 2025/2026)
  static const String currentSeason = '2025-2026';

  /// موسم سابق — يُستعمل للدمج لاسترجاع مباريات منتهية مؤكّدة
  static const String previousSeason = '2024-2025';

  static const List<String> alAhlyLeagueIds = <String>[
    '4829', // Egyptian Premier League
    '4720', // CAF Champions League
    '5185', // Egypt League Cup
    '4503', // FIFA Club World Cup
  ];

  final http.Client _client;

  FootballApiService({http.Client? client})
      : _client = client ?? http.Client();

  // ══════════════════════════════════════════════════════════════
  // مباريات — موسمين دمج
  // ══════════════════════════════════════════════════════════════

  /// مباريات الموسم الحالي + السابق (بعد إزالة التكرار) للأهلي فقط.
  Future<List<Map<String, dynamic>>> fetchAllAhlyMatchesMerged() async {
    final two = await Future.wait([
      _collectSeason(currentSeason),
      _collectSeason(previousSeason),
    ]);
    // نُفضّل أحدث رد لنفس [idEvent] (نادر التكرار بين موسمين)
    final byId = <String, Map<String, dynamic>>{};
    for (final m in two[0]) {
      byId[_eventKey(m)] = m;
    }
    for (final m in two[1]) {
      byId.putIfAbsent(_eventKey(m), () => m);
    }
    return byId.values.toList();
  }

  String _eventKey(Map<String, dynamic> m) {
    final id = m['idEvent']?.toString() ?? '';
    if (id.isNotEmpty) return id;
    return '${m['strEvent']}_${m['dateEvent']}_${m['strTime']}';
  }

  /// جمع مباريات الأهلي لـ [season] عبر البطولات الأربع بالتوازي.
  Future<List<Map<String, dynamic>>> _collectSeason(String season) async {
    final chunks = await Future.wait(
      alAhlyLeagueIds.map((lid) => _eventsForLeague(lid, season)),
    );
    final byId = <String, Map<String, dynamic>>{};
    for (final ch in chunks) {
      for (final raw in ch) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        if (!_hasAhly(m)) continue;
        byId[_eventKey(m)] = m;
      }
    }
    return byId.values.toList();
  }

  bool _hasAhly(Map<String, dynamic> m) {
    final h = m['idHomeTeam']?.toString();
    final a = m['idAwayTeam']?.toString();
    return h == alAhlyTeamIdStr || a == alAhlyTeamIdStr;
  }

  Future<List<dynamic>> _eventsForLeague(
    String leagueId,
    String season,
  ) async {
    final j = await _getJson('eventsseason.php', {
      'id': leagueId,
      's': season,
    });
    return (j['events'] as List?) ?? const <dynamic>[];
  }

  // ══════════════════════════════════════════════════════════════
  // جدول ترتيب — دوري/بطولة
  // ══════════════════════════════════════════════════════════════

  /// `lookuptable.php` — يرتّب [LeagueTableEntry] (قد يقسم مراحل/مجموعات)
  Future<List<LeagueTableEntry>> fetchLeagueTable(
    int leagueId,
    String season,
  ) async {
    final j = await _getJson('lookuptable.php', {
      'l': '$leagueId',
      's': season,
    });
    final arr = (j['table'] as List?) ?? const <dynamic>[];
    return arr
        .map((e) => LeagueTableEntry.fromTheSportsDb(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList(growable: false);
  }

  // ══════════════════════════════════════════════════════════════
  // مباراة + تشكيلة
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> fetchEventById(int idEvent) async {
    final j = await _getJson('lookupevent.php', {
      'id': '$idEvent',
    });
    final list = (j['events'] as List?)?.cast<dynamic>();
    if (list == null || list.isEmpty) return null;
    return Map<String, dynamic>.from(list.first as Map);
  }

  Future<List<Map<String, dynamic>>> fetchEventLineup(int idEvent) async {
    final j = await _getJson('lookuplineup.php', {'id': '$idEvent'});
    final L = (j['lineup'] as List?) ?? const <dynamic>[];
    return L
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  // ══════════════════════════════════════════════════════════════
  // داخلي
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _getJson(
    String file,
    Map<String, String> query,
  ) async {
    final uri = Uri.parse('$_basePath/$file').replace(
      queryParameters: query,
    );
    debugPrint('[TheSportsDB] GET $uri');
    try {
      final res = await _client
          .get(uri)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        throw FootballApiException(
          'الخادم ردّ بـ ${res.statusCode}',
          statusCode: res.statusCode,
        );
      }
      final dec = jsonDecode(res.body) as Map<String, dynamic>?;
      return dec ?? <String, dynamic>{};
    } on TimeoutException {
      throw const FootballApiException('انتهت مهلة الاتصال بالسيرفر');
    } on FootballApiException {
      rethrow;
    } catch (e) {
      throw FootballApiException('فشل الطلب: $e');
    }
  }

  void close() => _client.close();
}

class FootballApiException implements Exception {
  final String message;
  final int? statusCode;

  const FootballApiException(this.message, {this.statusCode});

  bool get isPlanLimit => false;

  @override
  String toString() =>
      'FootballApiException(${statusCode ?? '-'}): $message';
}
