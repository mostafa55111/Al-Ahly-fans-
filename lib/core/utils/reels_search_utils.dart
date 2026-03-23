// أدوات بحث الريلز — حقل searchText يُملأ عند الرفع؛ جاهز للتوسع (Firestore / Algolia).

/// نص واحد بأحرف صغيرة للمطابقة السريعة (يُحفظ في Firebase مع كل ريل).
String buildReelSearchText({
  required String caption,
  required String userName,
  required String userId,
  required String reelId,
  required String publicId,
}) {
  final buffer = StringBuffer()
    ..write(caption)
    ..write(' ')
    ..write(userName)
    ..write(' ')
    ..write(userId)
    ..write(' ')
    ..write(reelId)
    ..write(' ')
    ..write(publicId);
  return buffer.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// نص احتياطي للريلز القديمة بدون [searchText].
String reelSearchHaystack(Map<String, dynamic> r) {
  final stored = (r['searchText'] ?? '').toString().trim();
  if (stored.isNotEmpty) return stored.toLowerCase();
  final caption = (r['caption'] ?? '').toString();
  final name = (r['userName'] ?? '').toString();
  final uid = (r['userId'] ?? '').toString();
  final id = (r['id'] ?? '').toString();
  final publicId = (r['publicId'] ?? '').toString();
  return '$caption $name $uid $id $publicId'.toLowerCase();
}

/// فلترة محلية: كل كلمات الاستعلام يجب أن تظهر في النص (AND).
List<Map<String, dynamic>> filterReelsBySearchQuery(
  List<Map<String, dynamic>> list,
  String rawQuery,
) {
  final trimmed = rawQuery.trim();
  if (trimmed.isEmpty) return list;
  final parts = trimmed
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return list;

  return list.where((r) {
    final hay = reelSearchHaystack(r);
    return parts.every(hay.contains);
  }).toList();
}
