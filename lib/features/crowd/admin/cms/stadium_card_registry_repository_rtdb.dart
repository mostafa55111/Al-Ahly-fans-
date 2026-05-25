import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_repository.dart';

class StadiumCardRegistryRepositoryRtdb implements StadiumCardRegistryRepository {
  StadiumCardRegistryRepositoryRtdb(this._db);

  final FirebaseDatabase _db;

  List<StadiumCardRegistryEntry> _parse(DataSnapshot snap) {
    if (!snap.exists || snap.value is! Map) return const [];
    final m = Map<dynamic, dynamic>.from(snap.value! as Map);
    final list = <StadiumCardRegistryEntry>[];
    m.forEach((k, v) {
      if (k.toString().isEmpty || v is! Map) return;
      list.add(
        StadiumCardRegistryEntry.fromMap(
          k.toString(),
          Map<dynamic, dynamic>.from(v),
        ),
      );
    });
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<StadiumCardRegistryEntry>> watchCards(String clubTag) {
    return _db
        .ref(StadiumCardRegistryPaths.root(clubTag))
        .onValue
        .map((e) => _parse(e.snapshot));
  }

  @override
  Future<void> upsertCard({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  }) async {
    await _db
        .ref(StadiumCardRegistryPaths.card(clubTag, entry.id))
        .set(entry.toWriteMap());
  }

  @override
  Future<void> removeCard(String clubTag, String cardId) async {
    await _db.ref(StadiumCardRegistryPaths.card(clubTag, cardId)).remove();
  }

  @override
  Future<void> toggleFavorite({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  }) async {
    await upsertCard(
      clubTag: clubTag,
      entry: entry.copyWith(favorite: !entry.favorite),
    );
  }

  @override
  Future<void> recordCardUse({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await upsertCard(
      clubTag: clubTag,
      entry: entry.copyWith(
        lastUsedAt: now,
        useCount: entry.useCount + 1,
      ),
    );
  }
}
