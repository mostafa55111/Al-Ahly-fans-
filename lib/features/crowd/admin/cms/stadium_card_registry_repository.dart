import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';

abstract class StadiumCardRegistryRepository {
  Stream<List<StadiumCardRegistryEntry>> watchCards(String clubTag);

  Future<void> upsertCard({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  });

  Future<void> removeCard(String clubTag, String cardId);

  Future<void> toggleFavorite({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  });

  Future<void> recordCardUse({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  });
}
