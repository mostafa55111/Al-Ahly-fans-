import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/achievements/domain/entities/achievement_entity.dart';

/// واجهة Repository للإنجازات
abstract class AchievementRepository {
  /// الحصول على جميع الإنجازات
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة الإنجازات
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<AchievementEntity>>> getAllAchievements();

  /// الحصول على إنجازات المستخدم الحالي
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة إنجازات المستخدم
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<AchievementEntity>>> getUserAchievements();

  /// الحصول على إنجازات مستخدم معين
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة الإنجازات
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<AchievementEntity>>> getUserAchievementsById(
    String userId,
  );

  /// الحصول على إنجاز محدد
  /// 
  /// المعاملات:
  /// - [achievementId]: معرف الإنجاز
  /// 
  /// القيمة المرجعة:
  /// - [Right]: بيانات الإنجاز
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, AchievementEntity>> getAchievementById(
    String achievementId,
  );

  /// تحديث تقدم الإنجاز
  /// 
  /// المعاملات:
  /// - [achievementId]: معرف الإنجاز
  /// - [progress]: التقدم الجديد
  /// 
  /// القيمة المرجعة:
  /// - [Right]: بيانات الإنجاز المحدثة
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, AchievementEntity>> updateAchievementProgress({
    required String achievementId,
    required int progress,
  });

  /// فتح إنجاز
  /// 
  /// المعاملات:
  /// - [achievementId]: معرف الإنجاز
  /// 
  /// القيمة المرجعة:
  /// - [Right]: بيانات الإنجاز المفتوح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, AchievementEntity>> unlockAchievement(
    String achievementId,
  );

  /// تثبيت إنجاز
  /// 
  /// المعاملات:
  /// - [achievementId]: معرف الإنجاز
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم التثبيت بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> pinAchievement(String achievementId);

  /// إلغاء تثبيت إنجاز
  /// 
  /// المعاملات:
  /// - [achievementId]: معرف الإنجاز
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم إلغاء التثبيت بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> unpinAchievement(String achievementId);

  /// الحصول على الإنجازات حسب النوع
  /// 
  /// المعاملات:
  /// - [type]: نوع الإنجاز
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة الإنجازات
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<AchievementEntity>>> getAchievementsByType(
    AchievementType type,
  );

  /// الحصول على الإنجازات حسب مستوى الصعوبة
  /// 
  /// المعاملات:
  /// - [difficulty]: مستوى الصعوبة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة الإنجازات
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<AchievementEntity>>> getAchievementsByDifficulty(
    DifficultyLevel difficulty,
  );

  /// الحصول على الشارات
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة الشارات
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<BadgeEntity>>> getBadges();

  /// الحصول على شارات المستخدم
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة شارات المستخدم
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<BadgeEntity>>> getUserBadges();

  /// إضافة شارة للمستخدم
  /// 
  /// المعاملات:
  /// - [badgeId]: معرف الشارة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: بيانات الشارة
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, BadgeEntity>> addBadgeToUser(String badgeId);
}
