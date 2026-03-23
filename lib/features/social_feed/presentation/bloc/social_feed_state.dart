import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/entities/post_entity.dart';

/// الحالات الأساسية للـ Social Feed Bloc
abstract class SocialFeedState extends Equatable {
  const SocialFeedState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class SocialFeedInitial extends SocialFeedState {
  const SocialFeedInitial();
}

/// حالة التحميل
class SocialFeedLoading extends SocialFeedState {
  const SocialFeedLoading();
}

/// حالة تحميل المزيد
class SocialFeedLoadingMore extends SocialFeedState {
  /// المنشورات المحملة حالياً
  final List<PostEntity> posts;

  const SocialFeedLoadingMore(this.posts);

  @override
  List<Object?> get props => [posts];
}

/// حالة النجاح - تم تحميل المنشورات بنجاح
class SocialFeedLoaded extends SocialFeedState {
  /// قائمة المنشورات
  final List<PostEntity> posts;
  
  /// رقم الصفحة الحالية
  final int currentPage;
  
  /// هل هذه آخر صفحة
  final bool isLastPage;
  
  /// إجمالي عدد المنشورات
  final int totalCount;

  const SocialFeedLoaded({
    required this.posts,
    required this.currentPage,
    required this.isLastPage,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [posts, currentPage, isLastPage, totalCount];
}

/// حالة الخطأ
class SocialFeedError extends SocialFeedState {
  /// رسالة الخطأ
  final String message;
  
  /// المنشورات السابقة (إن وجدت)
  final List<PostEntity>? previousPosts;

  const SocialFeedError({
    required this.message,
    this.previousPosts,
  });

  @override
  List<Object?> get props => [message, previousPosts];
}

/// حالة نجاح إنشاء منشور
class PostCreatedSuccess extends SocialFeedState {
  /// المنشور المنشأ
  final PostEntity post;

  const PostCreatedSuccess(this.post);

  @override
  List<Object?> get props => [post];
}

/// حالة نجاح تحديث منشور
class PostUpdatedSuccess extends SocialFeedState {
  /// المنشور المحدث
  final PostEntity post;

  const PostUpdatedSuccess(this.post);

  @override
  List<Object?> get props => [post];
}

/// حالة نجاح حذف منشور
class PostDeletedSuccess extends SocialFeedState {
  /// معرف المنشور المحذوف
  final String postId;

  const PostDeletedSuccess(this.postId);

  @override
  List<Object?> get props => [postId];
}

/// حالة نجاح الإعجاب بمنشور
class PostLikedSuccess extends SocialFeedState {
  /// معرف المنشور
  final String postId;
  
  /// عدد الإعجابات الجديد
  final int likesCount;

  const PostLikedSuccess({
    required this.postId,
    required this.likesCount,
  });

  @override
  List<Object?> get props => [postId, likesCount];
}

/// حالة نجاح إلغاء الإعجاب بمنشور
class PostUnlikedSuccess extends SocialFeedState {
  /// معرف المنشور
  final String postId;
  
  /// عدد الإعجابات الجديد
  final int likesCount;

  const PostUnlikedSuccess({
    required this.postId,
    required this.likesCount,
  });

  @override
  List<Object?> get props => [postId, likesCount];
}

/// حالة نتائج البحث
class SearchResultsLoaded extends SocialFeedState {
  /// نتائج البحث
  final List<PostEntity> results;
  
  /// الاستعلام المستخدم
  final String query;

  const SearchResultsLoaded({
    required this.results,
    required this.query,
  });

  @override
  List<Object?> get props => [results, query];
}

/// حالة تحديث المنشور في الوقت الفعلي
class PostUpdatedRealtime extends SocialFeedState {
  /// المنشور المحدث
  final PostEntity post;
  
  /// المنشورات الحالية
  final List<PostEntity> currentPosts;

  const PostUpdatedRealtime({
    required this.post,
    required this.currentPosts,
  });

  @override
  List<Object?> get props => [post, currentPosts];
}

/// حالة الفراغ - لا توجد منشورات
class SocialFeedEmpty extends SocialFeedState {
  const SocialFeedEmpty();
}
