import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/entities/post_entity.dart';

/// الأحداث الأساسية للـ Social Feed Bloc
abstract class SocialFeedEvent extends Equatable {
  const SocialFeedEvent();

  @override
  List<Object?> get props => [];
}

/// حدث تحميل منشورات الفيد
class LoadFeedPostsEvent extends SocialFeedEvent {
  /// رقم الصفحة
  final int page;
  
  /// هل هذا تحميل أولي أم تحميل إضافي
  final bool isRefresh;

  const LoadFeedPostsEvent({
    this.page = 1,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [page, isRefresh];
}

/// حدث تحميل المزيد من المنشورات (Pagination)
class LoadMorePostsEvent extends SocialFeedEvent {
  const LoadMorePostsEvent();
}

/// حدث إنشاء منشور جديد
class CreatePostEvent extends SocialFeedEvent {
  /// بيانات المنشور الجديد
  final PostEntity post;

  const CreatePostEvent(this.post);

  @override
  List<Object?> get props => [post];
}

/// حدث تحديث منشور
class UpdatePostEvent extends SocialFeedEvent {
  /// معرف المنشور
  final String postId;
  
  /// بيانات المنشور المحدثة
  final PostEntity post;

  const UpdatePostEvent({
    required this.postId,
    required this.post,
  });

  @override
  List<Object?> get props => [postId, post];
}

/// حدث حذف منشور
class DeletePostEvent extends SocialFeedEvent {
  /// معرف المنشور المراد حذفه
  final String postId;

  const DeletePostEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

/// حدث الإعجاب بمنشور
class LikePostEvent extends SocialFeedEvent {
  /// معرف المنشور
  final String postId;

  const LikePostEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

/// حدث إلغاء الإعجاب بمنشور
class UnlikePostEvent extends SocialFeedEvent {
  /// معرف المنشور
  final String postId;

  const UnlikePostEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

/// حدث البحث عن منشورات
class SearchPostsEvent extends SocialFeedEvent {
  /// كلمات البحث
  final String query;
  
  /// رقم الصفحة
  final int page;

  const SearchPostsEvent({
    required this.query,
    this.page = 1,
  });

  @override
  List<Object?> get props => [query, page];
}

/// حدث البحث عن منشورات بالهاشتاج
class SearchByHashtagEvent extends SocialFeedEvent {
  /// الهاشتاج المراد البحث عنه
  final String hashtag;
  
  /// رقم الصفحة
  final int page;

  const SearchByHashtagEvent({
    required this.hashtag,
    this.page = 1,
  });

  @override
  List<Object?> get props => [hashtag, page];
}

/// حدث تثبيت منشور
class PinPostEvent extends SocialFeedEvent {
  /// معرف المنشور
  final String postId;

  const PinPostEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

/// حدث إلغاء تثبيت منشور
class UnpinPostEvent extends SocialFeedEvent {
  /// معرف المنشور
  final String postId;

  const UnpinPostEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

/// حدث تحديث المنشور في الوقت الفعلي
class UpdatePostRealtimeEvent extends SocialFeedEvent {
  /// المنشور المحدث
  final PostEntity post;

  const UpdatePostRealtimeEvent(this.post);

  @override
  List<Object?> get props => [post];
}
