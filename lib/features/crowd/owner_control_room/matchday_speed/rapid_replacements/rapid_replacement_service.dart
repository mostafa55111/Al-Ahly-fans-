import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// استبدال لاعب سريع — يحافظ على الموقع والتشكيلة.
class RapidReplacementService {
  Future<void> replaceStarter({
    required MatchVotesAdminCubit cubit,
    required MatchPitchPlayer player,
    required StadiumCardRegistryEntry replacement,
  }) {
    return cubit.replacePitchPlayerWithRegistry(
      playerId: player.id,
      entry: replacement,
    );
  }

  Future<void> replaceBenchPlayer({
    required MatchVotesAdminCubit cubit,
    required MatchPitchPlayer player,
    required StadiumCardRegistryEntry replacement,
  }) {
    return cubit.replacePitchPlayerWithRegistry(
      playerId: player.id,
      entry: replacement,
    );
  }
}
