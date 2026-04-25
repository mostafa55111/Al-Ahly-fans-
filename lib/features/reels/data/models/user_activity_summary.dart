/// ملخّص نشاط مستخدم واحد على ريل واحد — يُستخدم لحساب الـ personalScore.
///
/// يُقرأ من `/user_activity/{userId}/{videoId}` في Firebase.
class UserActivitySummary {
  /// إجمالي ثواني المشاهدة لهذا المستخدم على هذا الريل
  final int watchTime;

  /// هل أعجب به
  final bool liked;

  /// هل علّق عليه
  final bool commented;

  /// هل شاركه
  final bool shared;

  const UserActivitySummary({
    this.watchTime = 0,
    this.liked = false,
    this.commented = false,
    this.shared = false,
  });

  /// حد أدنى يُعتبر تحته الريل "تم تخطّيه بسرعة" → عقوبة في الـ scoring
  static const int quickSkipThresholdSeconds = 3;

  /// المستخدم شاهد الريل سابقاً (ولو لثانية واحدة)
  bool get hasWatched => watchTime > 0;

  /// المستخدم فتح الريل ومرّ عليه سريعاً (watchTime > 0 لكن قصير)
  bool get skippedQuickly =>
      watchTime > 0 && watchTime < quickSkipThresholdSeconds;
}
