import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// وصف التدفق الآلي — بدون تدخل يدوي بعد النشر.
///
/// OWNER: إنشاء + نشر الجلسة.
/// SYSTEM: فتح التصويت، العدّاد، الإغلاق، finalize، إعلان الفائز.
abstract final class OwnerSessionLifecycle {
  static bool isLive(MatchActiveSession? session) {
    if (session == null || session.id.isEmpty) return false;
    return session.votingEnabled;
  }

  static bool isDraft(MatchActiveSession? session) {
    if (session == null || session.id.isEmpty) return false;
    return !session.votingEnabled && !session.awardsFinalized;
  }

  static String phaseLabel(MatchActiveSession? session) {
    if (session == null || session.id.isEmpty) return 'لا جلسة';
    if (session.awardsFinalized) return 'منتهية';
    if (session.votingEnabled) return 'مباشر';
    return 'مسودة';
  }
}
