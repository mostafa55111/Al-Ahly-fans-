import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/services/fan_memory_cache_service.dart';
import 'package:gomhor_alahly_clean_new/features/notifications/data/reel_interaction_notification_service.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/datasources/reels_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/user_activity_summary.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/ignored_reels_storage.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_algorithm.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_hashtag_utils.dart';

part 'reels_feed_state.dart';

/// كيوبت الريلز - يدير قائمتين منفصلتين: "For You" و "Following"
/// ═══════════════════════════════════════════════════════════════════
/// - For You: كل الريلز، مرتّبة بـ score ذكي + شخصنة للمستخدم.
/// - Following: ريلز من الأشخاص اللي المستخدم بيتابعهم فقط، بترتيب زمني.
/// ═══════════════════════════════════════════════════════════════════
/// التبديل بين الفيدين instant (بدون إعادة تحميل) لأن كل فيد يحتفظ بقائمته.
class ReelsFeedCubit extends Cubit<ReelsFeedState> {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;
  final CloudinaryService _cloudinary;
  final ReelsRemoteDataSource _reelsRemote;

  /// ترقيم الصفحة في Firestore لفيد «لك».
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastForYouFirestoreDoc;

  /// هل مصدر قائمة «لك» الحالية هو Firestore (لـ pagination مختلفة).
  bool _forYouUsingFirestore = false;

  /// كاش لنشاط المستخدم الحالي — يُجلب مرة عند loadForYou
  /// ويُعاد استخدامه في loadMore لتجنّب إعادة التحميل.
  Map<String, UserActivitySummary> _userActivity = const {};

  /// كاش لقائمة الـ following IDs — يُجلب مرة عند loadFollowing.
  Set<String> _followingIds = const {};

  /// يمنع عدّ مشاهدة مؤهّلة أكثر من مرّة لنفس الريل أثناء تشغيل التطبيق.
  final Set<String> _qualifiedWatchRecorded = {};

  /// كاش لقائمة الريلز المحفوظة عند المستخدم الحالي — تُجلب مع loadForYou.
  Set<String> _savedIds = const {};

  final IgnoredReelsStorage _ignored;
  final FanMemoryCacheService? _fanMemory;

  /// معرّفات الريلز المخفية محلياً بخيار «غير مهتم».
  final Set<String> _ignoredReelIds = <String>{};

  /// ريل يُفتح أولاً — إشعار، رابط، أو اختيار من شبكة بروفايل.
  final String? initialReelId;

  /// لو حُدّد: قائمة الريلز مقصورة على هذا المستخدم (تجربة بروفايل كاملة).
  final String? profileOnlyUserId;

  /// بذرة من شبكة البروفايل (RTDB) لتطابق العناصر المعروضة قبل جلب Firestore.
  final List<VideoModel>? seedProfileReels;

  /// ترقيم صفحة Firestore لريلز المستخدم في وضع البروفايل فقط.
  DocumentSnapshot<Map<String, dynamic>>? _lastProfileFirestoreDoc;

  /// معرفات الريلز المحمّلة لوضع البروفايل — لتفادي التكرار مع الصفحات التالية.
  final Set<String> _profileFirestoreLoadedIds = <String>{};

  /// مشترك real-time لعقدة `/reels` — يلتقط أي ريل جديد يُرفع من أي مستخدم
  /// ويضيفه تلقائياً لفيد For You (وكذلك Following لو صاحب الريل مُتابَع).
  StreamSubscription<DatabaseEvent>? _newReelsSub;

