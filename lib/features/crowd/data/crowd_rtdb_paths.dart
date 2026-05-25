import 'package:firebase_database/firebase_database.dart';

/// مسارات Realtime Database — شاشة الجمهور / نسر المباراة
///
/// - [squadRootForApp]: كروت الملعب لكل نادٍ (`ahly_squad` / `zamalek_squad`) — الأسبقية عند القراءة
/// - [fifaCardsItems]: كروت FIFA المعزولة لكل تطبيق تحت `app_cards/{ahly|zamalek}/items`
/// - [bestPlayerRoot]: مسار قديم (توافق فقط)
/// - [eagleNesrRoot]: تصويت «نسر المباراة» + المجمّعات + شاشة الاحتفال
class CrowdRtdbPaths {
  /// جذر كروت الميدان في RTDB حسب تطبيق الأهلي/الزمالك.
  static String squadRootForApp(String appSegment) {
    final s = appSegment.trim().toLowerCase();
    if (s == 'ahly') return 'ahly_squad';
    if (s == 'zamalek') return 'zamalek_squad';
    return '${s}_squad';
  }

  /// ترتيب المحاولة عند التحميل: squad → app_cards → best_player (legacy).
  static List<String> playerCardsPathsDescendingPriority(String appSegment) {
    final s = appSegment.trim();
    return [
      squadRootForApp(s),
      fifaCardsItems(s),
      bestPlayerRoot,
    ];
  }

  /// أول مسار يحتوي بيانات فعلية (للاشتراك اللحظي مثل [SquadCubit]).
  static Future<String> activePlayerCardsPath(
    FirebaseDatabase db,
    String appSegment,
  ) async {
    for (final path in playerCardsPathsDescendingPriority(appSegment)) {
      final snap = await db.ref(path).get();
      if (!snap.exists || snap.value == null) continue;
      final v = snap.value;
      if (v is Map && v.isNotEmpty) return path;
      if (v is List && v.isNotEmpty) return path;
    }
    return squadRootForApp(appSegment);
  }

  /// كروت FIFA — [appSegment] يجب أن يطابق `FanAppIdentity.registryAppId` (`zamalek` أو `ahly`).
  static String fifaCardsItems(String appSegment) =>
      'app_cards/${appSegment.trim()}/items';

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

  /// نتائج النسور المعروضة للجمهور (تلخيص آخر مباراة + يمكن توسيعها لاحقاً).
  /// يُحدَّث `match/last` عند إنهاء الأدمن لجلسة التصويت.
  static const String eaglesResultsRoot = 'eagles_results';

  static const String eaglesResultsMatchLast = '$eaglesResultsRoot/match/last';

  /// تجميعات شهريّة/موسميّة بنفس بنية [aggregatesRoot] — للقراءة أو للمزامنة لاحقاً.
  static String eaglesResultsMonth(String yyyymm) =>
      '$eaglesResultsRoot/month/$yyyymm';
  static String eaglesResultsSeason(String seasonId) =>
      '$eaglesResultsRoot/season/$seasonId';

  static String userFormationPath(String uid) => 'users/$uid/crowd/formation';
  static String userFormationModePath(String uid) => 'users/$uid/crowd/formation_mode';

  /// Remote-configurable starter slots used as initial pitch positions.
  static const String defaultFormationSlots = 'app_configs/default_slots';

  /// Admin trigger: any value change means clear current dragged layout.
  static const String layoutResetSignal = 'app_configs/layout_reset_signal';
}
