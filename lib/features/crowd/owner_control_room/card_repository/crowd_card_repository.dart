import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/models/owner_card_record.dart';

abstract class CrowdCardRepository {
  Stream<List<OwnerCardRecord>> watchCards(String appId);

  Future<void> upsertCard({
    required String appId,
    required OwnerCardRecord card,
  });

  Future<void> removeCard(String appId, String cardId);

  Future<void> archiveCard(String appId, OwnerCardRecord card);
}
