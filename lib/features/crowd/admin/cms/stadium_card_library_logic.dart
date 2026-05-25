import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';

List<StadiumCardRegistryEntry> filterAndSortCardLibrary({
  required List<StadiumCardRegistryEntry> cards,
  required String query,
  required StadiumCardLibraryFilter filter,
  String? rarityFilter,
  String? clubFilter,
}) {
  var list = List<StadiumCardRegistryEntry>.from(cards);

  if (filter == StadiumCardLibraryFilter.archived) {
    list = list.where((e) => e.isArchived).toList();
  } else {
    list = list.where((e) => !e.isArchived).toList();
  }

  final q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list
        .where(
          (e) =>
              e.playerName.toLowerCase().contains(q) ||
              e.rarity.toLowerCase().contains(q) ||
              e.club.toLowerCase().contains(q) ||
              e.tags.any((t) => t.toLowerCase().contains(q)),
        )
        .toList();
  }

  if (rarityFilter != null && rarityFilter.isNotEmpty) {
    final r = rarityFilter.toLowerCase();
    list = list.where((e) => e.rarity.toLowerCase() == r).toList();
  }

  if (clubFilter != null && clubFilter.isNotEmpty) {
    final c = clubFilter.toLowerCase();
    list = list
        .where(
          (e) =>
              e.club.toLowerCase() == c ||
              e.tags.any((t) => t.toLowerCase() == c),
        )
        .toList();
  }

  switch (filter) {
    case StadiumCardLibraryFilter.favorites:
      list = list.where((e) => e.favorite).toList();
      list.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      break;
    case StadiumCardLibraryFilter.recent:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case StadiumCardLibraryFilter.lastUsed:
      list = list.where((e) => e.lastUsedAt > 0).toList();
      list.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      break;
    case StadiumCardLibraryFilter.all:
      list.sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return b.lastUsedAt.compareTo(a.lastUsedAt);
      });
      break;
    case StadiumCardLibraryFilter.archived:
      list.sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
      break;
  }

  return list;
}
