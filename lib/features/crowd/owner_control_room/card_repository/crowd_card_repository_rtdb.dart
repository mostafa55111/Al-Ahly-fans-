import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/card_repository/crowd_card_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/card_repository/crowd_card_repository_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/models/owner_card_record.dart';

class CrowdCardRepositoryRtdb implements CrowdCardRepository {
  CrowdCardRepositoryRtdb(this._db);

  final FirebaseDatabase _db;

  List<OwnerCardRecord> _parse(DataSnapshot snap, String appId) {
    if (!snap.exists || snap.value is! Map) return const [];
    final m = Map<dynamic, dynamic>.from(snap.value! as Map);
    final list = <OwnerCardRecord>[];
    m.forEach((k, v) {
      if (k.toString().isEmpty || v is! Map) return;
      final card = OwnerCardRecord.fromMap(
        k.toString(),
        Map<dynamic, dynamic>.from(v),
      );
      list.add(
        card.appId.isEmpty
            ? OwnerCardRecord(
                id: card.id,
                playerName: card.playerName,
                playerNumber: card.playerNumber,
                position: card.position,
                imageUrl: card.imageUrl,
                thumbnailUrl: card.thumbnailUrl,
                dominantColor: card.dominantColor,
                createdAtServer: card.createdAtServer,
                ownerUid: card.ownerUid,
                appId: appId,
                archivedAt: card.archivedAt,
              )
            : card,
      );
    });
    list.sort((a, b) => b.createdAtServer.compareTo(a.createdAtServer));
    return list;
  }

  Future<List<OwnerCardRecord>> _readLegacy(String appId) async {
    final snap = await _db.ref(StadiumCardRegistryPaths.root(appId)).get();
    if (!snap.exists || snap.value is! Map) return const [];
    final m = Map<dynamic, dynamic>.from(snap.value! as Map);
    final list = <OwnerCardRecord>[];
    m.forEach((k, v) {
      if (k.toString().isEmpty || v is! Map) return;
      list.add(
        OwnerCardRecord.fromRegistry(
          StadiumCardRegistryEntry.fromMap(
            k.toString(),
            Map<dynamic, dynamic>.from(v),
          ),
          appId,
        ),
      );
    });
    list.sort((a, b) => b.createdAtServer.compareTo(a.createdAtServer));
    return list;
  }

  @override
  Stream<List<OwnerCardRecord>> watchCards(String appId) {
    final tag = appId.trim().toLowerCase();
    return _db.ref(CrowdCardRepositoryPaths.cardsRoot(tag)).onValue.asyncMap(
      (event) async {
        final primary = _parse(event.snapshot, tag);
        if (primary.isNotEmpty) return primary;
        return _readLegacy(tag);
      },
    );
  }

  @override
  Future<void> upsertCard({
    required String appId,
    required OwnerCardRecord card,
  }) async {
    final tag = appId.trim().toLowerCase();
    await _db
        .ref(CrowdCardRepositoryPaths.card(tag, card.id))
        .set(card.toWriteMap());
  }

  @override
  Future<void> removeCard(String appId, String cardId) async {
    final tag = appId.trim().toLowerCase();
    await _db.ref(CrowdCardRepositoryPaths.card(tag, cardId)).remove();
  }

  @override
  Future<void> archiveCard(String appId, OwnerCardRecord card) async {
    await upsertCard(
      appId: appId,
      card: card.copyWith(
        archivedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
