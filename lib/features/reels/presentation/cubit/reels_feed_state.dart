part of 'reels_feed_cubit.dart';

enum ReelsFeedStatus { initial, loading, loaded, empty, error }

/// نوع الفيد المعروض للمستخدم
enum FeedType { forYou, following }

/// مراحل عملية رفع الريل
enum UploadPhase { uploadingVideo, savingToDatabase, success, failed }

/// بيانات فيد واحد — كل فيد (For You / Following) يحتفظ بقائمته وحالته المستقلة.
/// ده بيخلي الـ switching بين التابين instant بدون إعادة تحميل.
class FeedData extends Equatable {
  final ReelsFeedStatus status;
  final List<VideoModel> reels;
  final String? errorMessage;
  final bool isLoadingMore;

  /// true عند وصولنا لآخر ريل متاح (لمنع تكرار الطلب)
  final bool hasReachedEnd;

  const FeedData({
    this.status = ReelsFeedStatus.initial,
    this.reels = const [],
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
  });

  bool get isEmpty => reels.isEmpty;
  bool get isLoaded => status == ReelsFeedStatus.loaded;
  bool get isLoading => status == ReelsFeedStatus.loading;

  FeedData copyWith({
    ReelsFeedStatus? status,
    List<VideoModel>? reels,
    Object? errorMessage = _unset,
    bool? isLoadingMore,
    bool? hasReachedEnd,
  }) {
    return FeedData(
      status: status ?? this.status,
      reels: reels ?? this.reels,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    );
  }

  @override
  List<Object?> get props =>
      [status, reels, errorMessage, isLoadingMore, hasReachedEnd];
}

const _unset = Object();

class ReelsFeedState extends Equatable {
  /// الفيد المعروض حالياً للمستخدم
  final FeedType currentFeed;

  /// فيد "For You" — ترتيب ذكي مبني على score + شخصنة
  final FeedData forYou;

  /// فيد "Following" — ريلز من الأشخاص اللي المستخدم بيتابعهم فقط
  final FeedData following;

  const ReelsFeedState({
    this.currentFeed = FeedType.forYou,
    this.forYou = const FeedData(),
    this.following = const FeedData(),
  });

  /// الفيد النشط حالياً (يعتمد على [currentFeed])
  FeedData get activeFeed =>
      currentFeed == FeedType.forYou ? forYou : following;

  // ═══════════════════════════════════════════════════════════════════
  // Backward-compat getters — تحافظ على واجهة الـ state القديمة
  // ═══════════════════════════════════════════════════════════════════
  ReelsFeedStatus get status => activeFeed.status;
  List<VideoModel> get reels => activeFeed.reels;
  String? get errorMessage => activeFeed.errorMessage;
  bool get isLoadingMore => activeFeed.isLoadingMore;
  bool get hasReachedEnd => activeFeed.hasReachedEnd;

  ReelsFeedState copyWith({
    FeedType? currentFeed,
    FeedData? forYou,
    FeedData? following,
  }) {
    return ReelsFeedState(
      currentFeed: currentFeed ?? this.currentFeed,
      forYou: forYou ?? this.forYou,
      following: following ?? this.following,
    );
  }

  @override
  List<Object?> get props => [currentFeed, forYou, following];
}
