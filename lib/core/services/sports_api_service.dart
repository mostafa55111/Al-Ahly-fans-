import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SportsApiService {
  // TheSportDB API Configuration (Free API - No Key Required)
  // https://www.thesportsdb.com/api/v1/json/3
  static const String sportsDbApiUrl = 'https://www.thesportsdb.com/api/v1/json/3';
  static const String ahlyTeamId = '133912'; // ID الأهلي في TheSportDB
  static const String egyptLeagueId = '4680'; // ID الدوري المصري الممتاز في TheSportDB

  Map<String, String> get _headers => {
    'Accept': 'application/json',
  };

  /// جلب المباريات القادمة للنادي الأهلي
  Future<List<Map<String, dynamic>>> getNextMatches() async {
    try {
      final response = await http.get(
        Uri.parse('$sportsDbApiUrl/eventsnext.php?id=$ahlyTeamId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['events'] != null) {
          return List<Map<String, dynamic>>.from(
            (data['events'] as List).map((item) => {
              'id': item['idEvent'],
              'utcDate': item['dateEvent'] + ' ' + (item['strTime'] ?? '19:00:00'),
              'timestamp': DateTime.parse(item['dateEvent'] + ' ' + (item['strTime'] ?? '19:00:00')).millisecondsSinceEpoch ~/ 1000,
              'status': 'Not Started',
              'statusShort': 'NS',
              'elapsed': 0,
              'homeTeam': item['strHomeTeam'],
              'awayTeam': item['strAwayTeam'],
              'homeTeamId': item['idHomeTeam'],
              'awayTeamId': item['idAwayTeam'],
              'homeLogo': item['strHomeTeamBadge'],
              'awayLogo': item['strAwayTeamBadge'],
              'competition': item['strLeague'],
              'venue': item['strVenue'] ?? 'ملعب غير محدد',
            })
          );
        }
      }
      return [];
    } catch (e) {
      debugPrint('خطأ في جلب المباريات القادمة: $e');
      return [];
    }
  }

  /// جلب نتائج المباريات السابقة
  Future<List<Map<String, dynamic>>> getLastMatches() async {
    try {
      final response = await http.get(
        Uri.parse('$sportsDbApiUrl/eventslast.php?id=$ahlyTeamId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null) {
          return List<Map<String, dynamic>>.from(
            (data['results'] as List).map((item) => {
              'id': item['idEvent'],
              'utcDate': item['dateEvent'] + ' ' + (item['strTime'] ?? '19:00:00'),
              'timestamp': DateTime.parse(item['dateEvent'] + ' ' + (item['strTime'] ?? '19:00:00')).millisecondsSinceEpoch ~/ 1000,
              'status': 'Finished',
              'statusShort': 'FT',
              'elapsed': 90,
              'homeTeam': item['strHomeTeam'],
              'awayTeam': item['strAwayTeam'],
              'homeTeamId': item['idHomeTeam'],
              'awayTeamId': item['idAwayTeam'],
              'homeLogo': item['strHomeTeamBadge'],
              'awayLogo': item['strAwayTeamBadge'],
              'homeScore': item['intHomeScore'],
              'awayScore': item['intAwayScore'],
              'competition': item['strLeague'],
            })
          );
        }
      }
      return [];
    } catch (e) {
      debugPrint('خطأ في جلب النتائج السابقة: $e');
      return [];
    }
  }

  /// جلب تشكيل المباراة (Lineups)
  Future<List<Map<String, dynamic>>> getMatchLineups(int fixtureId) async {
    try {
      final response = await http.get(
        Uri.parse('$footballApiUrl/fixtures/lineups?fixture=$fixtureId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['response'] != null) {
          return List<Map<String, dynamic>>.from(data['response']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('خطأ في جلب التشكيل: $e');
      return [];
    }
  }

  /// جلب ترتيب الدوري المصري
  Future<List<Map<String, dynamic>>> getLeagueStandings() async {
    try {
      final response = await http.get(
        Uri.parse('$sportsDbApiUrl/lookuptable.php?l=$egyptLeagueId&s=${DateTime.now().year - 1}-${DateTime.now().year}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['table'] != null) {
          return List<Map<String, dynamic>>.from(
            (data['table'] as List).map((team) => ({
              'rank': team['intRank'],
              'team': {
                'id': team['idTeam'],
                'name': team['strTeam'],
                'logo': team['strTeamBadge'],
              },
              'points': team['intPoints'],
              'played': team['intPlayed'],
              'won': team['intWin'],
              'draw': team['intDraw'],
              'lost': team['intLoss'],
              'goalsFor': team['intGoalsFor'],
              'goalsAgainst': team['intGoalsAgainst'],
              'goalDifference': team['intGoalDifference'],
            }))
          );
        }
      }
      return [];
    } catch (e) {
      debugPrint('خطأ في جلب الترتيب: $e');
      return [];
    }
  }

  String getMatchStatus(String? status) {
    if (status == null) return 'غير محدد';
    if (status.contains('Finished') || status.contains('FT')) return 'انتهت';
    if (status.contains('Not Started') || status.contains('NS')) return 'مجدولة';
    if (status.contains('In Progress')) return 'جارية الآن';
    return status;
  }

  String formatISODateTime(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'تاريخ غير محدد';
    try {
      final dateTime = DateTime.parse(isoDate).toLocal();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
