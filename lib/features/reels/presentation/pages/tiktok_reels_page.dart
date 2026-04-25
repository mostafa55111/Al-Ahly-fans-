import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/app_shell.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_ranking_service.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/user_activity_tracker.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/cubit/reels_feed_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/upload_reel_page.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/user_profile_view_page.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/providers/video_controller_manager.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/comments_bottom_sheet.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/tiktok_reel_tile.dart';
import 'package:share_plus/share_plus.dart';

/// شاشة الريلز بأسلوب TikTok — Production Grade
///
/// المكونات الأساسية:
/// - Dual feed: For You / Following (تبديل instant بدون إعادة تحميل)
/// - PageView عمودي + [PageController] + tracking للـ index
/// - [VideoControllerManager] مركزي يدير دورة حياة الـ controllers (preload/dispose)
/// - Lazy loading عند الاقتراب من آخر ريل
/// - `AutomaticKeepAliveClientMixin` على كل tile لمنع إعادة بناء الواجهة
class TikTokReelsPage extends StatefulWidget {
  const TikTokReelsPage({super.key});

  @override
  State<TikTokReelsPage> createState() => _TikTokReelsPageState();
}

class _TikTokReelsPageState extends State<TikTokReelsPage>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  late final VideoControllerManager _controllerManager;
  late final ReelsRankingService _rankingService;
  late final UserActivityTracker _activityTracker;

  int _currentIndex = 0;
  final Set<String> _followingUsers = {};
  StreamSubscription<DatabaseEvent>? _followingSub;

  /// threshold: كم ريل متبقي قبل آخر القائمة لتشغيل التحميل الإضافي
  static const int _lazyLoadThreshold = 2;

  /// ID آخر ريل بدأنا تتبّعه — لتفادي بدء التتبع مرتين
  String? _lastTrackedId;

  /// هل صفحة الريلز هي التبويب النشط حالياً؟
  /// يُحدَّث من [didChangeDependencies] عند تغيير التبويب في [AppShell].
  bool _isTabActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController();
    _controllerManager = VideoControllerManager();
    _rankingService = ReelsRankingService(
      database: FirebaseDatabase.instance,
      onFlush: _handleRankingFlushed,
    );
    _activityTracker = UserActivityTracker(
      database: FirebaseDatabase.instance,
      auth: FirebaseAuth.instance,
    );

    _controllerManager.addListener(_onManagerUpdate);
    _listenFollowingUsers();

    // تحميل الفيد الافتراضي (For You)
    context.read<ReelsFeedCubit>().loadReels();
  }

  /// يُستدعى عند تغيّر أي InheritedWidget نعتمد عليه — تحديداً
  /// [AppTabScope] اللي بيعرّفنا على التبويب النشط.
  /// لو المستخدم خرج من شاشة الريلز → نوقف كل الفيديوهات ونفصل الصوت.
  /// لو رجع → نكمّل الفيديو الحالي.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = AppTabScope.of(context) == kReelsTabIndex;
    if (active == _isTabActive) return;
    _isTabActive = active;

    if (active) {
      _controllerManager.resumeCurrent();
      _rankingService.resumeTracking();
      _activityTracker.setPlaying(true);
    } else {
      _controllerManager.pauseAll();
      _rankingService.pauseTracking();
      _activityTracker.setPlaying(false);
      _activityTracker.flush();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controllerManager.removeListener(_onManagerUpdate);
    _followingSub?.cancel();
    _rankingService.dispose();
    _activityTracker.dispose();
    _pageController.dispose();
    _controllerManager.dispose();
    super.dispose();
  }

  /// إيقاف الفيديو عند مغادرة التطبيق (multitasking) واستئنافه عند العودة
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _controllerManager.pauseAll();
        _rankingService.pauseTracking();
        _activityTracker.setPlaying(false);
        _activityTracker.flush();
        break;
      case AppLifecycleState.resumed:
        _controllerManager.resumeCurrent();
        _rankingService.resumeTracking();
        _activityTracker.setPlaying(true);
        break;
      case AppLifecycleState.detached:
        _rankingService.flush();
        _activityTracker.flush();
        break;
    }
  }

  // ========== feed logic ==========

  /// مراقبة حالة الـ player: لو وقف (tap pause) نوقف عدّاد التتبع.
  void _onManagerUpdate() {
    final controller = _controllerManager.controllerFor(_currentIndex);
    if (controller == null || !controller.value.isInitialized) return;
    final isPlaying = controller.value.isPlaying;
    if (isPlaying) {
      _rankingService.resumeTracking();
      _activityTracker.setPlaying(true);
    } else {
      _rankingService.pauseTracking();
      _activityTracker.setPlaying(false);
    }
  }

  /// عند flush ناجح، نحدّث الإحصاءات محلياً في الـ Cubit.
  void _handleRankingFlushed(String videoId, int addedViews, int addedSeconds) {
    if (!mounted) return;
    context.read<ReelsFeedCubit>().applyStatsIncrement(
          videoId,
          addedViews: addedViews,
          addedSeconds: addedSeconds,
        );
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _controllerManager.setCurrentIndex(index);
    _startTrackingCurrent();
    _maybeLoadMore();
  }

  /// بدء تتبّع الريل الحالي (يعمل flush للسابق تلقائياً داخل الخدمة)
  void _startTrackingCurrent() {
    final reels = context.read<ReelsFeedCubit>().state.reels;
    if (_currentIndex < 0 || _currentIndex >= reels.length) return;
    final id = reels[_currentIndex].id;
    if (id == _lastTrackedId) return;
    _lastTrackedId = id;
    _rankingService.startTracking(id);
    _activityTracker.trackViewStart(id);
  }

  void _maybeLoadMore() {
    final cubit = context.read<ReelsFeedCubit>();
    final state = cubit.state;
    if (state.isLoadingMore) return;
    final total = state.reels.length;
    if (total == 0) return;
    if (_currentIndex >= total - _lazyLoadThreshold) {
      debugPrint('[Reels] lazy load triggered @ $_currentIndex / $total');
      cubit.loadMoreReels();
    }
  }

  /// يُحدّث قائمة الروابط في الـ manager كلما تغيّرت قائمة الريلز
  void _syncManagerUrls(List<VideoModel> reels) {
    final urls = reels.map((r) => r.videoUrl).toList(growable: false);
    _controllerManager.setUrls(urls);
    // لو كانت أول مرة نحصل فيها على بيانات، نبدأ تتبع الريل الحالي
    if (_lastTrackedId == null && reels.isNotEmpty) {
      _startTrackingCurrent();
    }
  }

  /// عند التبديل بين الفيدين: reset index + tracking + إعادة PageView لأعلى.
  /// الـ URLs تتحدّث تلقائياً من خلال [_syncManagerUrls] عبر listener منفصل.
  void _onFeedSwitched() {
    _lastTrackedId = null;
    _rankingService.pauseTracking();
    _activityTracker.setPlaying(false);
    _activityTracker.flush();

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    setState(() => _currentIndex = 0);
    _controllerManager.setCurrentIndex(0);
  }

  // ========== UI actions ==========

  /// عرض شاشة التعليقات بأسلوب تيك توك — Bottom Sheet متجاوب
  void _showComments(String videoId) {
    CommentsBottomSheet.show(
      context,
      videoId: videoId,
      feedCubit: context.read<ReelsFeedCubit>(),
    );
  }

  /// مشاركة الريل عبر share_plus — يمنح المستخدم قائمة الخيارات الأصلية.
  /// ═════════════════════════════════════════════════════════════════
  /// نستخدم [Share.shareWithResult] لتتبّع ما إذا كان المستخدم أكمل
  /// المشاركة فعلاً (success) قبل زيادة العدّاد — عشان يبقى صارم.
  Future<void> _shareVideo(VideoModel reel) async {
    final shareText = reel.caption.isNotEmpty
        ? '${reel.caption}\n\n${reel.videoUrl}\n\nشارك من تطبيق جمهور الأهلي 🦅'
        : 'ريل من جمهور الأهلي 🦅\n${reel.videoUrl}';
    try {
      final result = await Share.shareWithResult(
        shareText,
        subject: 'ريل من جمهور الأهلي',
      );
      if (!mounted) return;
      // لا نزيد العدّاد لو المستخدم لغى أو فشلت المشاركة
      if (result.status == ShareResultStatus.success) {
        context.read<ReelsFeedCubit>().recordShare(reel.id);
        _activityTracker.trackShare(reel.id);
      }
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  /// حفظ/إزالة الريل من قسم المحفوظات الخاص بالمستخدم.
  /// يظهر snackbar لتأكيد الإجراء (مريح للمستخدم).
  void _handleSave(VideoModel reel) {
    final willBeSaved = !reel.isSavedByCurrentUser;
    context.read<ReelsFeedCubit>().toggleSave(reel.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        content: Text(
          willBeSaved
              ? 'تم حفظ الريل في محفوظاتك ✨'
              : 'تم إزالة الريل من المحفوظات',
        ),
        backgroundColor:
            willBeSaved ? AppColors.royalRed : Colors.black87,
      ),
    );
  }

  void _handleLike(VideoModel reel) {
    final willBeLiked = !reel.isLikedByCurrentUser;
    context.read<ReelsFeedCubit>().toggleLike(reel.id);
    _activityTracker.trackLike(reel.id, willBeLiked);
  }

  /// double tap = إعجاب فقط (ما يُلغيش الإعجاب).
  void _handleLikeOnly(VideoModel reel) {
    if (reel.isLikedByCurrentUser) return;
    context.read<ReelsFeedCubit>().likeOnly(reel.id);
    _activityTracker.trackLike(reel.id, true);
  }

  void _handleComment(String videoId) {
    // فتح الـ bottom sheet فقط — العدّاد يزداد داخله عند إرسال تعليق فعلي
    _activityTracker.trackComment(videoId);
    _showComments(videoId);
  }

  void _toggleFollow(String userId) {
    _toggleFollowInDatabase(userId);
  }

  void _listenFollowingUsers() {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    _followingSub = FirebaseDatabase.instance.ref('follows/$me').onValue.listen((event) {
      final raw = event.snapshot.value;
      final ids = <String>{};
      if (raw is Map) {
        final data = Map<dynamic, dynamic>.from(raw);
        for (final key in data.keys) {
          ids.add(key.toString());
        }
      }
      if (!mounted) return;
      setState(() {
        _followingUsers
          ..clear()
          ..addAll(ids);
      });
    });
  }

  Future<void> _toggleFollowInDatabase(String targetUserId) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null || me == targetUserId) return;
    final isFollowing = _followingUsers.contains(targetUserId);
    final myFollowingRef = FirebaseDatabase.instance.ref('follows/$me/$targetUserId');
    final targetFollowersRef = FirebaseDatabase.instance.ref('followers/$targetUserId/$me');
    try {
      if (isFollowing) {
        await myFollowingRef.remove();
        await targetFollowersRef.remove();
      } else {
        await myFollowingRef.set({'ts': ServerValue.timestamp});
        await targetFollowersRef.set({'ts': ServerValue.timestamp});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث المتابعة: $e')),
      );
    }
  }

  /// فتح بروفايل صاحب الريل (وضع عرض فقط لمستخدم آخر).
  void _openUserProfile(VideoModel reel) {
    _controllerManager.pauseAll();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UserProfileViewPage(
          userId: reel.userId,
          fallbackName: reel.userName,
          fallbackAvatar: reel.userProfilePic,
        ),
      ),
    ).then((_) {
      if (mounted) _controllerManager.resumeCurrent();
    });
  }

  void _toggleMute() => _controllerManager.setMuted(!_controllerManager.isMuted);

  /// فتح شاشة اختيار الريل — الشاشة ترجع `UploadReelRequest`، والرفع نفسه
  /// يتم في الخلفية هنا ثم نعرض SnackBar (أخضر للنجاح / أحمر للفشل).
  Future<void> _openUploadScreen() async {
    final cubit = context.read<ReelsFeedCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    _controllerManager.pauseAll();
    await _rankingService.flush();
    await _activityTracker.flush();
    _lastTrackedId = null;

    final request = await navigator.push<UploadReelRequest>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const UploadReelPage(),
        ),
      ),
    );

    if (!mounted) return;
    _controllerManager.resumeCurrent();
    _startTrackingCurrent();

    if (request == null) return; // المستخدم لغى

    // إشعار خفيف أن الرفع بدأ (اختياري، معلومة للمستخدم)
    messenger.showSnackBar(
      const SnackBar(
        duration: Duration(milliseconds: 1400),
        content: Text('جاري رفع الريل في الخلفية…'),
        backgroundColor: Colors.black87,
      ),
    );

    // الرفع في الخلفية — المستخدم حر يتصفح التطبيق
    _backgroundUpload(cubit, request, messenger);
  }

  /// تنفيذ الرفع دون بلوك الـ UI + إظهار تنبيه نتيجة (أخضر/أحمر).
  Future<void> _backgroundUpload(
    ReelsFeedCubit cubit,
    UploadReelRequest req,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      await cubit.uploadReel(
        videoFile: req.videoFile,
        caption: req.caption,
        isPrivate: req.isPrivate,
      );
      if (!mounted) return;
      // انتقل لأول ريل فقط لو الريل عام (مش خاص)
      if (!req.isPrivate && _pageController.hasClients) {
        _pageController.jumpToPage(0);
        setState(() => _currentIndex = 0);
      }
      messenger.showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('تم رفع الريل بنجاح 🎉')),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint('Background upload failed: $e');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Row(
            children: const [
              Icon(Icons.error_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('فشل رفع الريل — حاول مرة أخرى')),
            ],
          ),
          backgroundColor: AppColors.brightRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MultiBlocListener(
        listeners: [
          // 1) يُحدّث الـ VideoControllerManager كلما تغيّرت URLs الفيد النشط.
          //    listenWhen يقارن URLs فقط → لا setUrls غير ضروري.
          BlocListener<ReelsFeedCubit, ReelsFeedState>(
            listenWhen: (prev, curr) => !listEquals(
              prev.reels.map((e) => e.videoUrl).toList(),
              curr.reels.map((e) => e.videoUrl).toList(),
            ),
            listener: (context, state) => _syncManagerUrls(state.reels),
          ),

          // 2) يتعامل مع تبديل الفيد (reset page + index + tracking).
          BlocListener<ReelsFeedCubit, ReelsFeedState>(
            listenWhen: (p, c) => p.currentFeed != c.currentFeed,
            listener: (ctx, state) => _onFeedSwitched(),
          ),
        ],
        child: Stack(
          children: [
            // محتوى الفيد — يُعاد بناؤه فقط عند تغيّر الفيد النشط أو reels
            Positioned.fill(
              child: BlocBuilder<ReelsFeedCubit, ReelsFeedState>(
                // نعيد البناء فقط لو تغيّر الفيد النشط أو بيانات الفيد النشط
                buildWhen: (p, c) =>
                    p.currentFeed != c.currentFeed ||
                    p.activeFeed != c.activeFeed,
                builder: (context, state) => _buildContent(state),
              ),
            ),

            // شريط التابات — يُبنى مرة واحدة ويرسم نفسه فقط على تغيّر FeedType
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(bottom: false, child: _FeedTabsBar()),
            ),

            // زر رفع الريل
            Positioned(
              top: 0,
              right: 14,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _UploadReelButton(onTap: _openUploadScreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ReelsFeedState state) {
    final feed = state.activeFeed;

    if (feed.status == ReelsFeedStatus.loading ||
        feed.status == ReelsFeedStatus.initial) {
      return const _LoadingView();
    }
    if (feed.status == ReelsFeedStatus.error && feed.reels.isEmpty) {
      return _ErrorView(
        message: feed.errorMessage ?? 'حدث خطأ',
        onRetry: () =>
            context.read<ReelsFeedCubit>().switchFeed(state.currentFeed, forceReload: true),
      );
    }
    if (feed.reels.isEmpty) {
      return _EmptyView(
        message: feed.errorMessage ??
            (state.currentFeed == FeedType.following
                ? 'تابع مبدعين لتشاهد فيدك الشخصي هنا'
                : 'لا توجد ريلز حالياً'),
      );
    }

    return RefreshIndicator(
      color: AppColors.royalRed,
      backgroundColor: Colors.black,
      onRefresh: () => context
          .read<ReelsFeedCubit>()
          .switchFeed(state.currentFeed, forceReload: true),
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const PageScrollPhysics().applyTo(
          const ClampingScrollPhysics(),
        ),
        itemCount: feed.reels.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final reel = feed.reels[index];
          return TikTokReelTile(
            // المفتاح يتضمن نوع الفيد لضمان إعادة بناء صحيحة عند التبديل
            key: ValueKey('${state.currentFeed.name}_${reel.id}'),
            index: index,
            reel: reel,
            manager: _controllerManager,
            isActive: index == _currentIndex,
            isFollowing: _followingUsers.contains(reel.userId),
            onLike: () => _handleLike(reel),
            onLikeOnly: () => _handleLikeOnly(reel),
            onComment: () => _handleComment(reel.id),
            onShare: () => _shareVideo(reel),
            onSave: () => _handleSave(reel),
            onFollow: () => _toggleFollow(reel.userId),
            onProfileTap: () => _openUserProfile(reel),
            onToggleMute: _toggleMute,
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: شريط تابات Following / For You (يُرسم بشكل مستقل)
// ═══════════════════════════════════════════════════════════════════

/// شريط التابات العلوي — يستخدم [BlocSelector] لإعادة البناء فقط
/// عند تغيير [FeedType] (لا يتأثر بتحديثات الريلز/الإحصاءات).
class _FeedTabsBar extends StatelessWidget {
  const _FeedTabsBar();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ReelsFeedCubit, ReelsFeedState, FeedType>(
      selector: (state) => state.currentFeed,
      builder: (context, currentFeed) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TabItem(
                label: 'المتابَعون',
                active: currentFeed == FeedType.following,
                onTap: () => context
                    .read<ReelsFeedCubit>()
                    .switchFeed(FeedType.following),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 14,
                color: Colors.white24,
              ),
              const SizedBox(width: 8),
              _TabItem(
                label: 'لك',
                active: currentFeed == FeedType.forYou,
                onTap: () => context
                    .read<ReelsFeedCubit>()
                    .switchFeed(FeedType.forYou),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.65),
                fontSize: active ? 16 : 15,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                shadows: active
                    ? const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 2,
              width: active ? 22 : 0,
              decoration: BoxDecoration(
                color: AppColors.luminousGold,
                borderRadius: BorderRadius.circular(2),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color:
                              AppColors.luminousGold.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: helper widgets
// ═══════════════════════════════════════════════════════════════════

/// زر الرفع (+) — التصميم الأحمر الملكي مع حدود ذهبية
class _UploadReelButton extends StatelessWidget {
  final VoidCallback onTap;

  const _UploadReelButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.royalRed, AppColors.darkRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.luminousGold.withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.royalRed.withValues(alpha: 0.5),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: SizedBox(
          width: 38,
          height: 38,
          child: CircularProgressIndicator(
            color: AppColors.royalRed,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({this.message = 'لا توجد ريلز حالياً'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined,
                color: Colors.white24, size: 70),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.royalRed, size: 60),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
