import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/user_activity_summary.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';

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

  /// كاش لنشاط المستخدم الحالي — يُجلب مرة عند loadForYou
  /// ويُعاد استخدامه في loadMore لتجنّب إعادة التحميل.
  Map<String, UserActivitySummary> _userActivity = const {};

  /// كاش لقائمة الـ following IDs — يُجلب مرة عند loadFollowing.
  Set<String> _followingIds = const {};

  /// كاش لقائمة الريلز المحفوظة عند المستخدم الحالي — تُجلب مع loadForYou.
  Set<String> _savedIds = const {};

  /// مشترك real-time لعقدة `/reels` — يلتقط أي ريل جديد يُرفع من أي مستخدم
  /// ويضيفه تلقائياً لفيد For You (وكذلك Following لو صاحب الريل مُتابَع).
  StreamSubscription<DatabaseEvent>? _newReelsSub;

  ReelsFeedCubit({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    CloudinaryService? cloudinary,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _cloudinary = cloudinary ?? CloudinaryService(),
        super(const ReelsFeedState());

  @override
  Future<void> close() {
    _newReelsSub?.cancel();
    return super.close();
  }

  /// عدد الريلز التي يتم تحميلها في كل دفعة
  static const int _pageSize = 20;

  /// لـ Following: نجلب دفعة أكبر للـ filter client-side لأن ممكن ريلز
  /// كتير لمستخدمين مش بنتابعهم تقع في الدفعة.
  static const int _followingFetchMultiplier = 5;

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

  /// تحميل فيد "For You" (الصفحة الأولى).
  /// ═══════════════════════════════════════════════════════════════
  /// يقوم بجلب:
  ///   1) آخر [_pageSize] ريل من `/reels`
  ///   2) نشاط المستخدم الحالي من `/user_activity/{uid}`
  /// ═══════════════════════════════════════════════════════════════
  /// الطلبان يتمّان بالتوازي عبر [Future.wait] لتقليل latency،
  /// ثم يتم حساب personalScore وترتيب القائمة محلياً (O(n log n)).
  Future<void> loadForYou() async {
    _emitForYou(state.forYou.copyWith(
      status: ReelsFeedStatus.loading,
      hasReachedEnd: false,
    ));
    try {
      final uid = _auth.currentUser?.uid;

      // المحاولة الأساسية: orderByChild('timestamp') + limitToLast
      // ═══════════════════════════════════════════════════════════
      // لو في index على timestamp → سريع جداً، الـ DB يفلتر server-side.
      // لو فشلت (مثلاً لعدم وجود .indexOn) → نحاول fallback بدون ترتيب server-side.
      DataSnapshot reelsSnapshot;
      try {
        final results = await Future.wait<Object?>([
          _database
              .ref('reels')
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

      // لا توجد ريلز في قاعدة البيانات → نعرض حالة فارغة بدلاً من ريلز عشوائية
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

      final videos = _parseReelsSnapshot(reelsSnapshot.value);
      // نضمن الترتيب النهائي حتى لو جينا من fallback
      _sortByTimestampDesc(videos);
      // نأخذ أحدث _pageSize فقط (في حالة fallback رجع الكل)
      final trimmed =
          videos.length > _pageSize ? videos.sublist(0, _pageSize) : videos;
      _rankSortPersonalized(trimmed);

      _emitForYou(state.forYou.copyWith(
        status: ReelsFeedStatus.loaded,
        reels: trimmed,
        hasReachedEnd: trimmed.length < _pageSize,
        errorMessage: trimmed.isEmpty
            ? 'لا توجد ريلز حالياً — كن أول من ينشر!'
            : null,
      ));

      // بعد أول تحميل ناجح، نشغّل الـ real-time listener لالتقاط الريلز الجديدة.
      _startNewReelsListener();
    } catch (e) {
      debugPrint('ReelsFeedCubit: loadForYou error -> $e');
      // لو كان فيه ريلز محفوظة محلياً من قبل، نحافظ عليها بدل مسحها
      final existing = state.forYou.reels;
      _emitForYou(state.forYou.copyWith(
        status: existing.isEmpty
            ? ReelsFeedStatus.error
            : ReelsFeedStatus.loaded,
        reels: existing,
        errorMessage: existing.isEmpty
            ? 'تعذّر تحميل الريلز — تأكد من اتصالك بالإنترنت'
            : null,
        hasReachedEnd: existing.isEmpty,
      ));
    }
  }

  /// Fallback لجلب الريلز بدون orderByChild (في حالة عدم وجود index على timestamp
  /// أو وجود مشكلة بصلاحيات الاستعلامات). نجلب الكل ثم نرتّب client-side.
  Future<DataSnapshot> _loadReelsFallback() async {
    return _database
        .ref('reels')
        .get()
        .timeout(const Duration(seconds: 20));
  }

  Future<void> _loadMoreForYou() async {
    final feed = state.forYou;
    if (feed.isLoadingMore || feed.hasReachedEnd || feed.reels.isEmpty) return;

    _emitForYou(feed.copyWith(isLoadingMore: true));
    try {
      final oldest = feed.reels.last.timestamp.millisecondsSinceEpoch;
      debugPrint('[Cubit] loadMoreForYou: cursor=$oldest');

      final snapshot = await _database
          .ref('reels')
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

      final more = _parseReelsSnapshot(snapshot.value);
      if (more.isEmpty) {
        _emitForYou(state.forYou.copyWith(
          isLoadingMore: false,
          hasReachedEnd: true,
        ));
        return;
      }

      final existingIds = state.forYou.reels.map((r) => r.id).toSet();
      final unique = more
          .where((r) => !existingIds.contains(r.id))
          .toList(growable: true);

      // ترتيب الدفعة الجديدة personally قبل إلحاقها
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
            .ref('reels')
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

      final all = _parseReelsSnapshot(reelsSnapshot.value);
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
          .ref('reels')
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

      final all = _parseReelsSnapshot(snapshot.value);
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
  List<VideoModel> _parseReelsSnapshot(Object? raw) {
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

          // الريلز الخاصة لا تظهر في الفيد العام (تظهر فقط في تبويب البروفايل لصاحبها)
          if (model.isPrivate) return;

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
  void applyStatsIncrement(
    String videoId, {
    int addedViews = 0,
    int addedSeconds = 0,
  }) {
    if (addedViews == 0 && addedSeconds == 0) return;
    _updateVideoInAllFeeds(videoId, (v) {
      return v.copyWith(
        viewsCount: v.viewsCount + addedViews,
        totalWatchTime: v.totalWatchTime + addedSeconds,
      );
    });
  }

  /// تسجيل تعليق: زيادة commentsCount (atomic) في Firebase + تحديث محلي.
  Future<void> recordComment(String videoId) async {
    _updateVideoInAllFeeds(
      videoId,
      (v) => v.copyWith(commentsCount: v.commentsCount + 1),
    );
    try {
      await _database
          .ref('reels/$videoId/commentsCount')
          .set(ServerValue.increment(1));
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
          .ref('reels/$videoId/sharesCount')
          .set(ServerValue.increment(1));
    } catch (e) {
      debugPrint('[Ranking] recordShare error $videoId: $e');
    }
  }

  /// تبديل إعجاب الفيديو - تحديث تفاؤلي + إرسال لـ Firebase
  Future<void> toggleLike(String videoId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // نستخدم الفيد النشط لتحديد الحالة الحالية (like/unlike)
    final activeList = state.activeFeed.reels;
    final idx = activeList.indexWhere((r) => r.id == videoId);
    if (idx < 0) return;

    final willBeLiked = !activeList[idx].isLikedByCurrentUser;
    final delta = willBeLiked ? 1 : -1;

    _updateVideoInAllFeeds(videoId, (v) {
      return v.copyWith(
        isLikedByCurrentUser: willBeLiked,
        likesCount: (v.likesCount + delta).clamp(0, 1 << 31),
      );
    });

    try {
      final likeRef = _database.ref('reels/$videoId/likes/$userId');
      if (willBeLiked) {
        await likeRef.set(true);
      } else {
        await likeRef.remove();
      }
      await _database
          .ref('reels/$videoId/likesCount')
          .set(ServerValue.increment(delta));
    } catch (e) {
      debugPrint('ReelsFeedCubit: toggleLike error -> $e');
      // تراجع عن التحديث في حال فشل الشبكة
      _updateVideoInAllFeeds(videoId, (v) {
        return v.copyWith(
          isLikedByCurrentUser: !willBeLiked,
          likesCount: (v.likesCount - delta).clamp(0, 1 << 31),
        );
      });
    }
  }

  /// إعجاب فقط (لا يُلغي الإعجاب) — يُستخدم مع الـ double tap بأسلوب تيك توك.
  /// يمنع التذبذب في العدّاد عند الضغط المزدوج السريع.
  Future<void> likeOnly(String videoId) async {
    final active = state.activeFeed.reels;
    final idx = active.indexWhere((r) => r.id == videoId);
    if (idx < 0) return;
    if (active[idx].isLikedByCurrentUser) return; // بالفعل معجب → لا شيء
    await toggleLike(videoId);
  }

  /// تبديل حفظ الريل في بروفايل المستخدم.
  /// ═══════════════════════════════════════════════════════════════
  /// ‣ يُخزّن في `users/{uid}/savedVideos/{videoId}` مع timestamp
  /// ‣ يُحدّث الكاش المحلي [_savedIds]
  /// ‣ يُحدّث savesCount الإجمالي للريل بشكل atomic
  Future<void> toggleSave(String videoId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final active = state.activeFeed.reels;
    final idx = active.indexWhere((r) => r.id == videoId);
    if (idx < 0) return;

    final willBeSaved = !active[idx].isSavedByCurrentUser;
    final delta = willBeSaved ? 1 : -1;

    _updateVideoInAllFeeds(videoId, (v) {
      return v.copyWith(
        isSavedByCurrentUser: willBeSaved,
        savesCount: (v.savesCount + delta).clamp(0, 1 << 31),
      );
    });
    // نحدث الكاش عشان أي إعادة تحميل تاني تفضل consistent
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
          .ref('reels/$videoId/savesCount')
          .set(ServerValue.increment(delta));
    } catch (e) {
      debugPrint('ReelsFeedCubit: toggleSave error -> $e');
      _updateVideoInAllFeeds(videoId, (v) {
        return v.copyWith(
          isSavedByCurrentUser: !willBeSaved,
          savesCount: (v.savesCount - delta).clamp(0, 1 << 31),
        );
      });
      // rollback للكاش
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
    // تفادي تكرار الريل لو وصل من real-time listener + upload معاً
    final forYouIds = state.forYou.reels.map((r) => r.id).toSet();
    final followingIds = state.following.reels.map((r) => r.id).toSet();

    final newForYou = forYouIds.contains(reel.id)
        ? state.forYou
        : state.forYou.copyWith(
            status: ReelsFeedStatus.loaded,
            reels: [reel, ...state.forYou.reels],
            errorMessage: null,
          );

    // الريل الخاص بالمستخدم نفسه لا نضيفه لـ Following إلا إذا هو نفسه في القائمة
    // (نادر) — لكن لو الريل من مستخدم آخر يتابعه يُضاف تلقائياً.
    final isFollowedAuthor = _followingIds.contains(reel.userId);
    final newFollowing = isFollowedAuthor && !followingIds.contains(reel.id)
        ? state.following.copyWith(
            status: ReelsFeedStatus.loaded,
            reels: [reel, ...state.following.reels],
            errorMessage: null,
          )
        : state.following;

    emit(state.copyWith(forYou: newForYou, following: newFollowing));
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
    if (_newReelsSub != null) return; // بالفعل مُفعّل
    try {
      _newReelsSub = _database
          .ref('reels')
          .orderByChild('timestamp')
          .limitToLast(1)
          .onChildAdded
          .listen((event) {
        final raw = event.snapshot.value;
        final key = event.snapshot.key;
        if (raw is! Map || key == null) return;
        try {
          final model = VideoModel.fromJson(
            Map<String, dynamic>.from(raw),
            key,
          );
          if (model.videoUrl.isEmpty) return;
          // لا نضيف ريلز قديمة جاءت في اللقطة الأولى إذا كانت موجودة مسبقاً
          final alreadyExists = state.forYou.reels.any((r) => r.id == model.id);
          if (alreadyExists) return;
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

  void _emitForYou(FeedData next) => emit(state.copyWith(forYou: next));
  void _emitFollowing(FeedData next) => emit(state.copyWith(following: next));

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
    void Function(UploadPhase phase)? onPhaseChanged,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    try {
      onPhaseChanged?.call(UploadPhase.uploadingVideo);
      final videoUrl = await _cloudinary.uploadVideo(videoFile);
      if (videoUrl.isEmpty) {
        throw Exception('فشل رفع الفيديو إلى Cloudinary');
      }

      onPhaseChanged?.call(UploadPhase.savingToDatabase);
      final thumbnailUrl = _buildThumbnailUrl(videoUrl);

      final userSnap = await _database.ref('users/${user.uid}').get();
      final userData = userSnap.value is Map
          ? Map<dynamic, dynamic>.from(userSnap.value as Map)
          : <dynamic, dynamic>{};

      final displayName = (userData['name']?.toString() ??
          user.displayName ??
          'مشجع أهلاوي');
      final photoUrl =
          (userData['profilePic']?.toString() ?? user.photoURL ?? '');

      final newReelRef = _database.ref('reels').push();
      final videoId = newReelRef.key!;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final reelData = <String, dynamic>{
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption.trim(),
        'userId': user.uid,
        'userName': displayName,
        'userProfilePic': photoUrl,
        'timestamp': nowMs,
        'likesCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
        'savesCount': 0,
        'viewsCount': 0,
        'totalWatchTime': 0,
        'isPrivate': isPrivate,
      };
      await newReelRef.set(reelData);
      await _database
          .ref('users/${user.uid}/videos/$videoId')
          .set({'timestamp': nowMs, 'videoUrl': videoUrl, 'isPrivate': isPrivate});

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
      );

      // الريلز الخاصة لا تظهر في الفيد العام
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
