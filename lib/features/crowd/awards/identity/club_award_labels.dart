import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';

/// عناوين الجوائز حسب هوية النادي — لا نصوص ثابتة داخل الـ widgets.
class ClubAwardLabels {
  ClubAwardLabels._();

  static bool get _zamalek => FanAppIdentity.registryAppId == 'zamalek';

  static String get matchTitle => _zamalek ? 'فارس المباراة' : 'نسر المباراة';
  static String get monthTitle => _zamalek ? 'فارس الشهر' : 'نسر الشهر';
  static String get seasonTitle => _zamalek ? 'فارس الموسم' : 'نسر الموسم';

  static String get hallOfFameTab => _zamalek ? 'قاعة الفرسان' : 'قاعة النسور';

  static String get lastMatchSection => 'آخر $matchTitle';
  static String get monthSection => monthTitle;
  static String get seasonSection => seasonTitle;
  static String get timelineSection => 'آخر الفائزين';

  static String get timelineMatchAwardLabel => matchTitle;

  static String votesLabel(int n) => '$n صوت';
  static String winsLabel(int n) => '$n مرة فوز بالمباراة';

  static String get noDataYet => 'لا بيانات بعد';
  static String get celebrationCta => _zamalek ? 'يلا الزمالك' : 'يلا الأهلي';

  static String get personalLegacySection => 'إرث النادي';

  static String get topMatchWinsLabel => 'أكثر $matchTitle';
  static String get topMonthlyLabel => 'أكثر $monthTitle';
  static String get topSeasonLabel => 'أكثر $seasonTitle';

  static String get voteConfirmTitle =>
      'هل تريد اختيار هذا اللاعب ل$matchTitle؟';

  static const String voteConfirmSubtext =
      'لن تتمكن من تغيير تصويتك لاحقًا.';

  static const String voteConfirmButton = 'تأكيد';
  static const String voteCancelButton = 'إلغاء';
  static const String voteRecorded = 'تم تسجيل صوتك';

  static String get countingMatchTitle => 'جارِ احتساب $matchTitle';

  static String get votingEndedTitle => 'انتهى التصويت';

  static String get finalTotalsTitle => 'النتيجة النهائية';
}

/// Alias مطلوب في المواصفات.
typedef ClubIdentityResolver = ClubAwardLabels;
