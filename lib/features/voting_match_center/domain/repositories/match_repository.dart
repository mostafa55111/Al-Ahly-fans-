import 'package:gomhor_alahly_clean_new/features/voting_match_center/data/models/match_model.dart';

abstract class MatchRepository {
  Future<List<MatchModel>> getMatchSchedule();
  Future<MatchModel> getMatchDetails(String matchId);
  Future<void> submitEagleOfTheMatchVote(String matchId, String playerId, String userId);
  Future<void> submitPlayerRating(String matchId, String playerId, String userId, int rating);
  Future<void> createMatch(MatchModel match);
  Future<void> updateMatch(MatchModel match);
  Future<void> deleteMatch(String matchId);
}
