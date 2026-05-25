import 'dart:math';

/// خوارزمية ترتيب الريلز (أسلوب TikTok) — مشتركة بين الـ Cubit ومزامنة Firestore.
/// المعادلة: (likes×2) + (comments×3) + (views×1) + (watch_count×3) مع انحلال زمني بسيط.
class ReelsAlgorithm {
  ReelsAlgorithm._();

  /// حساب score مع انحلال زمني هادئ حسب عمر المنشور (بالأيام).
  static double computeRankingScore({
    required int likes,
    required int comments,
    required int views,
    int watchCount = 0,
    required DateTime uploadedAt,
  }) {
    final engagement =
        (likes * 2.0) + (comments * 3.0) + (views * 1.0) + (watchCount * 3.0);
    final ageDays = DateTime.now().difference(uploadedAt).inMilliseconds /
        Duration.millisecondsPerDay;
    final decay = exp(-ageDays / 40.0);
    return engagement * decay;
  }

  /// إجمالي التفاعل لمستند Firestore — يُحدَّث مع كل Like/Comment/مزامنة مشاهدات.
  static int computeEngagementCount({
    required int likes,
    required int comments,
    required int views,
    int watchCount = 0,
  }) =>
      likes + comments + views + watchCount;

  /// خلط خفيف بعد الجلب — يُثبت أول [preserveTrendingTop] عناصر (الترند الحقيقي) ويخلط الباقي فقط.
  static void lightShuffle<T>(
    List<T> list,
    Random random, {
    int preserveTrendingTop = 3,
  }) {
    final start = min(preserveTrendingTop, list.length);
    for (var i = start; i < list.length - 1; i++) {
      if (random.nextDouble() < 0.22) {
        final span = min(4, list.length - i - 1);
        if (span <= 0) continue;
        final j = i + 1 + random.nextInt(span);
        final tmp = list[i];
        list[i] = list[j];
        list[j] = tmp;
      }
    }
  }
}
