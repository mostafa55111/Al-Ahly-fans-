// شاشة الريلز: تغذية عمودية، Cloudinary + Firebase، بحث محلي.
import 'dart:async';
import 'dart:io';

import 'package:animate_do/animate_do.dart' show FadeIn, ZoomIn;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/core/utils/reels_search_utils.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/reel_feed_subwidgets.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/reels_feed_theme.dart';

/// خدمة واحدة لمعاينة شبكة فيديوهات المؤلف (أسفل Screen).
final CloudinaryService _reelsCloudinarySingleton = CloudinaryService();

/// شاشة ريلز بأسلوب TikTok: تمرير عمودي، تبويب لك / متابعة، إجراءات جانبية، تعليقات، كتم صوت.
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final PageController _pageController = PageController(keepPage: true);
  bool _isUploading = false;

  /// 0 = لك، 1 = أتابعه، 2 = استكشف
  int _feedTab = 0;

  /// فلترة نصية على الوصف، الاسم، المعرّف (كل كلمات الاستعلام يجب أن تظهر).
  String _searchQuery = '';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpReelsToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  /// يُستدعى بعد تغيير التبويب أو البحث لإعادة التمرير لأول ريل.
  void _onFeedOrSearchChanged() => _jumpReelsToStart();

  Future<String?> _askCaption() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ReelsFeedTheme.sheetDark,
        title: const Text('وصف الريل', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'اكتب وصفاً قصيراً...',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(
              ctx,
              controller.text.trim().isEmpty ? null : controller.text.trim(),
            ),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video == null) return;

    if (!mounted) return;
    final caption = await _askCaption();
    if (!mounted) return;
    final finalCaption = (caption == null || caption.isEmpty)
        ? 'فيديو جديد من الجمهور 🦅'
        : caption;

    setState(() => _isUploading = true);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) throw 'يجب تسجيل الدخول أولاً لرفع الريلز';

      final result = await _cloudinaryService.uploadVideo(
        videoFile: File(video.path),
        userId: authUser.uid,
        userName: authUser.displayName ?? 'مشجع أهلاوي',
        caption: finalCaption,
      );
      if (!mounted) return;

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الريل بنجاح! 🦅'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw result?['error'] ?? 'فشل الرفع';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الرفع: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _openReelsSearch() {
    final controller = TextEditingController(text: _searchQuery);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ReelsFeedTheme.sheetDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'البحث في الريلز',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'يتم البحث في الوصف واسم المستخدم ومعرّف الفيديو (كل الكلمات يجب أن تطابق).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'مثال: أهلي #فيديو',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (v) {
                  setState(() => _searchQuery = v.trim());
                  Navigator.pop(ctx);
                  _onFeedOrSearchChanged();
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _searchQuery = '');
                        Navigator.pop(ctx);
                        _onFeedOrSearchChanged();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('مسح البحث'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() => _searchQuery = controller.text.trim());
                        Navigator.pop(ctx);
                        _onFeedOrSearchChanged();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: ReelsFeedTheme.rose,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('تطبيق'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _showLivePlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('البث المباشر قريباً — تابع التطبيق'),
        backgroundColor: Color(0xFF252525),
      ),
    );
  }

  Set<String> _followingIdsFromSnapshot(DataSnapshot? snap) {
    if (snap == null || !snap.exists || snap.value == null) return <String>{};
    final v = snap.value;
    if (v is Map) {
      return v.keys.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  List<Map<String, dynamic>> _filterByFollowing(
    List<Map<String, dynamic>> all,
    Set<String> following,
  ) {
    if (following.isEmpty) return <Map<String, dynamic>>[];
    return all.where((r) => following.contains(r['userId']?.toString())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (uid != null)
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('users/$uid/following').onValue,
              builder: (context, folSnap) {
                final following = _followingIdsFromSnapshot(folSnap.data?.snapshot);
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _cloudinaryService.getReelsStream(),
                  builder: (context, snapshot) {
                    return _buildReelsBody(
                      context: context,
                      snapshot: snapshot,
                      following: following,
                      topPad: topPad,
                    );
                  },
                );
              },
            )
          else
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _cloudinaryService.getReelsStream(),
              builder: (context, snapshot) {
                return _buildReelsBody(
                  context: context,
                  snapshot: snapshot,
                  following: const <String>{},
                  topPad: topPad,
                );
              },
            ),
          if (_isUploading)
            FadeIn(
              child: Container(
                color: Colors.black87,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      SizedBox(height: 20),
                      Text(
                        'جاري رفع الفيديو...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Preset: ahly_video_final',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReelsBody({
    required BuildContext context,
    required AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    required Set<String> following,
    required double topPad,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(
          'خطأ: ${snapshot.error}',
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    var reelsList = List<Map<String, dynamic>>.from(snapshot.data ?? []);
    if (_feedTab == 1) {
      reelsList = _filterByFollowing(reelsList, following);
    } else if (_feedTab == 2) {
      reelsList = reelsList.reversed.toList();
    }

    final afterTabCount = reelsList.length;
    reelsList = filterReelsBySearchQuery(reelsList, _searchQuery);
    final noSearchResults =
        _searchQuery.trim().isNotEmpty && afterTabCount > 0 && reelsList.isEmpty;

    if (reelsList.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    noSearchResults
                        ? Icons.search_off_rounded
                        : _feedTab == 1
                            ? Icons.people_outline
                            : _feedTab == 2
                                ? Icons.explore_outlined
                                : Icons.smart_display_outlined,
                    color: Colors.white38,
                    size: 72,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    noSearchResults
                        ? 'لا نتائج للبحث:\n"$_searchQuery"\nجرّب كلمات أخرى أو امسح البحث من الأعلى.'
                        : _feedTab == 1
                            ? 'تابع مشجعين من بروفايلهم لرؤية ريلزهم هنا.'
                            : _feedTab == 2
                                ? 'لا يوجد محتوى في الاستكشاف بعد.'
                                : 'لا توجد ريلز بعد.\nارفع أول فيديو من زر +',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          _tikTokTopBar(topPad),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
          allowImplicitScrolling: false,
          itemCount: reelsList.length,
          itemBuilder: (context, index) {
            return ReelItem(
              key: ValueKey(reelsList[index]['id'] ?? index),
              reel: reelsList[index],
              activeSearchQuery: _searchQuery,
              onSearchBarTap: _openReelsSearch,
            );
          },
        ),
        _tikTokTopBar(topPad),
      ],
    );
  }

  /// شريط: بحث + تبويبات + رفع + LIVE (ثيم تيك توك).
  Widget _tikTokTopBar(double topPad) {
    return Positioned(
      top: topPad + 4,
      left: 0,
      right: 0,
      child: SizedBox(
        height: ReelsFeedTheme.topBarHeight,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: ReelsFeedTheme.topBarHorizontalInset,
              child: _blurCircleIcon(
                icon: Icons.search_rounded,
                onTap: _openReelsSearch,
              ),
            ),
            Positioned(
              right: ReelsFeedTheme.topBarHorizontalInset,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _blurCircleIcon(
                    icon: Icons.add_box_rounded,
                    onTap: _pickAndUploadVideo,
                  ),
                  const SizedBox(width: 12),
                  _livePillButton(),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                _topTabLabel('لك', 0),
                const SizedBox(width: 20),
                _topTabLabel('أتابعه', 1),
                const SizedBox(width: 20),
                _topTabLabel('استكشف', 2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// زر LIVE في أقصى اليمين كما في TikTok (أيقونة + نص).
  Widget _livePillButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showLivePlaceholder,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withValues(alpha: 0.15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.live_tv_rounded,
                color: Colors.white,
                size: 18,
                shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
              ),
              SizedBox(width: 5),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blurCircleIcon({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.15),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
            shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
          ),
        ),
      ),
    );
  }

  Widget _topTabLabel(String title, int index) {
    final sel = _feedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _feedTab = index;
        });
        _onFeedOrSearchChanged();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: sel ? ReelsFeedTheme.topTabSelected : ReelsFeedTheme.topTabUnselected,
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: sel ? 3 : 0,
            width: sel ? 32 : 0,
            decoration: BoxDecoration(
              color: sel ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class ReelItem extends StatefulWidget {
  final Map<String, dynamic> reel;
  /// عند التصفية بالبحث يُعرض في الشريط السفلي.
  final String activeSearchQuery;
  final VoidCallback? onSearchBarTap;

  const ReelItem({
    super.key,
    required this.reel,
    this.activeSearchQuery = '',
    this.onSearchBarTap,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showPauseIcon = false;
  bool _isLiked = false;
  bool _showHeart = false;
  bool _muted = false;
  bool _isBookmarked = false;

  late int _likesCount;
  late int _commentsCount;
  late int _sharesCount;
  late int _savesCount;

  StreamSubscription<DatabaseEvent>? _reelSub;
  StreamSubscription<DatabaseEvent>? _likedSub;
  StreamSubscription<DatabaseEvent>? _bookmarkSub;
  late AnimationController _discController;

  @override
  void initState() {
    super.initState();
    _likesCount = _toInt(widget.reel['likes']);
    _commentsCount = _toInt(widget.reel['comments']);
    _sharesCount = _toInt(widget.reel['shares']);
    _savesCount = _toInt(widget.reel['saves']);
    _discController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _initializeVideo();
    _attachRealtimeListeners();
  }

  void _attachRealtimeListeners() {
    final reelId = widget.reel['id']?.toString();
    if (reelId == null || reelId.isEmpty) return;

    _reelSub = FirebaseDatabase.instance.ref('reels/$reelId').onValue.listen((event) {
      final v = event.snapshot.value;
      if (v is Map && mounted) {
        final m = Map<String, dynamic>.from(v);
        setState(() {
          _likesCount = _toInt(m['likes']);
          _commentsCount = _toInt(m['comments']);
          _sharesCount = _toInt(m['shares']);
          _savesCount = _toInt(m['saves']);
        });
      }
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _likedSub = FirebaseDatabase.instance
          .ref('reels/$reelId/likedBy/$uid')
          .onValue
          .listen((event) {
        final liked = event.snapshot.value == true;
        if (mounted) setState(() => _isLiked = liked);
      });

      _bookmarkSub = FirebaseDatabase.instance
          .ref('users/$uid/savedReels/$reelId')
          .onValue
          .listen((event) {
        final saved = event.snapshot.value == true;
        if (mounted) setState(() => _isBookmarked = saved);
      });
    }
  }

  @override
  void dispose() {
    _reelSub?.cancel();
    _likedSub?.cancel();
    _bookmarkSub?.cancel();
    _discController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  /// تهيئة مشغّل الشبكة؛ عند الفشل نُفرّغ الـ controller ونُظهر خلفية + إعادة محاولة.
  void _initializeVideo() {
    final String? videoUrl = widget.reel['videoUrl']?.toString();
    if (videoUrl == null || videoUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    final uri = Uri.tryParse(videoUrl);
    if (uri == null || !uri.hasScheme) {
      setState(() => _hasError = true);
      return;
    }

    final c = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..setLooping(true);
    _controller = c;
    c.initialize().then((_) {
      if (mounted) {
        c.setVolume(_muted ? 0 : 1);
        setState(() => _isInitialized = true);
        c.play();
      }
    }).catchError((Object error) {
      debugPrint('video init error (Cloudinary URL): $error');
      c.dispose();
      if (mounted) {
        setState(() {
          _controller = null;
          _hasError = true;
          _isInitialized = false;
        });
      }
    });
  }

  void _retryVideo() {
    _controller?.dispose();
    _controller = null;
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _isInitialized = false;
    });
    _initializeVideo();
  }

  String get _reelId => widget.reel['id']?.toString() ?? '';

  Future<void> _toggleMute() async {
    if (!_isInitialized || _controller == null) return;
    setState(() => _muted = !_muted);
    await _controller!.setVolume(_muted ? 0 : 1);
  }

  Future<void> _toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سجّل الدخول للإعجاب')),
        );
      }
      return;
    }
    if (_reelId.isEmpty) return;

    final likedRef = FirebaseDatabase.instance.ref('reels/$_reelId/likedBy/$uid');
    final legacyLiked = FirebaseDatabase.instance.ref('Reels/$_reelId/likedBy/$uid');
    final likesRef = FirebaseDatabase.instance.ref('reels/$_reelId/likes');
    final legacyLikes = FirebaseDatabase.instance.ref('Reels/$_reelId/likes');

    final next = !_isLiked;
    setState(() {
      _isLiked = next;
      _likesCount += next ? 1 : -1;
      if (_likesCount < 0) _likesCount = 0;
      if (next) _showHeart = true;
    });
    if (next) {
      Future.delayed(const Duration(milliseconds: 580), () {
        if (mounted) setState(() => _showHeart = false);
      });
    }

    try {
      if (next) {
        await likedRef.set(true);
        await legacyLiked.set(true);
        await likesRef.set(_likesCount);
        await legacyLikes.set(_likesCount);
      } else {
        await likedRef.remove();
        await legacyLiked.remove();
        await likesRef.set(_likesCount);
        await legacyLikes.set(_likesCount);
      }
    } catch (e) {
      debugPrint('like error: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _reelId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سجّل الدخول لحفظ الريل')),
        );
      }
      return;
    }
    final userRef = FirebaseDatabase.instance.ref('users/$uid/savedReels/$_reelId');
    final savesRef = FirebaseDatabase.instance.ref('reels/$_reelId/saves');
    final legacySaves = FirebaseDatabase.instance.ref('Reels/$_reelId/saves');

    final next = !_isBookmarked;
    setState(() {
      _isBookmarked = next;
      _savesCount += next ? 1 : -1;
      if (_savesCount < 0) _savesCount = 0;
    });

    try {
      if (next) {
        await userRef.set(true);
      } else {
        await userRef.remove();
      }
      await savesRef.set(_savesCount);
      await legacySaves.set(_savesCount);
    } catch (e) {
      debugPrint('bookmark: $e');
    }
  }

  Future<void> _shareReel() async {
    final url = widget.reel['videoUrl']?.toString() ?? '';
    final cap = widget.reel['caption']?.toString() ?? '';
    if (url.isEmpty) return;
    await Share.share('$cap\n$url', subject: 'ريل من جمهور الأهلي');
    if (_reelId.isEmpty) return;
    try {
      _sharesCount += 1;
      await FirebaseDatabase.instance.ref('reels/$_reelId/shares').set(_sharesCount);
      await FirebaseDatabase.instance.ref('Reels/$_reelId/shares').set(_sharesCount);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _openAuthorPreview() {
    final name = widget.reel['userName']?.toString() ?? 'مشجع';
    final authorId = widget.reel['userId']?.toString();
    
    // Navigate to user profile screen instead of showing bottom sheet
    if (authorId != null && authorId.isNotEmpty) {
      // TODO: Implement proper user profile navigation
      // Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: authorId)));
      
      // For now, show a snackbar indicating profile navigation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الانتقال إلى بروفايل $name'),
          backgroundColor: const Color(0xFF252525),
        ),
      );
    } else {
      // Fallback to bottom sheet if no authorId
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF121212),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.45,
            minChildSize: 0.32,
            maxChildSize: 0.92,
            builder: (_, scrollController) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  if (authorId != null && authorId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'معرّف المستخدم',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _reelsCloudinarySingleton.getUserReelsStream(authorId),
                        builder: (context, snap) {
                          final list = snap.data ?? [];
                          if (list.isEmpty) {
                            return const Center(
                              child: Text(
                                'لا فيديوهات بعد',
                                style: TextStyle(color: Colors.white38),
                              ),
                            );
                          }
                          return GridView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              childAspectRatio: 0.68,
                            ),
                            itemCount: list.length,
                            itemBuilder: (c, i) {
                              final r = list[i];
                              final thumb = r['thumbnail']?.toString() ?? '';
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: thumb.isNotEmpty
                                    ? CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover)
                                    : Container(color: const Color(0xFF1A1A1A)),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ] else
                    const Expanded(
                      child: Center(
                        child: Text('لا يوجد ملف للمستخدم', style: TextStyle(color: Colors.white38)),
                      ),
                    ),
                ],
              );
            },
          );
        },
      );
    }
  }

  void _openComments() {
    if (_reelId.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final name = FirebaseAuth.instance.currentUser?.displayName ?? 'مشجع';
    final textController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.58,
          minChildSize: 0.38,
          maxChildSize: 0.95,
          builder: (context, scrollCtrl) {
            final pad = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: pad),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.26),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          '$_commentsCount تعليق',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance.ref('reels/$_reelId/comments').onValue,
                      builder: (context, snap) {
                        if (!snap.hasData || snap.data?.snapshot.value == null) {
                          return ListView(
                            controller: scrollCtrl,
                            children: const [
                              SizedBox(height: 40),
                              Center(
                                child: Text(
                                  'كن أول من يعلّق',
                                  style: TextStyle(color: Colors.white38),
                                ),
                              ),
                            ],
                          );
                        }
                        final v = snap.data!.snapshot.value;
                        final rows = <Map<String, dynamic>>[];
                        if (v is Map) {
                          v.forEach((_, val) {
                            if (val is Map) {
                              rows.add(Map<String, dynamic>.from(val));
                            }
                          });
                        }
                        rows.sort((a, b) {
                          final ca = a['createdAt']?.toString() ?? '';
                          final cb = b['createdAt']?.toString() ?? '';
                          return ca.compareTo(cb);
                        });
                        return ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (context, i) {
                            final m = rows[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                              leading: const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFF2A2A2A),
                                child: Icon(Icons.person, color: Colors.white54, size: 20),
                              ),
                              title: Text(
                                m['userName']?.toString() ?? 'مشجع',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  m['text']?.toString() ?? '',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.25),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (uid != null)
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'أضف تعليقاً...',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF1A1A1A),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: Color(0xFFFE2C55)),
                            onPressed: () async {
                              final t = textController.text.trim();
                              if (t.isEmpty) return;
                              await FirebaseDatabase.instance.ref('reels/$_reelId/comments').push().set({
                                'userId': uid,
                                'userName': name,
                                'text': t,
                                'createdAt': DateTime.now().toIso8601String(),
                              });
                              final countSnap =
                                  await FirebaseDatabase.instance.ref('reels/$_reelId/comments').get();
                              int c = 0;
                              if (countSnap.value is Map) {
                                c = (countSnap.value as Map).length;
                              }
                              await FirebaseDatabase.instance.ref('reels/$_reelId').update({'comments': c});
                              await FirebaseDatabase.instance.ref('Reels/$_reelId').update({'comments': c});
                              textController.clear();
                              if (mounted) setState(() => _commentsCount = c);
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pic = widget.reel['userProfilePic']?.toString() ?? '';
    final userName = widget.reel['userName']?.toString() ?? 'مشجع أهلاوي';
    final caption = widget.reel['caption']?.toString() ?? '';
    // مساحة فوق شريط التنقل السفلي للتطبيق (extendBody: true في MainHomeScreen)
    final systemBottom = MediaQuery.paddingOf(context).bottom;
    const appBottomNavReserve = kBottomNavigationBarHeight + 18;
    const tickerH = 38.0;
    final tickerBottomPad = systemBottom + appBottomNavReserve;
    final contentBottom = tickerBottomPad + tickerH + 10;
    
    final String? fixtureId = widget.reel['fixtureId']?.toString();
    final bool isVotingReel = fixtureId != null && fixtureId.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isInitialized && _controller != null)
          VisibilityDetector(
            key: ValueKey('reel_${widget.reel['id'] ?? widget.reel['videoUrl']}'),
            onVisibilityChanged: (info) {
              if (!_isInitialized || !mounted || _controller == null) return;
              if (info.visibleFraction >= 0.6) {
                if (!_controller!.value.isPlaying) _controller!.play();
                if (!_discController.isAnimating) _discController.repeat();
              } else if (info.visibleFraction < 0.35) {
                if (_controller!.value.isPlaying) _controller!.pause();
                _discController.stop();
              }
            },
            child: GestureDetector(
              onDoubleTap: () {
                if (!_isLiked) {
                  _toggleLike();
                } else {
                  setState(() => _showHeart = true);
                  Future.delayed(const Duration(milliseconds: 580), () {
                    if (mounted) setState(() => _showHeart = false);
                  });
                }
              },
              onTap: () {
                final c = _controller;
                if (c == null) return;
                if (c.value.isPlaying) {
                  c.pause();
                  setState(() => _showPauseIcon = true);
                } else {
                  c.play();
                  setState(() => _showPauseIcon = false);
                }
              },
              child: RepaintBoundary(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            ),
          )
        else
          ReelVideoBackdrop(
            isLoading: !_hasError,
            isError: _hasError,
            thumbnailUrl: widget.reel['thumbnail']?.toString(),
            onRetry: _hasError ? _retryVideo : null,
          ),

        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),
          ),
        ),

        if (isVotingReel)
          EagleOfMatchOverlay(fixtureId: fixtureId),

        if (_showPauseIcon)
          const Center(
            child: Icon(Icons.play_circle_filled, color: Colors.white38, size: 88),
          ),

        if (_showHeart)
          Center(
            child: ZoomIn(
              duration: const Duration(milliseconds: 360),
              curve: Curves.elasticOut,
              child: Icon(
                Icons.favorite_rounded,
                color: ReelsFeedTheme.rose.withValues(alpha: 0.95),
                size: 102,
                shadows: const [
                  Shadow(blurRadius: 16, color: Colors.black87),
                ],
              ),
            ),
          ),

        Positioned(
          right: ReelsFeedTheme.sideActionsRightInset,
          bottom: contentBottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _avatarWithFollow(pic),
              const SizedBox(height: ReelsFeedTheme.sideActionGap),
              ReelLikeActionButton(
                isLiked: _isLiked,
                countLabel: _formatCountAr(_likesCount),
                onTap: _toggleLike,
              ),
              const SizedBox(height: ReelsFeedTheme.sideActionGap),
              TikTokSideActionButton(
                icon: const ReelCommentBubbleIcon(),
                label: _formatCountAr(_commentsCount),
                onTap: _openComments,
              ),
              const SizedBox(height: ReelsFeedTheme.sideActionGap),
              TikTokSideActionButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _isBookmarked
                      ? ReelsFeedTheme.yellowBookmark.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  size: 36,
                  shadows: const [Shadow(blurRadius: 12, color: Colors.black45)],
                ),
                label: _formatCountAr(_savesCount),
                onTap: _toggleBookmark,
              ),
              const SizedBox(height: ReelsFeedTheme.sideActionGap),
              TikTokSideActionButton(
                icon: Icon(
                  Icons.near_me_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 36,
                  shadows: const [Shadow(blurRadius: 12, color: Colors.black45)],
                ),
                label: _formatCountAr(_sharesCount),
                onTap: _shareReel,
              ),
              const SizedBox(height: ReelsFeedTheme.sideActionGap),
              _musicDisc(),
            ],
          ),
        ),

        Positioned(
          bottom: contentBottom,
          left: ReelsFeedTheme.captionLeftInset,
          right: ReelsFeedTheme.captionRightInset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName.replaceAll(' ', '_').toLowerCase(),
                style: ReelsFeedTheme.usernameStyle,
              ),
              if (caption.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  caption,
                  style: ReelsFeedTheme.captionStyle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        Positioned(
          left: 12,
          right: 12,
          bottom: tickerBottomPad,
          height: tickerH,
          child: _soundSearchTicker(
            caption,
            userName,
            widget.activeSearchQuery,
            widget.onSearchBarTap,
          ),
        ),

        // Comment input box above phone buttons
        Positioned(
          left: 16,
          right: 16,
          bottom: tickerBottomPad + tickerH + 8,
          child: _commentInputBox(),
        ),

        if (_isInitialized)
          Positioned(
            right: 10,
            bottom: contentBottom + 128,
            child: _blurMuteButton(),
          ),

        if (_isInitialized)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: false,
              colors: VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white.withValues(alpha: 0.22),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
          ),
        ),
      ],
    );
  }

  Widget _avatarWithFollow(String pic) {
    return SizedBox(
      width: 50,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          GestureDetector(
            onTap: _openAuthorPreview,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFF121212),
                backgroundImage: pic.isNotEmpty && pic != 'null' ? CachedNetworkImageProvider(pic) : null,
                child: pic.isEmpty || pic == 'null'
                    ? const Icon(Icons.person_rounded, color: Colors.white70, size: 28)
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            child: GestureDetector(
              onTap: _toggleFollow,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: ReelsFeedTheme.rose,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFollow() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final authorId = widget.reel['userId']?.toString();
    
    if (uid == null || authorId == null || authorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول للمتابعة')),
      );
      return;
    }
    
    if (uid == authorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن متابعة نفسك')),
      );
      return;
    }
    
    try {
      final followRef = FirebaseDatabase.instance.ref('users/$uid/following/$authorId');
      final followersRef = FirebaseDatabase.instance.ref('users/$authorId/followers/$uid');
      
      final currentFollowStatus = await followRef.get();
      final isCurrentlyFollowing = currentFollowStatus.exists && currentFollowStatus.value == true;
      
      if (isCurrentlyFollowing) {
        // Unfollow
        await followRef.remove();
        await followersRef.remove();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إلغاء متابعة ${widget.reel['userName'] ?? ''}')),
        );
      } else {
        // Follow
        await followRef.set(true);
        await followersRef.set(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم متابعة ${widget.reel['userName'] ?? ''}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في المتابعة: $e')),
      );
    }
  }

  Widget _commentInputBox() {
    final textController = TextEditingController();
    
    return Material(
      color: Colors.transparent,
      child: TextField(
        controller: textController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'أضف تعليقاً...',
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send_rounded, color: Color(0xFFFE2C55), size: 20),
            onPressed: () async {
              final commentText = textController.text.trim();
              if (commentText.isEmpty) return;
              
              final uid = FirebaseAuth.instance.currentUser?.uid;
              final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'مشجع';
              final reelId = widget.reel['id']?.toString();
              
              if (uid == null || reelId == null || reelId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يجب تسجيل الدخول لإضافة تعليق')),
                );
                return;
              }
              
              try {
                await FirebaseDatabase.instance.ref('reels/$reelId/comments').push().set({
                  'userId': uid,
                  'userName': userName,
                  'text': commentText,
                  'createdAt': DateTime.now().toIso8601String(),
                });
                
                // Update comments count
                final countSnap = await FirebaseDatabase.instance.ref('reels/$reelId/comments').get();
                int commentCount = 0;
                if (countSnap.value is Map) {
                  commentCount = (countSnap.value as Map).length;
                }
                await FirebaseDatabase.instance.ref('reels/$reelId').update({'comments': commentCount});
                await FirebaseDatabase.instance.ref('Reels/$reelId').update({'comments': commentCount});
                
                textController.clear();
                if (mounted) setState(() => _commentsCount = commentCount);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إضافة التعليق بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ في إضافة التعليق: $e')),
                );
              }
            },
          ),
        ),
        onSubmitted: (value) async {
          final commentText = value.trim();
          if (commentText.isEmpty) return;
          
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'مشجع';
          final reelId = widget.reel['id']?.toString();
          
          if (uid == null || reelId == null || reelId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('يجب تسجيل الدخول لإضافة تعليق')),
            );
            return;
          }
          
          try {
            await FirebaseDatabase.instance.ref('reels/$reelId/comments').push().set({
              'userId': uid,
              'userName': userName,
              'text': commentText,
              'createdAt': DateTime.now().toIso8601String(),
            });
            
            // Update comments count
            final countSnap = await FirebaseDatabase.instance.ref('reels/$reelId/comments').get();
            int commentCount = 0;
            if (countSnap.value is Map) {
              commentCount = (countSnap.value as Map).length;
            }
            await FirebaseDatabase.instance.ref('reels/$reelId').update({'comments': commentCount});
            await FirebaseDatabase.instance.ref('Reels/$reelId').update({'comments': commentCount});
            
            textController.clear();
            if (mounted) setState(() => _commentsCount = commentCount);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إضافة التعليق بنجاح')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ في إضافة التعليق: $e')),
            );
          }
        },
      ),
    );
  }

  Widget _blurMuteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleMute,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.15),
          ),
          child: Icon(
            _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: Colors.white,
            size: 24,
            shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
          ),
        ),
      ),
    );
  }

  Widget _soundSearchTicker(
    String caption,
    String userName,
    String activeSearchQuery,
    VoidCallback? onSearchBarTap,
  ) {
    final searchActive = activeSearchQuery.trim().isNotEmpty;
    final String line;
    if (searchActive) {
      final s = activeSearchQuery.trim();
      line = s.length > 52 ? '${s.substring(0, 52)}…' : s;
    } else {
      final raw = caption.trim().isNotEmpty
          ? caption.replaceAll('\n', ' ')
          : 'الصوت الأصلي — $userName';
      line = raw.length > 42 ? '${raw.substring(0, 42)}…' : raw;
    }

    final inner = Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.8),
            size: 18,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black45)],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'البحث • $line',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                shadows: const [Shadow(blurRadius: 4, color: Colors.black45)],
              ),
            ),
          ),
          Icon(
            Icons.chevron_left_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            size: 20,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black45)],
          ),
        ],
      ),
    );

    if (onSearchBarTap == null) return inner;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSearchBarTap,
        borderRadius: BorderRadius.circular(4),
        child: inner,
      ),
    );
  }

  Widget _musicDisc() {
    return AnimatedBuilder(
      animation: _discController,
      builder: (_, __) {
        return Transform.rotate(
          angle: _discController.value * 6.28318,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 5,
              ),
              color: Colors.black.withValues(alpha: 0.45),
            ),
            child: Icon(Icons.music_note_rounded, color: Colors.white.withValues(alpha: 0.65), size: 18),
          ),
        );
      },
    );
  }

  /// تنسيق أرقام بأسلوب TikTok العربي (مثل 65.9 ألف)
  String _formatCountAr(int n) {
    if (n >= 1000000) {
      final v = n / 1000000.0;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)} مليون';
    }
    if (n >= 1000) {
      final v = n / 1000.0;
      return '${v.toStringAsFixed(v >= 100 ? 0 : 1)} ألف';
    }
    return '$n';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
