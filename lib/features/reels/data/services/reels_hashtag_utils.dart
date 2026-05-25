/// أدوات استخراج الهاشتاجات من نص الوصف — لـ Firestore وواجهة التصفية.
class ReelsHashtagUtils {
  ReelsHashtagUtils._();

  static final RegExp _tagPattern =
      RegExp(r'#([\u0600-\u06FFA-Za-z0-9_]+)', unicode: true);

  /// قائمة يونيك بدون رمز # وأحرف صغيرة — مناسبة لـ `array-contains` في Firestore.
  static List<String> extractTags(String caption) {
    final set = <String>{};
    for (final m in _tagPattern.allMatches(caption)) {
      final t = m.group(1)?.toLowerCase().trim();
      if (t != null && t.isNotEmpty) set.add(t);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  /// إزالة # من بداية النص إن وُجدت.
  static String normalizeTag(String raw) {
    var s = raw.trim();
    if (s.startsWith('#')) s = s.substring(1);
    return s.toLowerCase().trim();
  }
}
