import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/leaderboard/domain/entities/leaderboard_entity.dart';

/// واجهة Repository للـ Leaderboard
abstract class LeaderboardRepository {
  /// الحصول على لوحة المتصدرين العامة
  /// 
  /// المعاملات:
  /// - [page]: رقم الصفحة
  /// - [pageSize]: عدد النتائج في الصفحة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المتصدرين
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<LeaderboardEntity>>> getOverallLeaderboard({
    required int page,
    required int pageSize,
  });

  /// الحصول على لوحة المتصدرين الأسبوعية
  /// 
  /// المعاملات:
  /// - [page]: رقم الصفحة
  /// - [pageSize]: عدد النتائج في الصفحة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المتصدرين
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<LeaderboardEntity>>> getWeeklyLeaderboard({
    required int page,
    required int pageSize,
  });

  /// الحصول على لوحة المتصدرين الشهرية
  /// 
  /// المعاملات:
  /// - [page]: رقم الصفحة
  /// - [pageSize]: عدد النتائج في الصفحة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المتصدرين
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<LeaderboardEntity>>> getMonthlyLeaderboard({
    required int page,
    required int pageSize,
  });

  /// الحصول على ترتيب الأصدقاء
  /// 
  /// المعاملات:
  /// - [page]: رقم الصفحة
  /// - [pageSize]: عدد النتائج في الصفحة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة الأصدقاء مرتبة
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<LeaderboardEntity>>> getFriendsLeaderboard({
    required int page,
    required int pageSize,
  });

  /// الحصول على ترتيب المستخدم الحالي
  /// 
  /// القيمة المرجعة:
  /// - [Right]: بيانات ترتيب المستخدم
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, LeaderboardEntity>> getCurrentUserRank();

  /// الحصول على ترتيب مستخدم معين
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم
  /// 
  /// القيمة المرجعة:
  /// - [Right]: بيانات الترتيب
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, LeaderboardEntity>> getUserRank(String userId);

  /// البحث عن مستخدم في لوحة المتصدرين
  /// 
  /// المعاملات:
  /// - [query]: كلمات البحث
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المستخدمين المطابقين
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<LeaderboardEntity>>> searchInLeaderboard(
    String query,
  );

  /// الحصول على المستويات
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المستويات
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<LevelEntity>>> getLevels();

  /// الحصول على مستوى المستخدم الحالي
  /// 
  /// القيمة المرجعة:
  /// - [Right]: بيانات المستوى
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, LevelEntity>> getCurrentUserLevel();

  /// الحصول على مستوى مستخدم معين
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم
  /// 
  /// القيمة المرجعة:
  /// - [Right]: بيانات المستوى
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, LevelEntity>> getUserLevel(String userId);

  /// إضافة نقاط للمستخدم الحالي
  /// 
  /// المعاملات:
  /// - [points]: عدد النقاط المراد إضافتها
  /// - [reason]: السبب (اختياري)
  /// 
  /// القيمة المرجعة:
  /// - [Right]: عدد النقاط الجديد
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, int>> addPoints({
    required int points,
    String? reason,
  });

  /// الحصول على إحصائيات المستخدم
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم
  /// 
  /// القيمة المرجعة:
  /// - [Right]: بيانات الإحصائيات
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, Map<String, dynamic>>> getUserStatistics(
    String userId,
  );

  /// الحصول على أفضل المستخدمين هذا الأسبوع
  /// 
  /// المعاملات:
  /// - [limit]: عدد النتائج
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة أفضل المستخدمين
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<LeaderboardEntity>>> getTopUsersThisWeek({
    required int limit,
  });

  /// الحصول على أفضل المستخدمين هذا الشهر
  /// 
  /// المعاملات:
  /// - [limit]: عدد النتائج
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة أفضل المستخدمين
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<LeaderboardEntity>>> getTopUsersThisMonth({
    required int limit,
  });
}
