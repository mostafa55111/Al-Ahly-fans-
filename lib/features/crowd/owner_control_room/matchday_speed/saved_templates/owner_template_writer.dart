import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_lineup_slot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/launch_validation/launch_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template_repository.dart';
import 'package:uuid/uuid.dart';

/// حفظ تشكيلة حالية كقالب مالك.
class OwnerTemplateWriter {
  OwnerTemplateWriter({
    required OwnerMatchTemplateRepository repository,
    Uuid? uuid,
  })  : _repository = repository,
        _uuid = uuid ?? const Uuid();

  final OwnerMatchTemplateRepository _repository;
  final Uuid _uuid;

  Future<OwnerMatchTemplate> saveFromState({
    required MatchVotesAdminState state,
    required String appId,
    required String name,
  }) async {
    final players = state.bundle.players;
    final starters = players
        .where((p) => p.y < LaunchValidator.starterPitchYThreshold)
        .map(_slotFromPlayer)
        .toList();
    final bench = players
        .where((p) => p.y >= LaunchValidator.starterPitchYThreshold)
        .map(_slotFromPlayer)
        .toList();
    final now = DateTime.now().millisecondsSinceEpoch;
    final template = OwnerMatchTemplate(
      id: _uuid.v4(),
      name: name,
      formation: state.match?.formation ?? '4-3-3',
      starters: starters,
      bench: bench,
      createdAt: now,
      lastUsedAt: now,
      appId: appId,
    );
    await _repository.upsertTemplate(appId: appId, template: template);
    return template;
  }

  StadiumLineupSlot _slotFromPlayer(MatchPitchPlayer p) {
    final img = p.cardImageUrl.trim().isNotEmpty ? p.cardImageUrl : p.imageUrl;
    return StadiumLineupSlot(
      registryCardId: p.id,
      playerName: p.name,
      imageUrl: img,
      thumbUrl: p.cardThumbnailUrl,
      position: p.position,
      rarity: p.cardRarity,
    );
  }
}
