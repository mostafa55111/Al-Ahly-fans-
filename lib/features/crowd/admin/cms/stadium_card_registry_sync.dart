import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:uuid/uuid.dart';

/// يحفظ كرت اللاعب في المكتبة الخفيفة بعد الرفع (بدون تكرار إن وُجد نفس الرابط).
Future<void> syncMatchPitchPlayerToCardRegistry({
  required StadiumCardRegistryRepository registry,
  required String clubTag,
  required MatchPitchPlayer player,
  List<StadiumCardRegistryEntry> existing = const [],
}) async {
  final url = player.cardImageUrl.trim();
  if (url.isEmpty) return;
  for (final e in existing) {
    if (e.imageUrl.trim() == url) return;
  }
  final id = const Uuid().v4();
  await registry.upsertCard(
    clubTag: clubTag,
    entry: StadiumCardRegistryEntry(
      id: id,
      playerName: player.name.trim().isEmpty ? 'لاعب' : player.name.trim(),
      imageUrl: url,
      thumbUrl: player.cardThumbnailUrl.trim(),
      rarity: player.cardRarity.trim(),
      club: clubTag,
      tags: [
        if (player.position.trim().isNotEmpty) player.position.trim().toUpperCase(),
      ],
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  );
}
