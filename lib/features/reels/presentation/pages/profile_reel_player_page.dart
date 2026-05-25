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
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/audio_trending_page.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/hashtag_reels_page.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/user_profile_view_page.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/providers/video_controller_manager.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/comments_bottom_sheet.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/reels_share_branding_sheet.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/tiktok_reel_tile.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/custom_button.dart';

/// تشغيل ريلز البروفايل بملء الشاشة — نفس تجربة الفيد الرئيسي (صوت، غير مهتم، مشاركة ذكية).
class ProfileReelPlayerPage extends StatefulWidget {
  const ProfileReelPlayerPage({
    super.key,
    required this.reels,
    required this.feedCubit,
    this.initialIndex = 0,
    this.displayName,
  });

  final List<VideoModel> reels;
  final int initialIndex;
  final String? displayName;

  /// يُمرَّر من الشاشة الأم حتى تعمل التفاعلات مع الفيد الرئيسي دون الاعتماد على شجرة الـ Provider فقط.
  final ReelsFeedCubit feedCubit;

  @override
  State<ProfileReelPlayerPage> createState() => _ProfileReelPlayerPageState();
}

class _ProfileReelPlayerPageState extends State<ProfileReelPlayerPage> {
  late final PageController _pageController;
  late final VideoControllerManager _controllerManager;
  late final ReelsRankingService _rankingService;
  late final UserActivityTracker _activityTracker;

  late List<VideoModel> _reels;

  int _currentIndex = 0;
  final Set<String> _followingUsers = {};
  StreamSubscription<DatabaseEvent>? _followingSub;

  String? _lastTrackedId;

  Color get _accent => AppConfig.reelsFirestoreClubTag == 'ahly'
      ? AppColors.royalRed
      : const Color(0xFF00247D);

  /// لون تأكيد الحفظ — أحمر للأهلي، أزرق ملكي للزمالك.
  Color get _saveSnackColor => AppConfig.reelsFirestoreClubTag == 'ahly'
      ? AppColors.royalRed
      : AppColors.royalBlue;

  @override
  void initState() {
    super.initState();
    _reels = List<VideoModel>.from(widget.reels);
    final safeInitial =
        widget.initialIndex.clamp(0, _reels.isEmpty ? 0 : _reels.length - 1);
    _currentIndex = safeInitial;
    _pageController = PageController(initialPage: safeInitial);

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

    if (_reels.isNotEmpty) {
      _controllerManager.setUrls(
        _reels.map((e) => e.videoUrl).toList(growable: false),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controllerManager.setCurrentIndex(_currentIndex);
          _startTrackingCurrent();
        }
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
    unawaited(widget.feedCubit.applyStatsIncrement(
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
      accentColor: _accent,
      onShareComplete: (success) async {
        if (!mounted || !success) return;
        widget.feedCubit.recordShare(reel.id);
        _activityTracker.trackShare(reel.id);
      },
    );
  }

  void _openAudioTrending(VideoModel reel) {
    if (reel.audioTrackKey.isEmpty) return;
    _controllerManager.pauseAll();
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: widget.feedCubit,
          child: AudioTrendingPage(
            audioTrackKey: reel.audioTrackKey,
            soundTitle: reel.audioDisplayLabel,
            accentColor: _accent,
          ),
        ),
      ),
    )
        .then((_) {
      if (mounted) _controllerManager.resumeCurrent();
    });
  }

  void _openHashtagFeed(String normalizedTag) {
    if (normalizedTag.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: widget.feedCubit,
          child: HashtagReelsPage(
            hashtag: normalizedTag,
            accentColor: _accent,
          ),
        ),
      ),
    );
  }

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

  Future<void> _onNotInterested(VideoModel reel) async {
    await widget.feedCubit.markNotInterested(reel.id);
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

  void _handleQualifiedWatch(String videoId) {
    VideoModel? ctxReel;
    for (final r in _reels) {
      if (r.id == videoId) {
        ctxReel = r;
        break;
      }
    }
    unawaited(
      widget.feedCubit.recordQualifiedWatch(
        videoId,
        reelContext: ctxReel,
      ),
    );
  }

  void _mergeReelFromCubitOrFlip(String videoId) {
    final i = _reels.indexWhere((r) => r.id == videoId);
    if (i < 0) return;
    final merged = widget.feedCubit.findReelById(videoId);
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
    final merged = widget.feedCubit.findReelById(videoId);
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
    final merged = widget.feedCubit.findReelById(videoId);
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

  Future<void> _handleSave(VideoModel reel) async {
    final willBeSaved = !reel.isSavedByCurrentUser;
    widget.feedCubit.toggleSave(reel.id, reelContext: reel);
    _mergeSaveFromCubitOrFlip(reel.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        content: Text(
          willBeSaved
              ? 'تم حفظ الريل في محفوظاتك ✨'
              : 'تم إزالة الريل من المحفوظات',
        ),
        backgroundColor: willBeSaved ? _saveSnackColor : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reels.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.displayName ?? ''),
        ),
        body: const Center(
          child:
              Text('لا توجد ريلز', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(parent: PageScrollPhysics()),
            itemCount: _reels.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final reel = _reels[index];
              return TikTokReelTile(
                key: ValueKey('profile_reel_${reel.id}'),
                index: index,
                reel: reel,
                manager: _controllerManager,
                isActive: index == _currentIndex,
                isFollowing: _followingUsers.contains(reel.userId),
                onLike: () async {
                  await widget.feedCubit.toggleLike(reel.id, reelContext: reel);
                  _mergeReelFromCubitOrFlip(reel.id);
                },
                onLikeOnly: () async {
                  await widget.feedCubit.likeOnly(reel.id, reelContext: reel);
                  _mergeLikeOnlyBump(reel.id);
                },
                onComment: () {
                  CommentsBottomSheet.show(
                    context,
                    videoId: reel.id,
                    feedCubit: widget.feedCubit,
                  );
                },
                onShare: () => _shareVideo(reel),
                onSave: () => _handleSave(reel),
                onFollow: () => _toggleFollow(reel.userId),
                onProfileTap: () => _openUserProfile(reel),
                onQualifiedWatch: () => _handleQualifiedWatch(reel.id),
                onHashtagTap: (tag) =>
                    _openHashtagFeed(ReelsHashtagUtils.normalizeTag(tag)),
                onMusicTap: () => _openAudioTrending(reel),
                onVideoLongPress: () => _openReelOptionsMenu(reel),
              );
            },
          ),
          SafeArea(
            child: Row(
              children: [
                CustomIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  semanticsLabel: 'زر الرجوع',
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                if (widget.displayName != null)
                  Expanded(
                    child: Text(
                      widget.displayName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
