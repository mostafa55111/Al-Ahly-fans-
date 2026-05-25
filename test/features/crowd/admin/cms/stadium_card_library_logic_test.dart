import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_library_logic.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/card_soft_delete_service.dart';

void main() {
  final active = StadiumCardRegistryEntry(
    id: 'a',
    playerName: 'Active',
    imageUrl: 'https://x/a.webp',
  );
  final archived = StadiumCardRegistryEntry(
    id: 'b',
    playerName: 'Archived',
    imageUrl: 'https://x/b.webp',
    archivedAt: DateTime.now().millisecondsSinceEpoch,
  );

  test('all filter hides archived cards', () {
    final list = filterAndSortCardLibrary(
      cards: [active, archived],
      query: '',
      filter: StadiumCardLibraryFilter.all,
    );
    expect(list.length, 1);
    expect(list.first.id, 'a');
  });

  test('archived filter shows only archived', () {
    final list = filterAndSortCardLibrary(
      cards: [active, archived],
      query: '',
      filter: StadiumCardLibraryFilter.archived,
    );
    expect(list.length, 1);
    expect(list.first.id, 'b');
  });

  test('CardSoftDeleteService recoverable within 7 days', () {
    final soft = CardSoftDeleteService(registry: _FakeRegistry());
    final entry = StadiumCardRegistryEntry(
      id: 'x',
      playerName: 'x',
      imageUrl: 'u',
      archivedAt: DateTime.now().millisecondsSinceEpoch,
    );
    expect(soft.isRecoverable(entry), isTrue);
  });
}

class _FakeRegistry implements StadiumCardRegistryRepository {
  @override
  Stream<List<StadiumCardRegistryEntry>> watchCards(String clubTag) =>
      Stream.value(const []);

  @override
  Future<void> upsertCard({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  }) async {}

  @override
  Future<void> removeCard(String clubTag, String cardId) async {}

  @override
  Future<void> toggleFavorite({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  }) async {}

  @override
  Future<void> recordCardUse({
    required String clubTag,
    required StadiumCardRegistryEntry entry,
  }) async {}
}
