import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/follow_system/domain/entities/follow_entity.dart';

/// الحالات الأساسية للـ Follow Bloc
abstract class FollowState extends Equatable {
  const FollowState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class FollowInitial extends FollowState {
  const FollowInitial();
}

/// حالة التحميل
class FollowLoading extends FollowState {
  const FollowLoading();
}

/// حالة النجاح - تم متابعة المستخدم
class UserFollowedSuccess extends FollowState {
  /// بيانات المتابعة
  final FollowEntity follow;

  const UserFollowedSuccess(this.follow);

  @override
  List<Object?> get props => [follow];
}

/// حالة النجاح - تم إلغاء متابعة المستخدم
class UserUnfollowedSuccess extends FollowState {
  /// معرف المستخدم
  final String userId;

  const UserUnfollowedSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حالة تحميل المتابعين
class FollowersLoaded extends FollowState {
  /// قائمة المتابعين
  final List<UserProfile> followers;
  
  /// رقم الصفحة الحالية
  final int currentPage;
  
  /// هل هذه آخر صفحة
  final bool isLastPage;

  const FollowersLoaded({
    required this.followers,
    required this.currentPage,
    required this.isLastPage,
  });

  @override
  List<Object?> get props => [followers, currentPage, isLastPage];
}

/// حالة تحميل المتابَعين
class FollowingLoaded extends FollowState {
  /// قائمة المتابَعين
  final List<UserProfile> following;
  
  /// رقم الصفحة الحالية
  final int currentPage;
  
  /// هل هذه آخر صفحة
  final bool isLastPage;

  const FollowingLoaded({
    required this.following,
    required this.currentPage,
    required this.isLastPage,
  });

  @override
  List<Object?> get props => [following, currentPage, isLastPage];
}

/// حالة تحميل بيانات المستخدم
class UserProfileLoaded extends FollowState {
  /// بيانات المستخدم
  final UserProfile userProfile;

  const UserProfileLoaded(this.userProfile);

  @override
  List<Object?> get props => [userProfile];
}

/// حالة نتائج البحث
class SearchResultsLoaded extends FollowState {
  /// نتائج البحث
  final List<UserProfile> results;
  
  /// الاستعلام المستخدم
  final String query;

  const SearchResultsLoaded({
    required this.results,
    required this.query,
  });

  @override
  List<Object?> get props => [results, query];
}

/// حالة تحميل اقتراحات المتابعة
class FollowSuggestionsLoaded extends FollowState {
  /// قائمة الاقتراحات
  final List<UserProfile> suggestions;

  const FollowSuggestionsLoaded(this.suggestions);

  @override
  List<Object?> get props => [suggestions];
}

/// حالة النجاح - تم حظر المستخدم
class UserBlockedSuccess extends FollowState {
  /// معرف المستخدم
  final String userId;

  const UserBlockedSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حالة النجاح - تم إلغاء حظر المستخدم
class UserUnblockedSuccess extends FollowState {
  /// معرف المستخدم
  final String userId;

  const UserUnblockedSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حالة النجاح - تم كتم صوت المستخدم
class UserMutedSuccess extends FollowState {
  /// معرف المستخدم
  final String userId;

  const UserMutedSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حالة النجاح - تم إلغاء كتم صوت المستخدم
class UserUnmutedSuccess extends FollowState {
  /// معرف المستخدم
  final String userId;

  const UserUnmutedSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حالة النجاح - تم إضافة المستخدم للمفضلة
class AddedToFavoritesSuccess extends FollowState {
  /// معرف المستخدم
  final String userId;

  const AddedToFavoritesSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حالة النجاح - تم إزالة المستخدم من المفضلة
class RemovedFromFavoritesSuccess extends FollowState {
  /// معرف المستخدم
  final String userId;

  const RemovedFromFavoritesSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// حالة تحميل قائمة المفضلة
class FavoritesLoaded extends FollowState {
  /// قائمة المفضلة
  final List<UserProfile> favorites;
  
  /// رقم الصفحة الحالية
  final int currentPage;
  
  /// هل هذه آخر صفحة
  final bool isLastPage;

  const FavoritesLoaded({
    required this.favorites,
    required this.currentPage,
    required this.isLastPage,
  });

  @override
  List<Object?> get props => [favorites, currentPage, isLastPage];
}

/// حالة الخطأ
class FollowError extends FollowState {
  /// رسالة الخطأ
  final String message;

  const FollowError(this.message);

  @override
  List<Object?> get props => [message];
}

/// حالة الفراغ
class FollowEmpty extends FollowState {
  const FollowEmpty();
}
