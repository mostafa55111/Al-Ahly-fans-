/// مسارات Realtime Database — شاشة الجمهور / نسر المباراة
///
/// - [bestPlayerRoot]: كروت اللاعبين المصمّمة (FIFA-style cards)
/// - [eagleNesrRoot]: تصويت «نسر المباراة» + المجمّعات + شاشة الاحتفال
class CrowdRtdbPaths {
  /// مسار كروت اللاعبين المصمَّمة في Realtime Database.
  ///
  /// كل لاعب يُخزَّن تحت مفتاح فريد (مثل `player1`, `player12`...) ويتضمّن:
  /// - `name`: اسم اللاعب
  /// - `cardUrl`: رابط الكارت المصمَّم (imgbb / Cloudinary…)
  /// - `votes`: عدد الأصوات التراكمي (يُديره الأدمن/التصويت)
  static const String bestPlayerRoot = 'best_player';

  /// alias قديم للحفاظ على التوافق — يُفضَّل استخدام [bestPlayerRoot].
  @Deprecated('Use bestPlayerRoot instead')
  static const String pastPlayerRoot = bestPlayerRoot;

  static const String eagleNesrRoot = 'eagle_nesr';

  /// بيانات الجلسة الحالية (يضبطها الأدمن من الـ console لاحقاً)
  static const String sessionCurrent = '$eagleNesrRoot/session_current';
  static String sessionVotes(String sessionId) => '$eagleNesrRoot/votes/$sessionId';
  static const String aggregatesRoot = '$eagleNesrRoot/aggregates';
  static String monthAggregate(String yyyymm) => '$aggregatesRoot/month/$yyyymm';
  static String seasonAggregate(String seasonId) => '$aggregatesRoot/season/$seasonId';

  /// فائز واحد للعرض الاحتفالي (لأول مرة لكل مستخدم)
  static const String activeCelebration = '$eagleNesrRoot/active_celebration';

  static String userFormationPath(String uid) => 'users/$uid/crowd/formation';
  static String userFormationModePath(String uid) => 'users/$uid/crowd/formation_mode';
}
