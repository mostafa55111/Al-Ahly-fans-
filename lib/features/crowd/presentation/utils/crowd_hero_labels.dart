import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';

/// عناوين «نسر» (الأهلي) مقابل «فارس» (الزمالك) لنفس مسارات RTDB.
class CrowdHeroLabels {
  CrowdHeroLabels._();

  static bool get _zamalek => FanAppIdentity.registryAppId == 'zamalek';

  static String get matchTitle => _zamalek ? 'فارس المباراة' : 'نسر المباراة';
  static String get monthTitle => _zamalek ? 'فارس الشهر' : 'نسر الشهر';
  static String get seasonTitle => _zamalek ? 'فارس الموسم' : 'نسر الموسم';

  /// زر إغلاق احتفال الفائز.
  static String get celebrationCheerCta =>
      _zamalek ? 'يلا الزمالك' : 'يلا الأهلي';

  /// تبويب «عرض النسور» / «عرض الفرسان» بجانب التصويت في شاشة الجمهور.
  static String get crowdShowcaseTab => _zamalek ? 'عرض الفرسان' : 'عرض النسور';
}
