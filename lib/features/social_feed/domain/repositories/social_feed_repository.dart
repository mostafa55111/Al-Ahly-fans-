import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/entities/post_entity.dart';

/// واجهة Repository للـ Social Feed
/// تحدد العمليات التي يمكن إجراؤها على المنشورات
abstract class SocialFeedRepository {
  /// الحصول على منشورات الفيد (مع Pagination)
  /// 
  /// المعاملات:
  /// - [page]: رقم الصفحة
  /// - [pageSize]: عدد المنشورات في الصفحة الواحدة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المنشورات
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<PostEntity>>> getFeedPosts({
    required int page,
    required int pageSize,
  });

  /// الحصول على منشورات مستخدم معين
  Future<Either<AppException, List<PostEntity>>> getUserPosts({
    required String userId,
    required int page,
    required int pageSize,
  });

  /// إنشاء منشور جديد
  /// 
  /// المعاملات:
  /// - [post]: بيانات المنشور الجديد
  /// 
  /// القيمة المرجعة:
  /// - [Right]: المنشور المنشأ
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, PostEntity>> createPost(PostEntity post);

  /// تحديث منشور موجود
  /// 
  /// المعاملات:
  /// - [postId]: معرف المنشور
  /// - [post]: بيانات المنشور المحدثة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: المنشور المحدث
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, PostEntity>> updatePost({
    required String postId,
    required PostEntity post,
  });

  /// حذف منشور
  /// 
  /// المعاملات:
  /// - [postId]: معرف المنشور المراد حذفه
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم الحذف بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> deletePost(String postId);

  /// الإعجاب بمنشور
  /// 
  /// المعاملات:
  /// - [postId]: معرف المنشور
  /// 
  /// القيمة المرجعة:
  /// - [Right]: عدد الإعجابات الجديد
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, int>> likePost(String postId);

  /// إلغاء الإعجاب بمنشور
  /// 
  /// المعاملات:
  /// - [postId]: معرف المنشور
  /// 
  /// القيمة المرجعة:
  /// - [Right]: عدد الإعجابات الجديد
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, int>> unlikePost(String postId);

  /// البحث عن منشورات بناءً على كلمات مفتاحية
  /// 
  /// المعاملات:
  /// - [query]: كلمات البحث
  /// - [page]: رقم الصفحة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المنشورات المطابقة
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<PostEntity>>> searchPosts({
    required String query,
    required int page,
  });

  /// البحث عن منشورات بناءً على الهاشتاج
  /// 
  /// المعاملات:
  /// - [hashtag]: الهاشتاج المراد البحث عنه
  /// - [page]: رقم الصفحة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة المنشورات
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<PostEntity>>> getPostsByHashtag({
    required String hashtag,
    required int page,
  });

  /// الحصول على منشورات المتابعين فقط
  /// 
  /// المعاملات:
  /// - [page]: رقم الصفحة
  /// - [pageSize]: عدد المنشورات في الصفحة
  /// 
  /// القيمة المرجعة:
  /// - [Right]: قائمة منشورات المتابعين
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, List<PostEntity>>> getFollowingPosts({
    required int page,
    required int pageSize,
  });

  /// تثبيت منشور
  /// 
  /// المعاملات:
  /// - [postId]: معرف المنشور
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم التثبيت بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> pinPost(String postId);

  /// إلغاء تثبيت منشور
  /// 
  /// المعاملات:
  /// - [postId]: معرف المنشور
  /// 
  /// القيمة المرجعة:
  /// - [Right]: true إذا تم إلغاء التثبيت بنجاح
  /// - [Left]: الخطأ الذي حدث
  Future<Either<AppException, bool>> unpinPost(String postId);
}
