import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/live_match_updates/data/models/match_model.dart';

abstract class MatchRemoteDataSource {
  Future<List<MatchModel>> getAllMatches();
  Future<List<MatchModel>> getLiveMatches();
  Future<List<MatchModel>> getUpcomingMatches({required int days});
  Future<List<MatchModel>> getPastMatches({required int days});
  Future<MatchModel> getMatchDetails(String matchId);
  Future<List<MatchModel>> searchMatches(String query);
  Future<List<MatchModel>> filterByTournament(String tournament);
  Future<List<MatchModel>> filterBySeason(String season);
  Future<Map<String, dynamic>> getMatchStatistics(String matchId);
  Future<Map<String, dynamic>> getPlayerStats({
    required String matchId,
    required String playerId,
  });
  Future<bool> subscribeToLiveUpdates(String matchId);
  Future<bool> unsubscribeFromLiveUpdates(String matchId);
  Future<List<dynamic>> getMatchTimeline(String matchId);
  Future<List<dynamic>> getTeamLineup({
    required String matchId,
    required String teamId,
  });
  Future<Map<String, dynamic>> getMatchComparisons(String matchId);
  Future<Map<String, dynamic>> getHeadToHead({
    required String team1Id,
    required String team2Id,
  });
}

class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final DatabaseReference _databaseRef;

  MatchRemoteDataSourceImpl({
    required DatabaseReference databaseRef,
  }) : _databaseRef = databaseRef;

  @override
  Future<List<MatchModel>> getAllMatches() async {
    try {
      final snapshot = await _databaseRef.child('matches').get();
      if (!snapshot.exists) return [];

      final matches = <MatchModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final matchData = entry.value as Map<dynamic, dynamic>;
        matches.add(MatchModel.fromJson(Map<String, dynamic>.from(matchData)));
      }

      return matches;
    } catch (e) {
      throw ServerException(message: 'فشل جلب المباريات: $e');
    }
  }

  @override
  Future<List<MatchModel>> getLiveMatches() async {
    try {
      final snapshot = await _databaseRef.child('matches').orderByChild('status').equalTo('live').get();
      if (!snapshot.exists) return [];

      final matches = <MatchModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final matchData = entry.value as Map<dynamic, dynamic>;
        matches.add(MatchModel.fromJson(Map<String, dynamic>.from(matchData)));
      }

      return matches;
    } catch (e) {
      throw ServerException(message: 'فشل جلب المباريات المباشرة: $e');
    }
  }

  @override
  Future<List<MatchModel>> getUpcomingMatches({required int days}) async {
    try {
      final snapshot = await _databaseRef.child('matches').get();
      if (!snapshot.exists) return [];

      final matches = <MatchModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: days));

      for (final entry in data.entries) {
        final matchData = entry.value as Map<dynamic, dynamic>;
        final match = MatchModel.fromJson(Map<String, dynamic>.from(matchData));
        
        if (match.matchDate != null) {
          final matchDateTime = DateTime.tryParse(match.matchDate!);
          if (matchDateTime != null && matchDateTime.isAfter(now) && matchDateTime.isBefore(futureDate)) {
            matches.add(match);
          }
        }
      }

      return matches;
    } catch (e) {
      throw ServerException(message: 'فشل جلب المباريات القادمة: $e');
    }
  }

  @override
  Future<List<MatchModel>> getPastMatches({required int days}) async {
    try {
      final snapshot = await _databaseRef.child('matches').get();
      if (!snapshot.exists) return [];

      final matches = <MatchModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      final now = DateTime.now();
      final pastDate = now.subtract(Duration(days: days));

      for (final entry in data.entries) {
        final matchData = entry.value as Map<dynamic, dynamic>;
        final match = MatchModel.fromJson(Map<String, dynamic>.from(matchData));
        
        if (match.matchDate != null) {
          final matchDateTime = DateTime.tryParse(match.matchDate!);
          if (matchDateTime != null && matchDateTime.isBefore(now) && matchDateTime.isAfter(pastDate)) {
            matches.add(match);
          }
        }
      }

      return matches;
    } catch (e) {
      throw ServerException(message: 'فشل جلب المباريات السابقة: $e');
    }
  }

  @override
  Future<MatchModel> getMatchDetails(String matchId) async {
    try {
      final snapshot = await _databaseRef.child('matches').child(matchId).get();
      if (!snapshot.exists) {
        throw NotFoundException(message: 'المباراة غير موجودة');
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return MatchModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ServerException(message: 'فشل جلب تفاصيل المباراة: $e');
    }
  }

  @override
  Future<List<MatchModel>> searchMatches(String query) async {
    try {
      final snapshot = await _databaseRef.child('matches').get();
      if (!snapshot.exists) return [];

      final results = <MatchModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final matchData = entry.value as Map<dynamic, dynamic>;
        final match = MatchModel.fromJson(Map<String, dynamic>.from(matchData));

        if ((match.homeTeam.contains(query) ?? false) ||
            (match.awayTeam.contains(query) ?? false) ||
            (match.tournament.contains(query) ?? false)) {
          results.add(match);
        }
      }

      return results;
    } catch (e) {
      throw ServerException(message: 'فشل البحث: $e');
    }
  }

  @override
  Future<List<MatchModel>> filterByTournament(String tournament) async {
    try {
      final snapshot = await _databaseRef.child('matches').get();
      if (!snapshot.exists) return [];

      final matches = <MatchModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final matchData = entry.value as Map<dynamic, dynamic>;
        final match = MatchModel.fromJson(Map<String, dynamic>.from(matchData));

        if (match.tournament == tournament) {
          matches.add(match);
        }
      }

      return matches;
    } catch (e) {
      throw ServerException(message: 'فشل التصفية: $e');
    }
  }

  @override
  Future<List<MatchModel>> filterBySeason(String season) async {
    try {
      final snapshot = await _databaseRef.child('matches').get();
      if (!snapshot.exists) return [];

      final matches = <MatchModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final matchData = entry.value as Map<dynamic, dynamic>;
        final match = MatchModel.fromJson(Map<String, dynamic>.from(matchData));

        if (match.season == season) {
          matches.add(match);
        }
      }

      return matches;
    } catch (e) {
      throw ServerException(message: 'فشل التصفية: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getMatchStatistics(String matchId) async {
    try {
      final snapshot = await _databaseRef
          .child('match_statistics')
          .child(matchId)
          .get();

      if (!snapshot.exists) {
        return {
          'homeTeamStats': {},
          'awayTeamStats': {},
        };
      }

      return Map<String, dynamic>.from(
        snapshot.value as Map<dynamic, dynamic>,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب الإحصائيات: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getPlayerStats({
    required String matchId,
    required String playerId,
  }) async {
    try {
      final snapshot = await _databaseRef
          .child('player_stats')
          .child(matchId)
          .child(playerId)
          .get();

      if (!snapshot.exists) {
        return {};
      }

      return Map<String, dynamic>.from(
        snapshot.value as Map<dynamic, dynamic>,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب إحصائيات اللاعب: $e');
    }
  }

  @override
  Future<bool> subscribeToLiveUpdates(String matchId) async {
    try {
      await _databaseRef
          .child('live_subscriptions')
          .child(matchId)
          .set({'subscribed': true});
      return true;
    } catch (e) {
      throw ServerException(message: 'فشل الاشتراك: $e');
    }
  }

  @override
  Future<bool> unsubscribeFromLiveUpdates(String matchId) async {
    try {
      await _databaseRef
          .child('live_subscriptions')
          .child(matchId)
          .remove();
      return true;
    } catch (e) {
      throw ServerException(message: 'فشل إلغاء الاشتراك: $e');
    }
  }

  @override
  Future<List<dynamic>> getMatchTimeline(String matchId) async {
    try {
      final snapshot = await _databaseRef
          .child('match_timeline')
          .child(matchId)
          .get();

      if (!snapshot.exists) return [];

      final timeline = <dynamic>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        timeline.add(entry.value);
      }

      return timeline;
    } catch (e) {
      throw ServerException(message: 'فشل جلب الجدول الزمني: $e');
    }
  }

  @override
  Future<List<dynamic>> getTeamLineup({
    required String matchId,
    required String teamId,
  }) async {
    try {
      final snapshot = await _databaseRef
          .child('team_lineups')
          .child(matchId)
          .child(teamId)
          .get();

      if (!snapshot.exists) return [];

      final lineup = <dynamic>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        lineup.add(entry.value);
      }

      return lineup;
    } catch (e) {
      throw ServerException(message: 'فشل جلب التشكيلة: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getMatchComparisons(String matchId) async {
    try {
      final snapshot = await _databaseRef
          .child('match_comparisons')
          .child(matchId)
          .get();

      if (!snapshot.exists) {
        return {};
      }

      return Map<String, dynamic>.from(
        snapshot.value as Map<dynamic, dynamic>,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب المقارنات: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getHeadToHead({
    required String team1Id,
    required String team2Id,
  }) async {
    try {
      final snapshot = await _databaseRef
          .child('head_to_head')
          .child('${team1Id}_$team2Id')
          .get();

      if (!snapshot.exists) {
        return {
          'team1Wins': 0,
          'team2Wins': 0,
          'draws': 0,
          'matches': [],
        };
      }

      return Map<String, dynamic>.from(
        snapshot.value as Map<dynamic, dynamic>,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب المواجهات السابقة: $e');
    }
  }
}
