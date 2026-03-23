import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/follow_system/domain/entities/follow_entity.dart';

/// واجهة Repository للـ Follow System
/// تحدد العمليات المتعلقة بالمتابعة
abstract class FollowRepository {
  /// متابعة مستخدم
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم المراد متابعته
  /// 
  /// القيمة المرجعة:
  /// - [Right]: بيانات المتابعة
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, FollowEntity>> followUser(String userId);

  /// إلغاء متابعة مستخدم
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم المراد إلغاء متابعته
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم إلغاء المتابعة بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> unfollowUser(String userId);

  /// الحصول على قائمة المتابعين
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم
  /// - [page]: رقم الصفحة
  /// - [pageSize]: عدد النتائج في الصفحة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المتابعين
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<UserProfile>>> getFollowers({
    required String userId,
    required int page,
    required int pageSize,
  });

  /// الحصول على قائمة المتابَعين
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم
  /// - [page]: رقم الصفحة
  /// - [pageSize]: عدد النتائج في الصفحة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المتابَعين
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<UserProfile>>> getFollowing({
    required String userId,
    required int page,
    required int pageSize,
  });

  /// الحصول على بيانات المستخدم
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم
  /// 
  /// القيمة المرجعة:
  /// - [Right]: بيانات المستخدم
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, UserProfile>> getUserProfile(String userId);

  /// البحث عن مستخدمين
  /// 
  /// المعاملات:
  /// - [query]: كلمات البحث
  /// - [page]: رقم الصفحة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المستخدمين المطابقين
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<UserProfile>>> searchUsers({
    required String query,
    required int page,
  });

  /// الحصول على اقتراحات متابعة
  /// 
  /// المعاملات:
  /// - [limit]: عدد الاقتراحات
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة الاقتراحات
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<UserProfile>>> getFollowSuggestions({
    required int limit,
  });

  /// حظر مستخدم
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم المراد حظره
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم الحظر بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> blockUser(String userId);

  /// إلغاء حظر مستخدم
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم المراد إلغاء حظره
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم إلغاء الحظر بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> unblockUser(String userId);

  /// كتم صوت مستخدم
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم المراد كتم صوته
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم كتم الصوت بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> muteUser(String userId);

  /// إلغاء كتم صوت مستخدم
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم المراد إلغاء كتم صوته
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم إلغاء كتم الصوت بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> unmuteUser(String userId);

  /// إضافة مستخدم للمفضلة
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم الإضافة بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> addToFavorites(String userId);

  /// إزالة مستخدم من المفضلة
  /// 
  /// المعاملات:
  /// - [userId]: معرف المستخدم
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم الإزالة بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> removeFromFavorites(String userId);

  /// الحصول على قائمة المفضلة
  /// 
  /// المعاملات:
  /// - [page]: رقم الصفحة
  /// - [pageSize]: عدد النتائج في الصفحة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المفضلة
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<UserProfile>>> getFavorites({
    required int page,
    required int pageSize,
  });
}
