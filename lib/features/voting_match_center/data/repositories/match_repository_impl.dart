import 'package:gomhor_alahly_clean_new/features/voting_match_center/data/datasources/match_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/data/models/match_model.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/domain/repositories/match_repository.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource remoteDataSource;

  MatchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MatchModel>> getMatchSchedule() async {
    return await remoteDataSource.getMatchSchedule();
  }

  @override
  Future<MatchModel> getMatchDetails(String matchId) async {
    return await remoteDataSource.getMatchDetails(matchId);
  }

  @override
  Future<void> submitEagleOfTheMatchVote(
      String matchId, String playerId, String userId) async {
    await remoteDataSource.submitEagleOfTheMatchVote(matchId, playerId, userId);
  }

  @override
  Future<void> submitPlayerRating(
      String matchId, String playerId, String userId, int rating) async {
    await remoteDataSource.submitPlayerRating(
        matchId, playerId, userId, rating);
  }

  @override
  Future<void> createMatch(MatchModel match) async {
    await remoteDataSource.createMatch(match);
  }

  @override
  Future<void> updateMatch(MatchModel match) async {
    await remoteDataSource.updateMatch(match);
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    await remoteDataSource.deleteMatch(matchId);
  }
}
