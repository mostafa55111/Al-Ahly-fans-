import 'package:gomhor_alahly_clean_new/features/crowd/data/models/active_celebration_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/eagle_session_dto.dart';

/// مستودع شاشة الجمهور (Realtime Database)
abstract class CrowdRepository {
  /// كروت اللاعبين من [past_player]
  Future<List<PastPlayerDto>> loadPastPlayers();

  /// جلسة التصويت الحالية
  Future<EagleSessionDto?> loadCurrentSession();

  /// صوت المستخدم في الجلسة (معرف اللاعب)
  Stream<String?> watchUserVote(String sessionId, String uid);

  /// تقديم/تغيير الصوت (تحديث المجمّعات بالـ increment)
  Future<void> submitVote({
    required String sessionId,
    required String yyyymm,
    required String seasonId,
    required String uid,
    required String newPlayerId,
  });

  /// الاحتفال النشط (للمرة الأولى)
  Stream<ActiveCelebrationDto?> watchActiveCelebration();

  /// تحميل/حفظ تشكيلة الملعب
  Future<Map<String, String>> loadUserFormation(String uid);
  Future<void> saveUserFormation(String uid, Map<String, String> slotToPlayerId);
  Future<String> loadFormationMode(String uid);
  Future<void> saveFormationMode(String uid, String mode);

  // ═══════════════ عمليات الأدمن ═══════════════
  // (تتطلّب أن يكون المستخدم مُسجَّلاً في `admins/{uid}` وأن تسمح القواعد).

  /// إضافة لاعب جديد (يُولَّد له id فريد).
  Future<String> adminAddPlayer({
    required String name,
    required String? cardUrl,
    String? position,
    int? number,
  });

  /// تعديل لاعب موجود (دمج حقول).
  Future<void> adminUpdatePlayer(
    String playerId,
    Map<String, Object?> updates,
  );

  /// حذف لاعب.
  Future<void> adminDeletePlayer(String playerId);

  /// بدء جلسة تصويت جديدة بـ `ServerValue.timestamp` لـ `startedAt`.
  /// تكتب أيضاً `eligible/{playerId}: true` لكل اللاعبين المؤهَّلين.
  Future<String> adminStartSession({
    required Iterable<String> eligiblePlayerIds,
    required String yyyymm,
    required String seasonId,
  });

  /// إنهاء الجلسة الحالية (حذف `session_current`).
  Future<void> adminEndSession();
}
