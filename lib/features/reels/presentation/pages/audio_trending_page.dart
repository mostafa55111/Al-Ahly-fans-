import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/core/services/social_graph_service.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_hashtag_utils.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_ranking_service.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/user_activity_tracker.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/cubit/reels_feed_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/hashtag_reels_page.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/user_profile_view_page.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/providers/video_controller_manager.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/comments_bottom_sheet.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/reels_feed_skeleton.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/reels_share_branding_sheet.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/tiktok_reel_tile.dart';

/// صفحة كل الريلز التي تشترك في نفس مصدر الصوت، مرتبة حسب الـ score.
class AudioTrendingPage extends StatefulWidget {
  const AudioTrendingPage({
    super.key,
    required this.audioTrackKey,
    required this.soundTitle,
    required this.accentColor,
  });

  final String audioTrackKey;
  final String soundTitle;
  final Color accentColor;

  @override
  State<AudioTrendingPage> createState() => _AudioTrendingPageState();
}

class _AudioTrendingPageState extends State<AudioTrendingPage> {
  final PageController _pageController = PageController();
  late final VideoControllerManager _controllerManager;
  late final ReelsRankingService _rankingService;
  late final UserActivityTracker _activityTracker;

  List<VideoModel> _reels = [];
  bool _loading = true;
  String? _error;

  int _currentIndex = 0;
  final Set<String> _followingUsers = {};
  StreamSubscription<DatabaseEvent>? _followingSub;

  String? _lastTrackedId;

