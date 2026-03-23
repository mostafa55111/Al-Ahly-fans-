import 'package:equatable/equatable.dart';

/// الأحداث الأساسية للـ Follow Bloc
abstract class FollowEvent extends Equatable {
  const FollowEvent();

  @override
  List<Object?> get props => [];
}

/// حدث متابعة مستخدم
class FollowUserEvent extends FollowEvent {
  /// معرف المستخدم المراد متابعته
  final String userId;

  const FollowUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حدث إلغاء متابعة مستخدم
class UnfollowUserEvent extends FollowEvent {
  /// معرف المستخدم المراد إلغاء متابعته
  final String userId;

  const UnfollowUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حدث تحميل المتابعين
class LoadFollowersEvent extends FollowEvent {
  /// معرف المستخدم
  final String userId;
  
  /// رقم الصفحة
  final int page;

  const LoadFollowersEvent({
    required this.userId,
    this.page = 1,
  });

  @override
  List<Object?> get props => [userId, page];
}

/// حدث تحميل المتابَعين
class LoadFollowingEvent extends FollowEvent {
  /// معرف المستخدم
  final String userId;
  
  /// رقم الصفحة
  final int page;

  const LoadFollowingEvent({
    required this.userId,
    this.page = 1,
  });

  @override
  List<Object?> get props => [userId, page];
}

/// حدث تحميل بيانات المستخدم
class LoadUserProfileEvent extends FollowEvent {
  /// معرف المستخدم
  final String userId;

  const LoadUserProfileEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حدث البحث عن مستخدمين
class SearchUsersEvent extends FollowEvent {
  /// كلمات البحث
  final String query;
  
  /// رقم الصفحة
  final int page;

  const SearchUsersEvent({
    required this.query,
    this.page = 1,
  });

  @override
  List<Object?> get props => [query, page];
}

/// حدث تحميل اقتراحات المتابعة
class LoadFollowSuggestionsEvent extends FollowEvent {
  /// عدد الاقتراحات
  final int limit;

  const LoadFollowSuggestionsEvent({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

/// حدث حظر مستخدم
class BlockUserEvent extends FollowEvent {
  /// معرف المستخدم المراد حظره
  final String userId;

  const BlockUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حدث إلغاء حظر مستخدم
class UnblockUserEvent extends FollowEvent {
  /// معرف المستخدم المراد إلغاء حظره
  final String userId;

  const UnblockUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حدث كتم صوت مستخدم
class MuteUserEvent extends FollowEvent {
  /// معرف المستخدم المراد كتم صوته
  final String userId;

  const MuteUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حدث إلغاء كتم صوت مستخدم
class UnmuteUserEvent extends FollowEvent {
  /// معرف المستخدم المراد إلغاء كتم صوته
  final String userId;

  const UnmuteUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حدث إضافة مستخدم للمفضلة
class AddToFavoritesEvent extends FollowEvent {
  /// معرف المستخدم
  final String userId;

  const AddToFavoritesEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حدث إزالة مستخدم من المفضلة
class RemoveFromFavoritesEvent extends FollowEvent {
  /// معرف المستخدم
  final String userId;

  const RemoveFromFavoritesEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حدث تحميل قائمة المفضلة
class LoadFavoritesEvent extends FollowEvent {
  /// رقم الصفحة
  final int page;

  const LoadFavoritesEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}
