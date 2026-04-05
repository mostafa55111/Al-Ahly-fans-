import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/data/models/match_model.dart';

abstract class MatchRemoteDataSource {
  Future<List<MatchModel>> getMatchSchedule();
  Future<MatchModel> getMatchDetails(String matchId);
  Future<void> submitEagleOfTheMatchVote(
      String matchId, String playerId, String userId);
  Future<void> submitPlayerRating(
      String matchId, String playerId, String userId, int rating);
  Future<void> createMatch(MatchModel match);
  Future<void> updateMatch(MatchModel match);
  Future<void> deleteMatch(String matchId);
}

class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final FirebaseDatabase _database;

  MatchRemoteDataSourceImpl(this._database);

  @override
  Future<List<MatchModel>> getMatchSchedule() async {
    final snapshot = await _database.ref().child('matches').get();
    if (snapshot.exists) {
      final List<MatchModel> matches = [];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final m = value as Map<dynamic, dynamic>;
        final tid = m['teamId'] ?? m['homeTeamId'] ?? m['awayTeamId'];
        final isAhlyId = tid != null && tid.toString() == '1029';
        final ht = m['homeTeam']?.toString().toLowerCase() ?? '';
        final at = m['awayTeam']?.toString().toLowerCase() ?? '';
        final isAhlyName = ht.contains('ahly') ||
            at.contains('ahly') ||
            m['homeTeam'] == 'الأهلي' ||
            m['awayTeam'] == 'الأهلي';
        if (isAhlyId || isAhlyName) {
          matches.add(MatchModel.fromMap(m, key.toString()));
        }
      });
      return matches;
    } else {
      return [];
    }
  }

  @override
  Future<MatchModel> getMatchDetails(String matchId) async {
    final snapshot = await _database.ref().child('matches/$matchId').get();
    if (snapshot.exists) {
      return MatchModel.fromSnapshot(snapshot);
    } else {
      throw Exception('Match not found');
    }
  }

  @override
  Future<void> submitEagleOfTheMatchVote(
      String matchId, String playerId, String userId) async {
    await _database
        .ref()
        .child('matches/$matchId/eagleOfTheMatchVotes/$userId')
        .set(playerId);
  }

  @override
  Future<void> submitPlayerRating(
      String matchId, String playerId, String userId, int rating) async {
    await _database
        .ref()
        .child('matches/$matchId/playerRatings/$playerId/$userId')
        .set(rating);
  }

  @override
  Future<void> createMatch(MatchModel match) async {
    final newMatchRef = _database.ref().child('matches').push();
    await newMatchRef.set(match.toJson());
  }

  @override
  Future<void> updateMatch(MatchModel match) async {
    await _database.ref().child('matches/${match.id}').update(match.toJson());
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    await _database.ref().child('matches/$matchId').remove();
  }
}