  ReelsFeedCubit({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    CloudinaryService? cloudinary,
    ReelsRemoteDataSource? reelsRemote,
    IgnoredReelsStorage? ignoredReelsStorage,
    FanMemoryCacheService? fanMemoryCache,
    this.initialReelId,
    this.profileOnlyUserId,
    this.seedProfileReels,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _cloudinary = cloudinary ?? CloudinaryService(),
        _reelsRemote = reelsRemote ?? ReelsRemoteDataSource(),
        _ignored = ignoredReelsStorage ??
            IgnoredReelsStorage(getIt<SharedPreferences>()),
        _fanMemory = fanMemoryCache ?? getIt<FanMemoryCacheService>(),
        super(ReelsFeedState(
          isGlobalAudience: AppConfig.reelsDefaultGlobalAudience,
        )) {
    _ignoredReelIds.addAll(_ignored.readCached());
  }

  /// وضع بروفايل مقصور على مستخدم — يخفي تبويبات الفيد في الواجهة.
  bool get isProfileScopedFeed =>
      (profileOnlyUserId ?? '').trim().isNotEmpty;

  @override
  Future<void> close() {
    _newReelsSub?.cancel();
    return super.close();
  }

  /// إعادة قراءة قائمة «غير مهتم» من التخزين المحلي قبل كل تحميل رئيسي.
  void _reloadIgnoredCache() {
    _ignoredReelIds
      ..clear()
      ..addAll(_ignored.readCached());
  }

  List<VideoModel> _withoutIgnored(List<VideoModel> reels) =>
      reels.where((r) => !_ignoredReelIds.contains(r.id)).toList(growable: false);

  /// عدد الريلز التي يتم تحميلها في كل دفعة
  static const int _pageSize = 20;

  /// لـ Following: نجلب دفعة أكبر للـ filter client-side لأن ممكن ريلز
  /// كتير لمستخدمين مش بنتابعهم تقع في الدفعة.
  static const int _followingFetchMultiplier = 5;

  /// التبديل بين فيد محلي (نادي التطبيق) وعالمي (دمج الجمهورين) — يُعيد تحميل «لك» من Firestore.
  Future<void> toggleGlobalAudience() async {
    emit(state.copyWith(isGlobalAudience: !state.isGlobalAudience));
    if (state.currentFeed == FeedType.forYou) {
      await loadForYou();
    }
  }

  VideoModel? _findReel(String videoId) {
    for (final r in state.forYou.reels) {
      if (r.id == videoId) return r;
    }
    for (final r in state.following.reels) {
      if (r.id == videoId) return r;
    }
    return null;
  }

  /// للواجهات الخارجية (مثل شاشة الهاشتاج) لمزامنة الحالة بعد التفاعل.
  VideoModel? findReelById(String videoId) => _findReel(videoId);

  /// مزامنة score والعدادات مع Firestore؛ [engagementDelta] يُطبَّق بـ `increment` ذرّي أولًا.
  Future<void> _syncFirestoreRanking(
    String videoId, {
    int engagementDelta = 0,
  }) async {
    final m = _findReel(videoId);
    if (m == null) return;
    if (engagementDelta != 0) {
      await _reelsRemote.incrementEngagementCount(
        videoId,
        delta: engagementDelta,
      );
    }
    await _reelsRemote.updateRankingOnly(m);
  }

  bool _allowedAudience(VideoModel m, {required bool forFollowingFeed}) {
    if (forFollowingFeed) {
      return AppConfig.reelsFirestoreClubTag == 'ahly'
          ? m.isVisibleInAhlyFeed
          : m.isVisibleInZamalekFeed;
    }
    if (state.isGlobalAudience) return true;
    return AppConfig.reelsFirestoreClubTag == 'ahly'
        ? m.isVisibleInAhlyFeed
        : m.isVisibleInZamalekFeed;
  }

  Future<Map<String, bool>> _fetchLikeFlagsForReels(
    List<String> ids,
    String uid,
  ) async {
    final out = <String, bool>{};
    const chunk = 12;
    for (var i = 0; i < ids.length; i += chunk) {
      final part = ids.sublist(i, min(i + chunk, ids.length));
      await Future.wait(part.map((id) async {
        final snap = await _database
            .ref('${AppConfig.rtdbReelsPath}/$id/likes/$uid')
            .get();
        out[id] = snap.exists && snap.value == true;
      }));
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════════
  // MARK: Entry points (public API)
  // ══════════════════════════════════════════════════════════════════

  /// Backward-compat: يحمّل الفيد الحالي (افتراضياً For You).
  Future<void> loadReels() => switchFeed(state.currentFeed, forceReload: true);

  /// تبديل بين الفيدين — بدون إعادة تحميل لو في بيانات مسبقاً.
  /// ═══════════════════════════════════════════════════════════════
  /// - لو الفيد الجديد فاضي → يبدأ التحميل تلقائياً (lazy load).
  /// - لو في بيانات → يبدّل instant بدون أي IO.
  /// - [forceReload]: يتجاهل الكاش ويعيد التحميل (pull-to-refresh).
  Future<void> switchFeed(FeedType type, {bool forceReload = false}) async {
    if (state.currentFeed != type) {
      emit(state.copyWith(currentFeed: type));
      debugPrint('[Feed] switched to $type');
    }
    final target = type == FeedType.forYou ? state.forYou : state.following;
    final needsLoad = forceReload || target.reels.isEmpty;
    if (!needsLoad) return;

    if (type == FeedType.forYou) {
      await loadForYou();
    } else {
      await loadFollowing();
    }
  }

  /// تحميل أكثر للفيد النشط حالياً — يُستدعى عند الاقتراب من آخر القائمة.
  Future<void> loadMoreReels() async {
    if (state.currentFeed == FeedType.forYou) {
      await _loadMoreForYou();
    } else {
      await _loadMoreFollowing();
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // MARK: For You feed
  // ══════════════════════════════════════════════════════════════════

  /// تحميل فيد "For You" — يدعم الدخول المباشر (إشعار / بروفايل) أو الوضع الكلاسيكي.
  Future<void> loadForYou() async {
    if (isProfileScopedFeed) {
      await _loadForYouProfileScoped();
      return;
    }
    final pin = initialReelId?.trim();
    if (pin != null && pin.isNotEmpty) {
      await _loadForYouPinnedThenAlgorithm(pin);
      return;
    }
    await _loadForYouClassic();
  }

  /// تحميل فيد "For You" (الصفحة الأولى) — الخوارزمية الافتراضية بدون تثبيت ريل.
  Future<void> _loadForYouClassic() async {
    _emitForYou(state.forYou.copyWith(
      status: ReelsFeedStatus.loading,
      hasReachedEnd: false,
    ));
    _lastForYouFirestoreDoc = null;
    _forYouUsingFirestore = false;

    try {
      _reloadIgnoredCache();
      final uid = _auth.currentUser?.uid;

      List<VideoModel>? firestoreVideos;
      try {
        final docs = await _reelsRemote.fetchTopReels(
          isGlobal: state.isGlobalAudience,
          limit: 50,
          startAfter: null,
        );
        if (docs.isNotEmpty) {
          final ids = docs.map((d) => d.id).toList(growable: false);
          final liked = uid != null
              ? await _fetchLikeFlagsForReels(ids, uid)
              : const <String, bool>{};

          if (uid != null) {
            final results = await Future.wait<Object?>([
              _fetchUserActivity(uid),
              _fetchSavedVideoIds(uid),
            ]);
            _userActivity = results[0] as Map<String, UserActivitySummary>;
            _savedIds = results[1] as Set<String>;
          } else {
            _userActivity = const {};
            _savedIds = {};
          }

          final parsed = <VideoModel>[];
          for (final d in docs) {
            final data = Map<String, dynamic>.from(d.data());
            var vm = VideoModel.fromJson(data, d.id).copyWith(
              isSavedByCurrentUser: _savedIds.contains(d.id),
              isLikedByCurrentUser: liked[d.id] ?? false,
            );
            if (vm.appSource.isEmpty) {
              vm = vm.copyWith(
                appSource: AppConfig.reelsFirestoreClubTag,
                engagementCount: ReelsAlgorithm.computeEngagementCount(
                  likes: vm.likesCount,
                  comments: vm.commentsCount,
                  views: vm.viewsCount,
                  watchCount: vm.watchCount,
                ),
              );
            }
            if (vm.isPrivate) continue;
            if (!_allowedAudience(vm, forFollowingFeed: false)) continue;
            if (vm.videoUrl.isEmpty) continue;
            parsed.add(vm);
          }

          if (parsed.isNotEmpty) {
            _rankSortPersonalized(parsed);
            ReelsAlgorithm.lightShuffle(parsed, Random());
            _forYouUsingFirestore = true;
            _lastForYouFirestoreDoc = docs.last;
            firestoreVideos = parsed;
          }
        }
      } catch (e) {
        debugPrint('ReelsFeedCubit: Firestore ForYou failed ($e) → RTDB');
      }

      if (firestoreVideos != null && firestoreVideos.isNotEmpty) {
        _emitForYou(state.forYou.copyWith(
          status: ReelsFeedStatus.loaded,
          reels: firestoreVideos,
          hasReachedEnd: firestoreVideos.length < 50,
          errorMessage: null,
        ));
        _startNewReelsListener();
        return;
      }

      DataSnapshot reelsSnapshot;
      try {
        final results = await Future.wait<Object?>([
          _database
              .ref(AppConfig.rtdbReelsPath)
              .orderByChild('timestamp')
              .limitToLast(_pageSize)
              .get()
              .timeout(const Duration(seconds: 15)),
          if (uid != null)
            _fetchUserActivity(uid)
          else
            Future.value(const <String, UserActivitySummary>{}),
          if (uid != null)
            _fetchSavedVideoIds(uid)
          else
            Future.value(const <String>{}),
        ]);
        reelsSnapshot = results[0] as DataSnapshot;
        _userActivity = results[1] as Map<String, UserActivitySummary>;
        _savedIds = results[2] as Set<String>;
      } catch (primaryErr) {
        debugPrint(
            'ReelsFeedCubit: orderByChild failed ($primaryErr) → fallback');
        reelsSnapshot = await _loadReelsFallback();
        if (uid != null) {
          _userActivity = await _fetchUserActivity(uid);
          _savedIds = await _fetchSavedVideoIds(uid);
        }
      }

      if (!reelsSnapshot.exists || reelsSnapshot.value == null) {
        _emitForYou(state.forYou.copyWith(
          status: ReelsFeedStatus.loaded,
          reels: const [],
          hasReachedEnd: true,
          errorMessage: 'لا توجد ريلز حالياً — كن أول من ينشر!',
        ));
        _startNewReelsListener();
        return;
      }

      final videos = _parseReelsSnapshot(
        reelsSnapshot.value,
        forFollowingFeed: false,
      );
      _sortByTimestampDesc(videos);
      final trimmed =
          videos.length > _pageSize ? videos.sublist(0, _pageSize) : videos;
      _rankSortPersonalized(trimmed);
      ReelsAlgorithm.lightShuffle(trimmed, Random());

      _emitForYou(state.forYou.copyWith(
        status: ReelsFeedStatus.loaded,
        reels: trimmed,
        hasReachedEnd: trimmed.length < _pageSize,
        errorMessage:
            trimmed.isEmpty ? 'لا توجد ريلز حالياً — كن أول من ينشر!' : null,
      ));

      _startNewReelsListener();
    } catch (e) {
      debugPrint('ReelsFeedCubit: loadForYou error -> $e');
      final existing = state.forYou.reels;
      _emitForYou(state.forYou.copyWith(
        status:
            existing.isEmpty ? ReelsFeedStatus.error : ReelsFeedStatus.loaded,
        reels: existing,
        errorMessage: existing.isEmpty
            ? 'تعذّر تحميل الريلز — تأكد من اتصالك بالإنترنت'
            : null,
        hasReachedEnd: existing.isEmpty,
      ));
    }
  }

  /// يضع الريل المختار في الفهرس 0 مع الإبقاء على ترتيب البقية.
  List<VideoModel> _orderPinnedFirst(List<VideoModel> list, String? pinnedId) {
    if (list.isEmpty) return List<VideoModel>.from(list);
    final pin = pinnedId?.trim();
    if (pin == null || pin.isEmpty) return List<VideoModel>.from(list);
    final idx = list.indexWhere((r) => r.id == pin);
    if (idx <= 0) return List<VideoModel>.from(list);
    final copy = List<VideoModel>.from(list);
    final p = copy.removeAt(idx);
    return [p, ...copy];
  }

  /// تحويل دفعة مستندات Firestore إلى نماذج مع جلب حالة الإعجاب.
  Future<List<VideoModel>> _videoModelsFromFirestoreDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return [];
    final uid = _auth.currentUser?.uid;
    final ids = docs.map((d) => d.id).toList(growable: false);
    final liked = uid != null
        ? await _fetchLikeFlagsForReels(ids, uid)
        : const <String, bool>{};

    final out = <VideoModel>[];
    for (final d in docs) {
      final data = Map<String, dynamic>.from(d.data());
      var vm = VideoModel.fromJson(data, d.id).copyWith(
        isSavedByCurrentUser: _savedIds.contains(d.id),
        isLikedByCurrentUser: liked[d.id] ?? false,
      );
      if (vm.appSource.isEmpty) {
        vm = vm.copyWith(
          appSource: AppConfig.reelsFirestoreClubTag,
          engagementCount: ReelsAlgorithm.computeEngagementCount(
            likes: vm.likesCount,
            comments: vm.commentsCount,
            views: vm.viewsCount,
            watchCount: vm.watchCount,
          ),
        );
      }
      if (vm.isPrivate) continue;
      if (!_allowedAudience(vm, forFollowingFeed: false)) continue;
      if (vm.videoUrl.isEmpty) continue;
      out.add(vm);
    }
    return out;
  }

  /// فيد مقصور على مستخدم واحد — بذرة من الشبكة ثم مزامنة Firestore.
  Future<void> _loadForYouProfileScoped() async {
    final uidScope = profileOnlyUserId!.trim();
    final pin = initialReelId?.trim();

    _emitForYou(state.forYou.copyWith(
      status: ReelsFeedStatus.loading,
      hasReachedEnd: false,
    ));
    _lastForYouFirestoreDoc = null;
    _forYouUsingFirestore = true;
    _lastProfileFirestoreDoc = null;
    _profileFirestoreLoadedIds.clear();

    try {
      _reloadIgnoredCache();

      final seeds = seedProfileReels;
      List<VideoModel> ordered = [];
      if (seeds != null && seeds.isNotEmpty) {
        ordered = _orderPinnedFirst(
          _withoutIgnored(
            seeds.where((r) => r.userId == uidScope).toList(),
          ),
          pin,
        );
      }

      final authUid = _auth.currentUser?.uid;
      if (authUid != null) {
        final r = await Future.wait<Object?>([
          _fetchUserActivity(authUid),
          _fetchSavedVideoIds(authUid),
        ]);
        _userActivity = r[0] as Map<String, UserActivitySummary>;
        _savedIds = r[1] as Set<String>;
      } else {
        _userActivity = const {};
        _savedIds = {};
      }

      if (ordered.isEmpty) {
        await _profileFeedFirestoreBootstrap(uidScope, pin);
        return;
      }

      for (final r in ordered) {
        _profileFirestoreLoadedIds.add(r.id);
      }

      _emitForYou(state.forYou.copyWith(
        status: ReelsFeedStatus.loaded,
        reels: ordered,
        hasReachedEnd: false,
        errorMessage: null,
      ));

      unawaited(_syncProfileFeedWithFirestore(uidScope));
    } catch (e) {
      debugPrint('ReelsFeedCubit: profile scoped load -> $e');
      _emitForYou(state.forYou.copyWith(
        status: ReelsFeedStatus.error,
        reels: const [],
        errorMessage: 'تعذّر تحميل ريلز البروفايل',
        hasReachedEnd: true,
      ));
    }
  }

  /// جلب أول دفعة من Firestore لو شبكة البروفايل لم تُرسل بذرة.
  Future<void> _profileFeedFirestoreBootstrap(
    String uidScope,
    String? pin,
  ) async {
    final docs = await _reelsRemote.fetchReelsByUserId(
      userId: uidScope,
      isGlobal: state.isGlobalAudience,
      limit: 40,
      startAfter: null,
    );

    final parsed =
        _withoutIgnored(await _videoModelsFromFirestoreDocs(docs));

    if (parsed.isEmpty) {
      _emitForYou(state.forYou.copyWith(
        status: ReelsFeedStatus.loaded,
        reels: const [],
        hasReachedEnd: true,
        errorMessage: 'لا توجد ريلز لهذا المستخدم',
      ));
      return;
    }

    final ordered = _orderPinnedFirst(parsed, pin);
    _lastProfileFirestoreDoc = docs.isNotEmpty ? docs.last : null;

    _profileFirestoreLoadedIds
      ..clear()
      ..addAll(ordered.map((r) => r.id));

    _emitForYou(state.forYou.copyWith(
      status: ReelsFeedStatus.loaded,
      reels: ordered,
      hasReachedEnd: docs.length < 40,
      errorMessage: null,
    ));
  }

  /// دمج ريلز إضافية من Firestore مع قائمة البذرة (بدون تكرار).
  Future<void> _syncProfileFeedWithFirestore(String uidScope) async {
    try {
      final docs = await _reelsRemote.fetchReelsByUserId(
        userId: uidScope,
        isGlobal: state.isGlobalAudience,
        limit: 40,
        startAfter: null,
      );
      if (docs.isEmpty) {
        _emitForYou(state.forYou.copyWith(hasReachedEnd: true));
        return;
      }

      _lastProfileFirestoreDoc = docs.last;

      final parsed =
          _withoutIgnored(await _videoModelsFromFirestoreDocs(docs));
      final pin = initialReelId?.trim();
      final currentIds = state.forYou.reels.map((r) => r.id).toSet();
      final extras = parsed
          .where((r) => !currentIds.contains(r.id))
          .toList(growable: false)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (extras.isEmpty) {
        _emitForYou(state.forYou.copyWith(
          hasReachedEnd: docs.length < 40,
        ));
        return;
      }

      for (final r in extras) {
        _profileFirestoreLoadedIds.add(r.id);
      }

      final merged = [...state.forYou.reels, ...extras];
      final finalList = _orderPinnedFirst(merged, pin);

      _emitForYou(state.forYou.copyWith(
        reels: finalList,
        hasReachedEnd: docs.length < 40,
      ));
    } catch (e) {
      debugPrint('ReelsFeedCubit: sync profile Firestore -> $e');
    }
  }

  Future<void> _loadMoreProfileScoped() async {
    final feed = state.forYou;
    if (feed.isLoadingMore || feed.hasReachedEnd) return;

    final uidScope = profileOnlyUserId!.trim();

    _emitForYou(feed.copyWith(isLoadingMore: true));
    try {
      final docs = await _reelsRemote.fetchReelsByUserId(
        userId: uidScope,
        isGlobal: state.isGlobalAudience,
        limit: 25,
        startAfter: _lastProfileFirestoreDoc,
      );
      if (docs.isEmpty) {
        _emitForYou(state.forYou.copyWith(
          isLoadingMore: false,
          hasReachedEnd: true,
        ));
        return;
      }
      _lastProfileFirestoreDoc = docs.last;

      final parsed =
          _withoutIgnored(await _videoModelsFromFirestoreDocs(docs));
      final existing = state.forYou.reels.map((r) => r.id).toSet();
      final fresh = parsed
          .where((r) => !existing.contains(r.id))
          .toList(growable: false)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (fresh.isEmpty) {
        _emitForYou(state.forYou.copyWith(
          isLoadingMore: false,
          hasReachedEnd: docs.length < 25,
        ));
        return;
      }

      _emitForYou(state.forYou.copyWith(
        reels: [...state.forYou.reels, ...fresh],
        isLoadingMore: false,
        hasReachedEnd: docs.length < 25,
      ));
    } catch (e) {
      debugPrint('ReelsFeedCubit: loadMoreProfileScoped -> $e');
      _emitForYou(state.forYou.copyWith(isLoadingMore: false));
    }
  }

  /// إشعار/رابط: ريل واحد أولاً ثم إكمال الخوارزمية في الخلفية.
  Future<void> _loadForYouPinnedThenAlgorithm(String pinnedId) async {
    _emitForYou(state.forYou.copyWith(
      status: ReelsFeedStatus.loading,
      hasReachedEnd: false,
    ));
    _lastForYouFirestoreDoc = null;
    _forYouUsingFirestore = false;

    try {
      _reloadIgnoredCache();
      final authUid = _auth.currentUser?.uid;

      if (authUid != null) {
        final r = await Future.wait<Object?>([
          _fetchUserActivity(authUid),
          _fetchSavedVideoIds(authUid),
        ]);
        _userActivity = r[0] as Map<String, UserActivitySummary>;
        _savedIds = r[1] as Set<String>;
      } else {
        _userActivity = const {};
        _savedIds = {};
      }

      final doc = await _reelsRemote.fetchReelDocById(pinnedId);
      VideoModel? pinnedVm;
      if (doc != null && doc.exists && doc.data() != null) {
        final liked = authUid != null
            ? await _fetchLikeFlagsForReels([pinnedId], authUid)
            : const <String, bool>{};
        final data = Map<String, dynamic>.from(doc.data()!);
        var vm = VideoModel.fromJson(data, pinnedId).copyWith(
          isSavedByCurrentUser: _savedIds.contains(pinnedId),
          isLikedByCurrentUser: liked[pinnedId] ?? false,
        );
        if (vm.appSource.isEmpty) {
          vm = vm.copyWith(
            appSource: AppConfig.reelsFirestoreClubTag,
            engagementCount: ReelsAlgorithm.computeEngagementCount(
              likes: vm.likesCount,
              comments: vm.commentsCount,
              views: vm.viewsCount,
              watchCount: vm.watchCount,
            ),
          );
        }
        pinnedVm = vm;
      }

      if (pinnedVm == null ||
          pinnedVm.videoUrl.isEmpty ||
          pinnedVm.isPrivate ||
          !_allowedAudience(pinnedVm, forFollowingFeed: false) ||
          _ignoredReelIds.contains(pinnedVm.id)) {
        await _loadForYouClassic();
        return;
      }

      _emitForYou(state.forYou.copyWith(
        status: ReelsFeedStatus.loaded,
        reels: [pinnedVm],
        hasReachedEnd: false,
        errorMessage: null,
      ));
      _forYouUsingFirestore = true;

      _startNewReelsListener();

      unawaited(_hydrateForYouAfterPinned(pinnedVm));
    } catch (e) {
      debugPrint('ReelsFeedCubit: pinned entry -> $e');
      await _loadForYouClassic();
    }
  }

  Future<void> _hydrateForYouAfterPinned(VideoModel pinnedVm) async {
    try {
      _reloadIgnoredCache();
      final authUid = _auth.currentUser?.uid;

      final docs = await _reelsRemote.fetchTopReels(
        isGlobal: state.isGlobalAudience,
        limit: 50,
        startAfter: null,
      );

      if (docs.isEmpty) {
        _emitForYou(state.forYou.copyWith(hasReachedEnd: true));
        return;
      }

      final ids = docs.map((d) => d.id).toList(growable: false);
      final liked = authUid != null
          ? await _fetchLikeFlagsForReels(ids, authUid)
          : const <String, bool>{};

      final parsed = <VideoModel>[];
      for (final d in docs) {
        final data = Map<String, dynamic>.from(d.data());
        var vm = VideoModel.fromJson(data, d.id).copyWith(
          isSavedByCurrentUser: _savedIds.contains(d.id),
          isLikedByCurrentUser: liked[d.id] ?? false,
        );
        if (vm.appSource.isEmpty) {
          vm = vm.copyWith(
            appSource: AppConfig.reelsFirestoreClubTag,
            engagementCount: ReelsAlgorithm.computeEngagementCount(
              likes: vm.likesCount,
              comments: vm.commentsCount,
              views: vm.viewsCount,
              watchCount: vm.watchCount,
            ),
          );
        }
        if (vm.isPrivate) continue;
        if (!_allowedAudience(vm, forFollowingFeed: false)) continue;
        if (vm.videoUrl.isEmpty) continue;
        parsed.add(vm);
      }

      if (parsed.isEmpty) {
        _emitForYou(state.forYou.copyWith(hasReachedEnd: true));
        return;
      }

      _rankSortPersonalized(parsed);
      ReelsAlgorithm.lightShuffle(parsed, Random());

      final rest =
          parsed.where((r) => r.id != pinnedVm.id).toList(growable: false);
      final merged = [pinnedVm, ...rest];

      _emitForYou(state.forYou.copyWith(
        reels: merged,
        hasReachedEnd: docs.length < 50,
        errorMessage: null,
      ));
      _lastForYouFirestoreDoc = docs.last;
    } catch (e) {
      debugPrint('ReelsFeedCubit: hydrate after pinned -> $e');
    }
  }

  /// Fallback لجلب الريلز بدون orderByChild (في حالة عدم وجود index على timestamp
  /// أو وجود مشكلة بصلاحيات الاستعلامات). نجلب الكل ثم نرتّب client-side.
  Future<DataSnapshot> _loadReelsFallback() async {
    return _database.ref(AppConfig.rtdbReelsPath).get().timeout(const Duration(seconds: 20));
  }

  Future<void> _loadMoreForYou() async {
    final feed = state.forYou;
    if (feed.isLoadingMore || feed.hasReachedEnd || feed.reels.isEmpty) return;

    if (isProfileScopedFeed) {
      await _loadMoreProfileScoped();
      return;
    }

    if (_forYouUsingFirestore && _lastForYouFirestoreDoc != null) {
      _emitForYou(feed.copyWith(isLoadingMore: true));
      try {
        final docs = await _reelsRemote.fetchTopReels(
          isGlobal: state.isGlobalAudience,
          limit: 50,
          startAfter: _lastForYouFirestoreDoc,
        );
        if (docs.isEmpty) {
          _emitForYou(state.forYou.copyWith(
            isLoadingMore: false,
            hasReachedEnd: true,
          ));
          return;
        }
        _lastForYouFirestoreDoc = docs.last;

        final uid = _auth.currentUser?.uid;
        final ids = docs.map((d) => d.id).toList(growable: false);
        final liked = uid != null
            ? await _fetchLikeFlagsForReels(ids, uid)
            : const <String, bool>{};

        final parsed = <VideoModel>[];
        for (final d in docs) {
          final data = Map<String, dynamic>.from(d.data());
          var vm = VideoModel.fromJson(data, d.id).copyWith(
            isSavedByCurrentUser: _savedIds.contains(d.id),
            isLikedByCurrentUser: liked[d.id] ?? false,
          );
          if (vm.appSource.isEmpty) {
            vm = vm.copyWith(
              appSource: AppConfig.reelsFirestoreClubTag,
              engagementCount: ReelsAlgorithm.computeEngagementCount(
                likes: vm.likesCount,
                comments: vm.commentsCount,
                views: vm.viewsCount,
                watchCount: vm.watchCount,
              ),
            );
          }
          if (vm.isPrivate) continue;
          if (!_allowedAudience(vm, forFollowingFeed: false)) continue;
          if (vm.videoUrl.isEmpty) continue;
          parsed.add(vm);
        }

        final existingIds = state.forYou.reels.map((r) => r.id).toSet();
        final unique =
            parsed.where((r) => !existingIds.contains(r.id)).toList(growable: true);

        _rankSortPersonalized(unique);
        ReelsAlgorithm.lightShuffle(unique, Random());

        _emitForYou(state.forYou.copyWith(
          reels: [...state.forYou.reels, ...unique],
          isLoadingMore: false,
          hasReachedEnd: unique.length < 50,
        ));
      } catch (e) {
        debugPrint('ReelsFeedCubit: loadMoreForYou Firestore error -> $e');
        _emitForYou(state.forYou.copyWith(isLoadingMore: false));
      }
      return;
    }

    _emitForYou(feed.copyWith(isLoadingMore: true));
    try {
      final oldest = feed.reels.last.timestamp.millisecondsSinceEpoch;
      debugPrint('[Cubit] loadMoreForYou: cursor=$oldest');

      final snapshot = await _database
          .ref(AppConfig.rtdbReelsPath)
          .orderByChild('timestamp')
          .endBefore(oldest)
          .limitToLast(_pageSize)
          .get()
          .timeout(const Duration(seconds: 15));

      if (!snapshot.exists || snapshot.value == null) {
        _emitForYou(state.forYou.copyWith(
          isLoadingMore: false,
          hasReachedEnd: true,
        ));
        return;
      }

      final more = _parseReelsSnapshot(
        snapshot.value,
        forFollowingFeed: false,
      );
      if (more.isEmpty) {
        _emitForYou(state.forYou.copyWith(
          isLoadingMore: false,
          hasReachedEnd: true,
        ));
        return;
      }

      final existingIds = state.forYou.reels.map((r) => r.id).toSet();
      final unique =
          more.where((r) => !existingIds.contains(r.id)).toList(growable: true);

      _rankSortPersonalized(unique);

      _emitForYou(state.forYou.copyWith(
        reels: [...state.forYou.reels, ...unique],
        isLoadingMore: false,
        hasReachedEnd: unique.length < _pageSize,
      ));
    } catch (e) {
      debugPrint('ReelsFeedCubit: loadMoreForYou error -> $e');
      _emitForYou(state.forYou.copyWith(isLoadingMore: false));
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // MARK: Following feed
  // ══════════════════════════════════════════════════════════════════

  /// تحميل فيد "Following" — فقط ريلز من المتابَعين، بترتيب زمني تنازلي.
  /// ═══════════════════════════════════════════════════════════════
  /// المراحل:
  ///   1) جلب قائمة الـ following IDs للمستخدم الحالي.
  ///   2) جلب آخر (pageSize * 5) ريل من `/reels`.
  ///   3) Filter client-side بـ userId.
  ///   4) Sort حسب timestamp تنازلياً.
  Future<void> loadFollowing() async {
    _emitFollowing(state.following.copyWith(
      status: ReelsFeedStatus.loading,
      hasReachedEnd: false,
    ));
    try {
      _reloadIgnoredCache();
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        _emitFollowing(state.following.copyWith(
          status: ReelsFeedStatus.loaded,
          reels: const [],
          hasReachedEnd: true,
          errorMessage: 'سجّل الدخول لمتابعة المبدعين',
        ));
        return;
      }

      // جلب الـ following + دفعة كبيرة من الريلز بالتوازي
      final results = await Future.wait<Object?>([
        _fetchFollowingIds(uid),
        _database
            .ref(AppConfig.rtdbReelsPath)
            .orderByChild('timestamp')
            .limitToLast(_pageSize * _followingFetchMultiplier)
            .get()
            .timeout(const Duration(seconds: 15)),
      ]);

      _followingIds = results[0] as Set<String>;
      final reelsSnapshot = results[1] as DataSnapshot;

      if (_followingIds.isEmpty) {
        _emitFollowing(state.following.copyWith(
          status: ReelsFeedStatus.loaded,
          reels: const [],
          hasReachedEnd: true,
          errorMessage: 'لم تتابع أي شخص بعد',
        ));
        return;
      }

      if (!reelsSnapshot.exists || reelsSnapshot.value == null) {
        _emitFollowing(state.following.copyWith(
          status: ReelsFeedStatus.loaded,
          reels: const [],
          hasReachedEnd: true,
        ));
        return;
      }

      final all = _parseReelsSnapshot(
        reelsSnapshot.value,
        forFollowingFeed: true,
      );
      final filtered = all
          .where((r) => _followingIds.contains(r.userId))
          .toList(growable: true);
      _sortByTimestampDesc(filtered);

      debugPrint(
        '[Following] ${all.length} reels fetched, ${filtered.length} from followed users',
      );

      _emitFollowing(state.following.copyWith(
        status: ReelsFeedStatus.loaded,
        reels: filtered,
        hasReachedEnd: all.length < _pageSize * _followingFetchMultiplier,
      ));
    } catch (e) {
      debugPrint('ReelsFeedCubit: loadFollowing error -> $e');
      _emitFollowing(state.following.copyWith(
        status: ReelsFeedStatus.error,
        errorMessage: 'فشل تحميل فيد المتابَعين',
      ));
    }
  }

  Future<void> _loadMoreFollowing() async {
    final feed = state.following;
    if (feed.isLoadingMore || feed.hasReachedEnd || feed.reels.isEmpty) return;
    if (_followingIds.isEmpty) return;

    _emitFollowing(feed.copyWith(isLoadingMore: true));
    try {
      final oldest = feed.reels.last.timestamp.millisecondsSinceEpoch;

      final snapshot = await _database
          .ref(AppConfig.rtdbReelsPath)
          .orderByChild('timestamp')
          .endBefore(oldest)
          .limitToLast(_pageSize * _followingFetchMultiplier)
          .get()
          .timeout(const Duration(seconds: 15));

      if (!snapshot.exists || snapshot.value == null) {
        _emitFollowing(state.following.copyWith(
          isLoadingMore: false,
          hasReachedEnd: true,
        ));
        return;
      }

      final all = _parseReelsSnapshot(
        snapshot.value,
        forFollowingFeed: true,
      );
      final existingIds = state.following.reels.map((r) => r.id).toSet();
      final filtered = all
          .where(
            (r) =>
                _followingIds.contains(r.userId) && !existingIds.contains(r.id),
          )
          .toList(growable: true);
      _sortByTimestampDesc(filtered);

      _emitFollowing(state.following.copyWith(
        reels: [...state.following.reels, ...filtered],
        isLoadingMore: false,
        hasReachedEnd: all.length < _pageSize * _followingFetchMultiplier,
      ));
    } catch (e) {
      debugPrint('ReelsFeedCubit: loadMoreFollowing error -> $e');
      _emitFollowing(state.following.copyWith(isLoadingMore: false));
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // MARK: Data fetchers
  // ══════════════════════════════════════════════════════════════════

  /// جلب كل نشاط المستخدم الحالي وتحويله إلى Map للبحث السريع O(1).
  Future<Map<String, UserActivitySummary>> _fetchUserActivity(
      String uid) async {
    try {
      final snap = await _database
          .ref('user_activity/$uid')
          .get()
          .timeout(const Duration(seconds: 10));

      if (!snap.exists || snap.value is! Map) return const {};

      final map = <String, UserActivitySummary>{};
      (snap.value as Map).forEach((videoId, value) {
        if (value is Map) {
          map[videoId.toString()] = UserActivitySummary(
            watchTime: _asInt(value['watchTime']),
            liked: value['liked'] == true,
            commented: value['commented'] == true,
            shared: value['shared'] == true,
          );
        }
      });
      debugPrint('[Ranking] loaded ${map.length} activity record(s) for $uid');
      return map;
    } catch (e) {
      debugPrint('ReelsFeedCubit: _fetchUserActivity error -> $e');
      return const {};
    }
  }

  /// جلب IDs المستخدمين اللي بيتابعهم المستخدم الحالي.
  /// البنية: `/follows/{currentUid}/{targetUid}: true`
  Future<Set<String>> _fetchFollowingIds(String uid) async {
    try {
      final snap = await _database
          .ref('follows/$uid')
          .get()
          .timeout(const Duration(seconds: 10));
      if (!snap.exists || snap.value is! Map) return const {};
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      return map.keys.map((k) => k.toString()).toSet();
    } catch (e) {
      debugPrint('ReelsFeedCubit: _fetchFollowingIds error -> $e');
      return const {};
    }
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// تحليل بيانات snapshot من Firebase إلى قائمة VideoModel (بدون ترتيب).
  /// ═══════════════════════════════════════════════════════════════════
  /// ‣ نحسب likesCount الصارم من عدد أطفال `likes` (ما ينقصش ولا يزيد عبثاً)
  /// ‣ نحسب commentsCount الصارم من عدد أطفال `comments`
  /// ‣ نضبط `isLikedByCurrentUser` حسب وجود uid المستخدم الحالي في `likes`
  /// ‣ نضبط `isSavedByCurrentUser` من كاش `_savedIds`
  List<VideoModel> _parseReelsSnapshot(
    Object? raw, {
    required bool forFollowingFeed,
  }) {
    if (raw is! Map) return const [];
    final uid = _auth.currentUser?.uid;
    final videos = <VideoModel>[];
    raw.forEach((key, value) {
      if (value is Map) {
        try {
          final map = Map<String, dynamic>.from(value);
          final id = key.toString();
          var model = VideoModel.fromJson(map, id);

          // عدّاد الإعجابات الصارم + حالة الإعجاب للمستخدم الحالي
          final likes = map['likes'];
          int likesCount = model.likesCount;
          bool isLikedByMe = false;
          if (likes is Map) {
            likesCount = likes.length;
            if (uid != null) isLikedByMe = likes[uid] == true;
          }

          // عدّاد التعليقات الصارم
          final comments = map['comments'];
          int commentsCount = model.commentsCount;
          if (comments is Map) {
            commentsCount = comments.length;
          }

          model = model.copyWith(
            likesCount: likesCount,
            commentsCount: commentsCount,
            isLikedByCurrentUser: isLikedByMe,
            isSavedByCurrentUser: _savedIds.contains(id),
          );

          if (model.appSource.isEmpty) {
            model = model.copyWith(
              appSource: AppConfig.reelsFirestoreClubTag,
              engagementCount: ReelsAlgorithm.computeEngagementCount(
                likes: model.likesCount,
                comments: model.commentsCount,
                views: model.viewsCount,
                watchCount: model.watchCount,
              ),
            );
          }

          // الريلز الخاصة لا تظهر في الفيد العام (تظهر فقط في تبويب البروفايل لصاحبها)
          if (model.isPrivate) return;

          if (!_allowedAudience(model, forFollowingFeed: forFollowingFeed)) {
            return;
          }
          if (model.videoUrl.isNotEmpty) videos.add(model);
        } catch (e) {
          debugPrint('ReelsFeedCubit: parse error for $key -> $e');
        }
      }
    });
    return videos;
  }

  /// جلب قائمة IDs للريلز المحفوظة عند المستخدم
  Future<Set<String>> _fetchSavedVideoIds(String uid) async {
    try {
      final snap = await _database
          .ref('users/$uid/savedVideos')
          .get()
          .timeout(const Duration(seconds: 10));
      if (!snap.exists || snap.value is! Map) return const {};
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      return map.keys.map((k) => k.toString()).toSet();
    } catch (e) {
      debugPrint('ReelsFeedCubit: _fetchSavedVideoIds error -> $e');
      return const {};
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // MARK: Sorting
  // ══════════════════════════════════════════════════════════════════

  /// الترتيب الشخصي للـ For You — قلب نظام التوصيات.
  /// ═══════════════════════════════════════════════════════════════
  /// يرتّب القائمة in-place بالـ personalScore تنازلياً، مع الاعتماد
  /// على الكاش [_userActivity] (لا أي IO إضافي).
  ///
  /// التعقيد الزمني: O(n log n) — يتم مرّة واحدة فقط بعد fetch.
  /// Tie-breaker: الأحدث أولاً.
  void _rankSortPersonalized(List<VideoModel> list) {
    if (list.isEmpty) return;
    // كاش لنتيجة personalScore لكل عنصر علشان ما نكرّرش الحساب داخل comparator
    final scoreCache = <String, double>{};
    double scoreOf(VideoModel v) {
      final cached = scoreCache[v.id];
      if (cached != null) return cached;
      final s = v.personalScore(_userActivity[v.id]);
      scoreCache[v.id] = s;
      return s;
    }

    list.sort((a, b) {
      final byScore = scoreOf(b).compareTo(scoreOf(a));
      if (byScore != 0) return byScore;
      return b.timestamp.compareTo(a.timestamp);
    });

    if (kDebugMode) {
      for (final r in list) {
        final p = scoreOf(r);
        final activity = _userActivity[r.id];
        final tag = activity == null
            ? 'base'
            : (activity.liked
                ? 'liked'
                : (activity.skippedQuickly
                    ? 'skipped'
                    : (activity.hasWatched ? 'watched' : 'seen')));
        debugPrint(
          '[Ranking] ${r.id} -> base=${r.score.toStringAsFixed(1)} '
          'personal=${p.toStringAsFixed(1)} ($tag'
          '${activity != null && activity.watchTime > 0 ? ', wt=${activity.watchTime}s' : ''})',
        );
      }
    }
  }

  /// ترتيب زمني بسيط للـ Following feed (الأحدث أولاً).
  void _sortByTimestampDesc(List<VideoModel> list) {
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ══════════════════════════════════════════════════════════════════
  // MARK: Local state mutations (called from UI / services)
  // ══════════════════════════════════════════════════════════════════

  /// تحديث محلي لإحصاءات ريل (views + totalWatchTime) بدون إعادة ترتيب.
  /// يُطبَّق على الفيدين معاً إذا الريل موجود فيهما.
  Future<void> applyStatsIncrement(
    String videoId, {
    int addedViews = 0,
    int addedSeconds = 0,
  }) async {
    if (addedViews == 0 && addedSeconds == 0) return;
    _updateVideoInAllFeeds(videoId, (v) {
      final nextViews = v.viewsCount + addedViews;
      return v.copyWith(
        viewsCount: nextViews,
        totalWatchTime: v.totalWatchTime + addedSeconds,
        engagementCount: ReelsAlgorithm.computeEngagementCount(
          likes: v.likesCount,
          comments: v.commentsCount,
          views: nextViews,
          watchCount: v.watchCount,
        ),
      );
    });
    await _syncFirestoreRanking(videoId, engagementDelta: addedViews);
  }

  /// مشاهدة مؤهّلة في الخوارزمية: بعد مشاهدة نسبة كبيرة من الريل نزيد [watch_count].
  Future<void> recordQualifiedWatch(
    String videoId, {
    VideoModel? reelContext,
  }) async {
    if (_qualifiedWatchRecorded.contains(videoId)) return;
    _qualifiedWatchRecorded.add(videoId);

    final existing = _findReel(videoId);
    if (existing != null) {
      _updateVideoInAllFeeds(videoId, (v) {
        final wc = v.watchCount + 1;
        return v.copyWith(
          watchCount: wc,
          engagementCount: ReelsAlgorithm.computeEngagementCount(
            likes: v.likesCount,
            comments: v.commentsCount,
            views: v.viewsCount,
            watchCount: wc,
          ),
        );
      });
    }

    try {
      await _reelsRemote.incrementWatchCount(videoId);
      await _reelsRemote.incrementEngagementCount(videoId, delta: 1);
      final updated = _findReel(videoId) ??
          (reelContext != null
              ? reelContext.copyWith(
                  watchCount: reelContext.watchCount + 1,
                  engagementCount: ReelsAlgorithm.computeEngagementCount(
                    likes: reelContext.likesCount,
                    comments: reelContext.commentsCount,
                    views: reelContext.viewsCount,
                    watchCount: reelContext.watchCount + 1,
                  ),
                )
              : null);
      if (updated != null) {
        await _reelsRemote.updateRankingOnly(updated);
      }
    } catch (e) {
      debugPrint('[Ranking] recordQualifiedWatch $videoId: $e');
    }
  }

  /// جلب ريلز تحمل هاشتاجاً محدداً من Firestore (لشاشة الهاشتاج).
  Future<List<VideoModel>> fetchReelsForHashtag(String rawTag) async {
    final docs = await _reelsRemote.fetchReelsByHashtag(
      rawTag: rawTag,
      isGlobal: state.isGlobalAudience,
    );
    final uid = _auth.currentUser?.uid;
    final ids = docs.map((d) => d.id).toList(growable: false);
    final liked = uid != null
        ? await _fetchLikeFlagsForReels(ids, uid)
        : const <String, bool>{};
    final parsed = <VideoModel>[];
    for (final d in docs) {
      final data = Map<String, dynamic>.from(d.data());
      var vm = VideoModel.fromJson(data, d.id).copyWith(
        isSavedByCurrentUser: _savedIds.contains(d.id),
        isLikedByCurrentUser: liked[d.id] ?? false,
      );
      if (vm.appSource.isEmpty) {
        vm = vm.copyWith(
          appSource: AppConfig.reelsFirestoreClubTag,
          engagementCount: ReelsAlgorithm.computeEngagementCount(
            likes: vm.likesCount,
            comments: vm.commentsCount,
            views: vm.viewsCount,
            watchCount: vm.watchCount,
          ),
        );
      }
      if (vm.isPrivate) continue;
      if (!_allowedAudience(vm, forFollowingFeed: false)) continue;
      if (vm.videoUrl.isEmpty) continue;
      parsed.add(vm);
    }
    return parsed;
  }

  /// استبعاد ريل من الفيد والتخزين المحلي («غير مهتم»).
  Future<void> markNotInterested(String reelId) async {
    if (reelId.isEmpty) return;
    await _ignored.addIgnored(reelId);
    _ignoredReelIds.add(reelId);
    final fy = state.forYou.reels.where((r) => r.id != reelId).toList();
    final fo = state.following.reels.where((r) => r.id != reelId).toList();
    emit(state.copyWith(
      forYou: state.forYou.copyWith(reels: fy),
      following: state.following.copyWith(reels: fo),
    ));
  }

  /// ريلز بنفس مصدر الصوت — مرتبة تنازلياً حسب [VideoModel.score].
  Future<List<VideoModel>> fetchReelsForAudioUrl(String audioKey) async {
    if (audioKey.isEmpty) return [];
    final docs = await _reelsRemote.fetchReelsByAudioUrl(
      audioUrl: audioKey,
      isGlobal: state.isGlobalAudience,
    );
    final uid = _auth.currentUser?.uid;
    final ids = docs.map((d) => d.id).toList(growable: false);
    final liked = uid != null
        ? await _fetchLikeFlagsForReels(ids, uid)
        : const <String, bool>{};
    final parsed = <VideoModel>[];
    for (final d in docs) {
      final data = Map<String, dynamic>.from(d.data());
      var vm = VideoModel.fromJson(data, d.id).copyWith(
        isSavedByCurrentUser: _savedIds.contains(d.id),
        isLikedByCurrentUser: liked[d.id] ?? false,
      );
      if (vm.appSource.isEmpty) {
        vm = vm.copyWith(
          appSource: AppConfig.reelsFirestoreClubTag,
          engagementCount: ReelsAlgorithm.computeEngagementCount(
            likes: vm.likesCount,
            comments: vm.commentsCount,
            views: vm.viewsCount,
            watchCount: vm.watchCount,
          ),
        );
      }
      if (vm.isPrivate) continue;
      if (!_allowedAudience(vm, forFollowingFeed: false)) continue;
      if (vm.videoUrl.isEmpty) continue;
      if (_ignoredReelIds.contains(vm.id)) continue;
      parsed.add(vm);
    }
    parsed.sort((a, b) => b.score.compareTo(a.score));
    return parsed;
  }

  /// تسجيل تعليق: زيادة commentsCount (atomic) في Firebase + تحديث محلي.
  Future<void> recordComment(String videoId) async {
    _updateVideoInAllFeeds(
      videoId,
      (v) {
        final nextComments = v.commentsCount + 1;
        return v.copyWith(
          commentsCount: nextComments,
          engagementCount: ReelsAlgorithm.computeEngagementCount(
            likes: v.likesCount,
            comments: nextComments,
            views: v.viewsCount,
            watchCount: v.watchCount,
          ),
        );
      },
    );
    try {
      await _database
          .ref('${AppConfig.rtdbReelsPath}/$videoId/commentsCount')
          .set(ServerValue.increment(1));
      await _syncFirestoreRanking(videoId, engagementDelta: 1);
      final reel = _findReel(videoId);
      if (reel != null) {
        unawaited(getIt<ReelInteractionNotificationService>().notifyComment(reel));
      }
    } catch (e) {
      debugPrint('[Ranking] recordComment error $videoId: $e');
    }
  }

  /// تسجيل مشاركة: زيادة sharesCount (atomic) في Firebase + تحديث محلي.
  Future<void> recordShare(String videoId) async {
    _updateVideoInAllFeeds(
      videoId,
      (v) => v.copyWith(sharesCount: v.sharesCount + 1),
    );
    try {
      await _database
          .ref('${AppConfig.rtdbReelsPath}/$videoId/sharesCount')
          .set(ServerValue.increment(1));
    } catch (e) {
      debugPrint('[Ranking] recordShare error $videoId: $e');
    }
  }

  /// تبديل إعجاب الفيديو - تحديث تفاؤلي + إرسال لـ Firebase
  /// [reelContext] يُستخدم خارج قائمة الفيد الرئيسية (مثل شاشة الهاشتاج).
  Future<void> toggleLike(String videoId, {VideoModel? reelContext}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final existing = _findReel(videoId);
    final basis = existing ?? reelContext;
    if (basis == null) return;

    final willBeLiked = !basis.isLikedByCurrentUser;
    final delta = willBeLiked ? 1 : -1;

    if (existing != null) {
      _updateVideoInAllFeeds(videoId, (v) {
        final nextLikes = (v.likesCount + delta).clamp(0, 1 << 31);
        return v.copyWith(
          isLikedByCurrentUser: willBeLiked,
          likesCount: nextLikes,
          engagementCount: ReelsAlgorithm.computeEngagementCount(
            likes: nextLikes,
            comments: v.commentsCount,
            views: v.viewsCount,
            watchCount: v.watchCount,
          ),
        );
      });
    }

    try {
      final likeRef =
          _database.ref('${AppConfig.rtdbReelsPath}/$videoId/likes/$userId');
      if (willBeLiked) {
        await likeRef.set(true);
      } else {
        await likeRef.remove();
      }
      await _database
          .ref('${AppConfig.rtdbReelsPath}/$videoId/likesCount')
          .set(ServerValue.increment(delta));
      await _syncFirestoreRanking(videoId, engagementDelta: delta);
      if (willBeLiked) {
        final reel = _findReel(videoId) ?? reelContext;
        if (reel != null) {
          unawaited(getIt<ReelInteractionNotificationService>().notifyLike(reel));
        }
      }
    } catch (e) {
      debugPrint('ReelsFeedCubit: toggleLike error -> $e');
      if (existing != null) {
        _updateVideoInAllFeeds(videoId, (v) {
          final rolled =
              (v.likesCount - delta).clamp(0, 1 << 31); // عدّاد تقريبي للتراجع
          return v.copyWith(
            isLikedByCurrentUser: !willBeLiked,
            likesCount: rolled,
            engagementCount: ReelsAlgorithm.computeEngagementCount(
              likes: rolled,
              comments: v.commentsCount,
              views: v.viewsCount,
              watchCount: v.watchCount,
            ),
          );
        });
      }
    }
  }

  /// إعجاب فقط (لا يُلغي الإعجاب) — يُستخدم مع الـ double tap بأسلوب تيك توك.
  /// يمنع التذبذب في العدّاد عند الضغط المزدوج السريع.
  Future<void> likeOnly(String videoId, {VideoModel? reelContext}) async {
    final basis = _findReel(videoId) ?? reelContext;
    if (basis == null) return;
    if (basis.isLikedByCurrentUser) return;
    await toggleLike(videoId, reelContext: basis);
  }

  /// تبديل حفظ الريل في بروفايل المستخدم.
  /// ═══════════════════════════════════════════════════════════════
  /// ‣ يُخزّن في `users/{uid}/savedVideos/{videoId}` مع timestamp
  /// ‣ يُحدّث الكاش المحلي [_savedIds]
  /// ‣ يُحدّث savesCount الإجمالي للريل بشكل atomic
  Future<void> toggleSave(String videoId, {VideoModel? reelContext}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final existing = _findReel(videoId);
    final basis = existing ?? reelContext;
    if (basis == null) return;

    final willBeSaved = !basis.isSavedByCurrentUser;
    final delta = willBeSaved ? 1 : -1;

    if (existing != null) {
      _updateVideoInAllFeeds(videoId, (v) {
        return v.copyWith(
          isSavedByCurrentUser: willBeSaved,
          savesCount: (v.savesCount + delta).clamp(0, 1 << 31),
        );
      });
    }
    if (willBeSaved) {
      _savedIds = {..._savedIds, videoId};
    } else {
      _savedIds = _savedIds.where((id) => id != videoId).toSet();
    }

    try {
      final saveRef = _database.ref('users/$uid/savedVideos/$videoId');
      if (willBeSaved) {
        await saveRef.set({
          'timestamp': ServerValue.timestamp,
          'videoId': videoId,
        });
      } else {
        await saveRef.remove();
      }
      await _database
          .ref('${AppConfig.rtdbReelsPath}/$videoId/savesCount')
          .set(ServerValue.increment(delta));
    } catch (e) {
      debugPrint('ReelsFeedCubit: toggleSave error -> $e');
      if (existing != null) {
        _updateVideoInAllFeeds(videoId, (v) {
          return v.copyWith(
            isSavedByCurrentUser: !willBeSaved,
            savesCount: (v.savesCount - delta).clamp(0, 1 << 31),
          );
        });
      }
      if (willBeSaved) {
        _savedIds = _savedIds.where((id) => id != videoId).toSet();
      } else {
        _savedIds = {..._savedIds, videoId};
      }
    }
  }

  /// تعديل نموذج ريل في كلا الفيدين (إن وُجد فيهما) بدفعة emit واحدة.
  void _updateVideoInAllFeeds(
    String videoId,
    VideoModel Function(VideoModel current) mutate,
  ) {
    FeedData? newFor;
    FeedData? newFollow;

    final fIdx = state.forYou.reels.indexWhere((r) => r.id == videoId);
    if (fIdx >= 0) {
      final copy = List<VideoModel>.from(state.forYou.reels);
      copy[fIdx] = mutate(copy[fIdx]);
      newFor = state.forYou.copyWith(reels: copy);
    }

    final fwIdx = state.following.reels.indexWhere((r) => r.id == videoId);
    if (fwIdx >= 0) {
      final copy = List<VideoModel>.from(state.following.reels);
      copy[fwIdx] = mutate(copy[fwIdx]);
      newFollow = state.following.copyWith(reels: copy);
    }

    if (newFor == null && newFollow == null) return;
    emit(state.copyWith(forYou: newFor, following: newFollow));
  }

  /// إضافة ريلز مؤقت إلى قائمة الفيديوهات (بعد رفع ناجح)
  /// يضاف لفيد For You فوراً، ولفيد Following إذا المستخدم الحالي يتابع نفسه
  /// (عادة لا، لكن الريل الخاص بالمستخدم يجب أن يظهر في For You).
  ///
  /// مهم: نحدّث status إلى loaded ونمسح رسالة الخطأ حتى لو كان الفيد في حالة
  /// خطأ من قبل — عشان الريل الجديد يظهر بدل شاشة الخطأ.
  void prependReel(VideoModel reel) {
    if (_ignoredReelIds.contains(reel.id)) return;
    if (!_allowedAudience(reel, forFollowingFeed: false)) return;
    // تفادي تكرار الريل لو وصل من real-time listener + upload معاً
    final forYouIds = state.forYou.reels.map((r) => r.id).toSet();
    final followingIds = state.following.reels.map((r) => r.id).toSet();

    final newForYou = forYouIds.contains(reel.id)
        ? state.forYou
        : state.forYou.copyWith(
            status: ReelsFeedStatus.loaded,
            reels: _personalizeForCurrentUser([reel, ...state.forYou.reels]),
            errorMessage: null,
          );

    // الريل الخاص بالمستخدم نفسه لا نضيفه لـ Following إلا إذا هو نفسه في القائمة
    // (نادر) — لكن لو الريل من مستخدم آخر يتابعه يُضاف تلقائياً.
    final isFollowedAuthor = _followingIds.contains(reel.userId);
    final newFollowing = isFollowedAuthor && !followingIds.contains(reel.id)
        ? state.following.copyWith(
            status: ReelsFeedStatus.loaded,
            reels: _personalizeForCurrentUser([reel, ...state.following.reels]),
            errorMessage: null,
          )
        : state.following;

    emit(state.copyWith(forYou: newForYou, following: newFollowing));
  }

  List<VideoModel> _personalizeForCurrentUser(List<VideoModel> reels) {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _fanMemory == null || reels.length < 2) return reels;
    final seenHints = _fanMemory!.marketplaceKeywords(uid).toSet();
    if (seenHints.isEmpty) return reels;
    final copy = List<VideoModel>.from(reels);
    copy.sort((a, b) {
      final aBoost = seenHints.contains(a.id) ? 1 : 0;
      final bBoost = seenHints.contains(b.id) ? 1 : 0;
      if (aBoost != bBoost) return bBoost.compareTo(aBoost);
      return 0;
    });
    return copy;
  }

  // ══════════════════════════════════════════════════════════════════
  // MARK: Real-time listener
  // ══════════════════════════════════════════════════════════════════

  /// تشغيل مشترك `onChildAdded` على عقدة `/reels` ليلتقط أي ريل جديد فور رفعه
  /// من أي مستخدم في التطبيق. يضمن ظهور الريلز المرفوعة live بدون refresh.
  ///
  /// - نستخدم `limitToLast(1)` عشان ما يرجعش كل الريلز القديمة على مرة واحدة.
  /// - الـ listener idempotent: مفعّل مرة واحدة فقط لكل عمر Cubit.
  void _startNewReelsListener() {
    if (isProfileScopedFeed) return;
    if (_newReelsSub != null) return; // بالفعل مُفعّل
    try {
      _newReelsSub = _database
          .ref(AppConfig.rtdbReelsPath)
          .orderByChild('timestamp')
          .limitToLast(1)
          .onChildAdded
          .listen((event) {
        final raw = event.snapshot.value;
        final key = event.snapshot.key;
        if (raw is! Map || key == null) return;
        try {
          var model = VideoModel.fromJson(
            Map<String, dynamic>.from(raw),
            key,
          );
          if (model.appSource.isEmpty) {
            model = model.copyWith(
              appSource: AppConfig.reelsFirestoreClubTag,
              engagementCount: ReelsAlgorithm.computeEngagementCount(
                likes: model.likesCount,
                comments: model.commentsCount,
                views: model.viewsCount,
                watchCount: model.watchCount,
              ),
            );
          }
          if (model.videoUrl.isEmpty) return;
          if (!_allowedAudience(model, forFollowingFeed: false)) return;
          // لا نضيف ريلز قديمة جاءت في اللقطة الأولى إذا كانت موجودة مسبقاً
          final alreadyExists = state.forYou.reels.any((r) => r.id == model.id);
          if (alreadyExists) return;
          if (_ignoredReelIds.contains(model.id)) return;
          debugPrint('[Realtime] new reel detected: ${model.id}');
          prependReel(model);
        } catch (e) {
          debugPrint('Realtime listener parse error: $e');
        }
      }, onError: (e) {
        debugPrint('Realtime listener error: $e');
      });
    } catch (e) {
      debugPrint('Could not start realtime listener: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // MARK: Emit helpers
  // ══════════════════════════════════════════════════════════════════

  void _emitForYou(FeedData next) => emit(state.copyWith(
        forYou: next.copyWith(reels: _withoutIgnored(next.reels)),
      ));

  void _emitFollowing(FeedData next) => emit(state.copyWith(
        following: next.copyWith(reels: _withoutIgnored(next.reels)),
      ));

  // ══════════════════════════════════════════════════════════════════
  // MARK: Upload flow
  // ══════════════════════════════════════════════════════════════════

  /// رفع ريل جديد:
  /// 1. رفع الفيديو لـ Cloudinary
  /// 2. حفظ الـ metadata في Firebase Realtime Database
  /// 3. إضافة الريل لأعلى القائمة
  Future<VideoModel?> uploadReel({
    required File videoFile,
    required String caption,
    bool isPrivate = false,
    String visibility = 'all',
    String? title,
    void Function(UploadPhase phase)? onPhaseChanged,
    void Function(double overall01)? onUploadProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final trimmedTitle = title?.trim();
    final titleForDb =
        (trimmedTitle != null && trimmedTitle.isNotEmpty) ? trimmedTitle : null;

    try {
      onPhaseChanged?.call(UploadPhase.uploadingVideo);
      onUploadProgress?.call(0.02);
      final videoUrl = await _cloudinary.uploadVideo(
        videoFile,
        onUploadProgress: (p) {
          onUploadProgress?.call(0.02 + p * 0.88);
        },
      );
      if (videoUrl.isEmpty) {
        throw Exception('فشل رفع الفيديو إلى Cloudinary');
      }

      onUploadProgress?.call(0.92);
      onPhaseChanged?.call(UploadPhase.savingToDatabase);
      final thumbnailUrl = _buildThumbnailUrl(videoUrl);

      final userSnap = await _database.ref('users/${user.uid}').get();
      final userData = userSnap.value is Map
          ? Map<dynamic, dynamic>.from(userSnap.value as Map)
          : <dynamic, dynamic>{};

      final displayName = (userData['name']?.toString() ??
          user.displayName ??
          (AppConfig.reelsFirestoreClubTag == 'ahly'
              ? 'مشجع أهلاوي'
              : 'مشجع زملكاوي'));
      final photoUrl =
          (userData['profilePic']?.toString() ?? user.photoURL ?? '');
      final tagList = ReelsHashtagUtils.extractTags(caption.trim());

      final newReelRef = _database.ref(AppConfig.rtdbReelsPath).push();
      final videoId = newReelRef.key!;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final reelData = <String, dynamic>{
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption.trim(),
        if (titleForDb != null) 'title': titleForDb,
        'userId': user.uid,
        'userName': displayName,
        'userProfilePic': photoUrl,
        'timestamp': nowMs,
        'likesCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
        'savesCount': 0,
        'viewsCount': 0,
        'watch_count': 0,
        'hashtags': tagList,
        'totalWatchTime': 0,
        'audioUrl': videoUrl,
        'isPrivate': isPrivate,
        'visibility': visibility,
      };
      await newReelRef.set(reelData);
      await _database.ref('users/${user.uid}/videos/$videoId').set({
        'timestamp': nowMs,
        'videoUrl': videoUrl,
        'isPrivate': isPrivate,
        'visibility': visibility,
      });

      final newReel = VideoModel(
        id: videoId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption.trim(),
        userId: user.uid,
        userName: displayName,
        userProfilePic: photoUrl,
        timestamp: DateTime.fromMillisecondsSinceEpoch(nowMs),
        isPrivate: isPrivate,
        visibility: visibility,
        appSource: AppConfig.reelsFirestoreClubTag,
        audioUrl: videoUrl,
        watchCount: 0,
        engagementCount:
            ReelsAlgorithm.computeEngagementCount(
                likes: 0, comments: 0, views: 0, watchCount: 0),
      );

      await _reelsRemote.upsertFullReelDoc(
        newReel,
        extraFields: titleForDb != null ? {'title': titleForDb} : null,
      );

      onUploadProgress?.call(1.0);
      if (!isPrivate) prependReel(newReel);
      onPhaseChanged?.call(UploadPhase.success);
      return newReel;
    } catch (e) {
      debugPrint('ReelsFeedCubit: uploadReel error -> $e');
      onPhaseChanged?.call(UploadPhase.failed);
      rethrow;
    }
  }

  /// توليد رابط صورة مصغّرة من رابط الفيديو الخاص بـ Cloudinary
  String _buildThumbnailUrl(String videoUrl) {
    try {
      if (!videoUrl.contains('/video/upload/')) return '';
      return videoUrl
          .replaceFirst('/video/upload/', '/video/upload/so_0/')
          .replaceAll(RegExp(r'\.(mp4|mov|webm|avi)$'), '.jpg');
    } catch (_) {
      return '';
    }
  }
}