  @override
  void initState() {
    super.initState();
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
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final list = await context
          .read<ReelsFeedCubit>()
          .fetchReelsForAudioUrl(widget.audioTrackKey);
      if (!mounted) return;
      setState(() {
        _reels = list;
        _loading = false;
        _error =
            list.isEmpty ? 'لا توجد ريلز بهذا الصوت بعد على Firestore' : null;
      });
      _controllerManager.setUrls(list.map((e) => e.videoUrl).toList(growable: false));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startTrackingCurrent();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'تعذّر تحميل الصوت — تحقق من الفهارس أو الاتصال\n$e';
      });
    }
  }

  void _listenFollowingUsers() {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    _followingSub =
        FirebaseDatabase.instance.ref('follows/$me').onValue.listen((event) {
      final raw = event.snapshot.value;
      final ids = <String>{};
      if (raw is Map) {
        for (final key in raw.keys) {
          ids.add(key.toString());
        }
      }
      if (!mounted) return;
      setState(() => _followingUsers
        ..clear()
        ..addAll(ids));
    });
  }

  void _onManagerUpdate() {
    final controller = _controllerManager.controllerFor(_currentIndex);
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      _rankingService.resumeTracking();
      _activityTracker.setPlaying(true);
    } else {
      _rankingService.pauseTracking();
      _activityTracker.setPlaying(false);
    }
  }

  void _handleRankingFlushed(String videoId, int addedViews, int addedSeconds) {
    if (!mounted) return;
    unawaited(context.read<ReelsFeedCubit>().applyStatsIncrement(
          videoId,
          addedViews: addedViews,
          addedSeconds: addedSeconds,
        ));
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _controllerManager.setCurrentIndex(index);
    _startTrackingCurrent();
  }

  void _startTrackingCurrent() {
    if (_currentIndex < 0 || _currentIndex >= _reels.length) return;
    final id = _reels[_currentIndex].id;
    if (id == _lastTrackedId) return;
    _lastTrackedId = id;
    _rankingService.startTracking(id);
    _activityTracker.trackViewStart(id);
  }

  @override
  void dispose() {
    _followingSub?.cancel();
    _controllerManager.removeListener(_onManagerUpdate);
    _rankingService.dispose();
    _activityTracker.dispose();
    _pageController.dispose();
    _controllerManager.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow(String targetUserId) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null || me == targetUserId) return;
    final isFollowing = _followingUsers.contains(targetUserId);
    try {
      if (isFollowing) {
        await SocialGraphService.unfollowUser(targetUserId);
      } else {
        await SocialGraphService.followUser(targetUserId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث المتابعة: $e')),
      );
    }
  }

  void _openUserProfile(VideoModel reel) {
    _controllerManager.pauseAll();
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => UserProfileViewPage(
          userId: reel.userId,
          fallbackName: reel.userName,
          fallbackAvatar: reel.userProfilePic,
        ),
      ),
    )
        .then((_) {
      if (mounted) _controllerManager.resumeCurrent();
    });
  }

  Future<void> _shareVideo(VideoModel reel) async {
    await ReelsShareBrandingSheet.show(
      context,
      reel: reel,
      accentColor: widget.accentColor,
      onShareComplete: (success) async {
        if (!mounted || !success) return;
        context.read<ReelsFeedCubit>().recordShare(reel.id);
        _activityTracker.trackShare(reel.id);
      },
    );
  }

  /// قائمة سريعة على الضغط المطوّل — مطابقة لتجربة الهاشتاج والفيد الرئيسي.
  void _openReelOptionsMenu(VideoModel reel) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.not_interested_rounded,
                  color: Colors.white70),
              title: const Text(
                'غير مهتم',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_onNotInterested(reel));
              },
            ),
          ],
        ),
      ),
    );
  }

  /// إخفاء الريل محلياً وتخطّيه فوراً؛ لو انفرغت القائمة نخرج من صفحة الصوت.
  Future<void> _onNotInterested(VideoModel reel) async {
    await context.read<ReelsFeedCubit>().markNotInterested(reel.id);
    if (!mounted) return;
    final idxBefore = _currentIndex;
    setState(() {
      _reels.removeWhere((r) => r.id == reel.id);
    });
    if (_reels.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    var nextIdx = idxBefore;
    if (idxBefore >= _reels.length) {
      nextIdx = _reels.length - 1;
    }
    _controllerManager.setUrls(_reels.map((e) => e.videoUrl).toList());
    if (_pageController.hasClients) {
      _pageController.jumpToPage(nextIdx);
    }
    setState(() => _currentIndex = nextIdx);
    _controllerManager.setCurrentIndex(nextIdx);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startTrackingCurrent();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لن نعرض هذا الريل مرة أخرى على هذا الجهاز'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _openHashtagFeed(String normalizedTag) {
    if (normalizedTag.isEmpty) return;
    const accent = AppConfig.reelsFirestoreClubTag == 'ahly'
        ? AppColors.royalRed
        : Color(0xFF00247D);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<ReelsFeedCubit>(),
          child: HashtagReelsPage(
            hashtag: normalizedTag,
            accentColor: accent,
          ),
        ),
      ),
    );
  }

  void _handleQualifiedWatch(String videoId) {
    VideoModel? ctxReel;
    for (final r in _reels) {
      if (r.id == videoId) {
        ctxReel = r;
        break;
      }
    }
    unawaited(
      context.read<ReelsFeedCubit>().recordQualifiedWatch(
            videoId,
            reelContext: ctxReel,
          ),
    );
  }

  void _mergeReelFromCubitOrFlip(String videoId) {
    final i = _reels.indexWhere((r) => r.id == videoId);
    if (i < 0) return;
    final merged = context.read<ReelsFeedCubit>().findReelById(videoId);
    if (merged != null) {
      setState(() => _reels[i] = merged);
      return;
    }
    final r = _reels[i];
    setState(() {
      _reels[i] = r.copyWith(
        isLikedByCurrentUser: !r.isLikedByCurrentUser,
        likesCount:
            (r.likesCount + (r.isLikedByCurrentUser ? -1 : 1)).clamp(0, 1 << 31),
      );
    });
  }

  void _mergeSaveFromCubitOrFlip(String videoId) {
    final i = _reels.indexWhere((r) => r.id == videoId);
    if (i < 0) return;
    final merged = context.read<ReelsFeedCubit>().findReelById(videoId);
    if (merged != null) {
      setState(() => _reels[i] = merged);
      return;
    }
    final r = _reels[i];
    setState(() {
      _reels[i] = r.copyWith(
        isSavedByCurrentUser: !r.isSavedByCurrentUser,
        savesCount:
            (r.savesCount + (r.isSavedByCurrentUser ? -1 : 1)).clamp(0, 1 << 31),
      );
    });
  }

  void _mergeLikeOnlyBump(String videoId) {
    final i = _reels.indexWhere((r) => r.id == videoId);
    if (i < 0) return;
    final merged = context.read<ReelsFeedCubit>().findReelById(videoId);
    if (merged != null) {
      setState(() => _reels[i] = merged);
      return;
    }
    final r = _reels[i];
    if (r.isLikedByCurrentUser) return;
    setState(() {
      _reels[i] = r.copyWith(
        isLikedByCurrentUser: true,
        likesCount: (r.likesCount + 1).clamp(0, 1 << 31),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.soundTitle,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: widget.accentColor.withValues(alpha: 0.4),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? ReelsFeedSkeleton(accentColor: widget.accentColor)
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const PageScrollPhysics()
                      .applyTo(const ClampingScrollPhysics()),
                  itemCount: _reels.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final reel = _reels[index];
                    return TikTokReelTile(
                      key: ValueKey('audio_${reel.id}'),
                      index: index,
                      reel: reel,
                      manager: _controllerManager,
                      isActive: index == _currentIndex,
                      isFollowing: _followingUsers.contains(reel.userId),
                      onLike: () async {
                        await context.read<ReelsFeedCubit>().toggleLike(
                              reel.id,
                              reelContext: reel,
                            );
                        _mergeReelFromCubitOrFlip(reel.id);
                      },
                      onLikeOnly: () async {
                        await context.read<ReelsFeedCubit>().likeOnly(
                              reel.id,
                              reelContext: reel,
                            );
                        _mergeLikeOnlyBump(reel.id);
                      },
                      onComment: () {
                        CommentsBottomSheet.show(
                          context,
                          videoId: reel.id,
                          feedCubit: context.read<ReelsFeedCubit>(),
                        );
                      },
                      onShare: () => _shareVideo(reel),
                      onSave: () async {
                        await context.read<ReelsFeedCubit>().toggleSave(
                              reel.id,
                              reelContext: reel,
                            );
                        _mergeSaveFromCubitOrFlip(reel.id);
                      },
                      onFollow: () => _toggleFollow(reel.userId),
                      onProfileTap: () => _openUserProfile(reel),
                      onQualifiedWatch: () => _handleQualifiedWatch(reel.id),
                      onHashtagTap: (tag) =>
                          _openHashtagFeed(ReelsHashtagUtils.normalizeTag(tag)),
                      // داخل صفحة الصوت لا نفتح صفحة صوت متداخلة — شريط الصوت للعرض فقط
                      onMusicTap: null,
                      onVideoLongPress: () => _openReelOptionsMenu(reel),
                    );
                  },
                ),
    );
  }
}
