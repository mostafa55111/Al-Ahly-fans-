import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/cubit/reels_feed_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// ═══════════════════════════════════════════════════════════════════
/// شاشة التعليقات بأسلوب تيك توك — مع دعم الـ threading والمرفقات.
/// ═══════════════════════════════════════════════════════════════════
/// المزايا:
/// - تعليقات real-time من Firebase RTDB.
/// - إعجاب صارم لكل تعليق (toggle مع كاونتر من children لا من حقل مخزن).
/// - ردود (threaded replies) — أي مستخدم ممكن يرد على أي تعليق.
/// - إرفاق صورة/فيديو/GIF مع التعليق أو الرد (يُرفع على Cloudinary).
class CommentsBottomSheet extends StatefulWidget {
  final String videoId;

  /// Cubit الريلز — يُستخدم لتحديث العداد محلياً بعد إضافة تعليق
  final ReelsFeedCubit feedCubit;

  const CommentsBottomSheet({
    super.key,
    required this.videoId,
    required this.feedCubit,
  });

  /// دالة عرض جاهزة مع إعدادات responsive
  static Future<void> show(
    BuildContext context, {
    required String videoId,
    required ReelsFeedCubit feedCubit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => CommentsBottomSheet(
        videoId: videoId,
        feedCubit: feedCubit,
      ),
    );
  }

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  late final DatabaseReference _commentsRef;
  late final TextEditingController _inputController;
  late final FocusNode _inputFocus;
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();

  /// قائمة التعليقات مرتّبة من الأحدث للأقدم
  final List<_CommentData> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  /// تخزين بيانات المستخدمين التي تم جلبها لتجنّب الطلبات المتكررة
  final Map<String, _UserProfile> _userCache = {};

  /// التعليق اللي بنرد عليه حالياً (null = تعليق عادي جديد)
  _CommentData? _replyingTo;

  /// مرفق مختار (قبل الرفع)
  File? _pickedAttachment;
  _AttachmentKind? _pickedKind;
  bool _isUploadingAttachment = false;

  StreamSubscription<DatabaseEvent>? _childAddedSub;
  StreamSubscription<DatabaseEvent>? _childRemovedSub;
  StreamSubscription<DatabaseEvent>? _childChangedSub;

  @override
  void initState() {
    super.initState();
    _commentsRef = FirebaseDatabase.instance
        .ref('reels/${widget.videoId}/comments');
    _inputController = TextEditingController();
    _inputFocus = FocusNode();
    _loadComments();
  }

  @override
  void dispose() {
    _childAddedSub?.cancel();
    _childRemovedSub?.cancel();
    _childChangedSub?.cancel();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────
  // جلب التعليقات + الاستماع real-time لأي تعليق جديد/محذوف/مُحدَّث
  // ──────────────────────────────────────────────────────────────────
  Future<void> _loadComments() async {
    try {
      final snapshot = await _commentsRef.get().timeout(
        const Duration(seconds: 10),
      );

      if (!mounted) return;

      if (snapshot.exists && snapshot.value is Map) {
        final raw = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final loaded = <_CommentData>[];
        raw.forEach((key, value) {
          if (value is Map) {
            loaded.add(_CommentData.fromMap(
              key.toString(),
              Map<String, dynamic>.from(
                value.map((k, v) => MapEntry(k.toString(), v)),
              ),
            ));
          }
        });
        // أحدث تعليق أولاً
        loaded.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        setState(() {
          _comments
            ..clear()
            ..addAll(loaded);
          _isLoading = false;
        });

        // جلب بيانات المستخدمين بشكل كسول
        _prefetchUserProfiles(loaded.map((c) => c.userId).toSet());
      } else {
        setState(() => _isLoading = false);
      }

      _subscribeToRealtimeChanges();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذّر تحميل التعليقات';
      });
    }
  }

  /// الاستماع للتعليقات الجديدة والمحذوفة والمعدّلة دون إعادة تحميل كاملة
  void _subscribeToRealtimeChanges() {
    _childAddedSub = _commentsRef.onChildAdded.listen((event) {
      final key = event.snapshot.key;
      if (key == null) return;
      // تجاهل لو موجود مسبقاً (أثناء التحميل الأولي)
      if (_comments.any((c) => c.id == key)) return;
      final value = event.snapshot.value;
      if (value is! Map) return;
      final data = _CommentData.fromMap(
        key,
        Map<String, dynamic>.from(
          value.map((k, v) => MapEntry(k.toString(), v)),
        ),
      );
      if (!mounted) return;
      setState(() => _comments.insert(0, data));
      _prefetchUserProfiles({data.userId});
    });

    _childRemovedSub = _commentsRef.onChildRemoved.listen((event) {
      final key = event.snapshot.key;
      if (key == null || !mounted) return;
      setState(() => _comments.removeWhere((c) => c.id == key));
    });

    // لما يحصل like/reply على تعليق → نُحدّثه محلياً (الـ likes/replies)
    _childChangedSub = _commentsRef.onChildChanged.listen((event) {
      final key = event.snapshot.key;
      final value = event.snapshot.value;
      if (key == null || value is! Map || !mounted) return;
      final updated = _CommentData.fromMap(
        key,
        Map<String, dynamic>.from(
          value.map((k, v) => MapEntry(k.toString(), v)),
        ),
      );
      final idx = _comments.indexWhere((c) => c.id == key);
      if (idx < 0) return;
      setState(() => _comments[idx] = updated);
    });
  }

  /// جلب بيانات المستخدمين دفعة واحدة (بدون بلوك اليو آي)
  Future<void> _prefetchUserProfiles(Set<String> userIds) async {
    for (final uid in userIds) {
      if (uid.isEmpty || _userCache.containsKey(uid)) continue;
      try {
        final snap = await FirebaseDatabase.instance
            .ref('users/$uid')
            .get()
            .timeout(const Duration(seconds: 4));
        if (!mounted) return;
        if (snap.exists && snap.value is Map) {
          final map = Map<dynamic, dynamic>.from(snap.value as Map);
          _userCache[uid] = _UserProfile(
            name: (map['name'] ?? map['displayName'] ?? map['username'] ?? 'مستخدم')
                .toString(),
            avatar: (map['profilePic'] ??
                    map['photoURL'] ??
                    map['image'] ??
                    map['avatar'] ??
                    '')
                .toString(),
          );
          setState(() {});
        } else {
          _userCache[uid] = const _UserProfile(name: 'مستخدم', avatar: '');
        }
      } catch (_) {
        _userCache[uid] = const _UserProfile(name: 'مستخدم', avatar: '');
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // اختيار مرفق (صورة/فيديو/GIF)
  // ──────────────────────────────────────────────────────────────────
  Future<void> _pickAttachment() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.image_rounded, color: Colors.white),
              title: const Text('صورة من المعرض',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImageOrGif();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_rounded, color: Colors.white),
              title: const Text('فيديو من المعرض',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              title: const Text('التقاط صورة',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImageOrGif(source: ImageSource.camera);
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageOrGif({ImageSource source = ImageSource.gallery}) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (x == null) return;
      final path = x.path.toLowerCase();
      final kind =
          path.endsWith('.gif') ? _AttachmentKind.gif : _AttachmentKind.image;
      setState(() {
        _pickedAttachment = File(x.path);
        _pickedKind = kind;
      });
    } catch (e) {
      _showError('تعذّر اختيار الصورة');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final x = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
      if (x == null) return;
      setState(() {
        _pickedAttachment = File(x.path);
        _pickedKind = _AttachmentKind.video;
      });
    } catch (e) {
      _showError('تعذّر اختيار الفيديو');
    }
  }

  void _clearAttachment() {
    setState(() {
      _pickedAttachment = null;
      _pickedKind = null;
    });
  }

  // ──────────────────────────────────────────────────────────────────
  // إرسال تعليق / رد
  // ──────────────────────────────────────────────────────────────────
  Future<void> _sendComment() async {
    final text = _inputController.text.trim();
    if (text.isEmpty && _pickedAttachment == null) return;
    if (_isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('سجّل الدخول لإضافة تعليق');
      return;
    }

    setState(() => _isSending = true);

    String? mediaUrl;
    String? mediaType;

    try {
      // 1) رفع المرفق إن وجد
      if (_pickedAttachment != null && _pickedKind != null) {
        setState(() => _isUploadingAttachment = true);
        final resourceType =
            _pickedKind == _AttachmentKind.video ? 'video' : 'image';
        mediaUrl = await _cloudinary.uploadImage(
          _pickedAttachment!,
          resourceType: resourceType,
        );
        mediaType = _pickedKind!.name; // image / gif / video
        setState(() => _isUploadingAttachment = false);
      }

      // 2) كتابة التعليق/الرد في Firebase
      final parentId = _replyingTo?.id; // لو null → تعليق رئيسي
      final payload = <String, dynamic>{
        'uid': user.uid,
        'text': text,
        'timestamp': ServerValue.timestamp,
        if (parentId != null) 'parentId': parentId,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (mediaType != null) 'mediaType': mediaType,
      };

      final newRef = _commentsRef.push();
      await newRef.set(payload);

      // 3) لو رد → زوّد عدّاد replies على التعليق الأب
      if (parentId != null) {
        await _commentsRef
            .child('$parentId/repliesCount')
            .set(ServerValue.increment(1));
      }

      // 4) حدّث عدّاد تعليقات الريل فقط للـ top-level (ليس للردود)
      if (parentId == null) {
        widget.feedCubit.recordComment(widget.videoId);
      }

      // 5) تنظيف الـ UI
      _inputController.clear();
      _clearAttachment();
      setState(() {
        _replyingTo = null;
      });
    } catch (e) {
      debugPrint('Send comment error: $e');
      _showError('فشل إرسال التعليق');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isUploadingAttachment = false;
        });
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // تبديل إعجاب على تعليق
  // ──────────────────────────────────────────────────────────────────
  Future<void> _toggleCommentLike(_CommentData comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('سجّل الدخول للتفاعل');
      return;
    }

    final willLike = !comment.isLikedByMe(user.uid);
    final likeRef = _commentsRef.child('${comment.id}/likes/${user.uid}');

    try {
      if (willLike) {
        await likeRef.set(true);
      } else {
        await likeRef.remove();
      }
      // ما نحدّثش العدّاد محلياً — listener onChildChanged هيحدّثه آلياً
      // من عدد أطفال map الـ likes (صارم).
    } catch (e) {
      debugPrint('Like comment error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // بدء الرد على تعليق
  // ──────────────────────────────────────────────────────────────────
  void _startReplyTo(_CommentData comment) {
    final name = _userCache[comment.userId]?.name ?? 'مستخدم';
    setState(() => _replyingTo = comment);
    _inputController.text = '@$name ';
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputController.text.length),
    );
    _inputFocus.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
    _inputController.clear();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.brightRed),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxHeightFraction = mq.size.height >= 900 ? 0.88 : 0.9;
    final initialFraction = mq.size.height >= 900 ? 0.7 : 0.78;

    return DraggableScrollableSheet(
      initialChildSize: initialFraction,
      minChildSize: 0.45,
      maxChildSize: maxHeightFraction,
      expand: false,
      snap: true,
      snapSizes: [initialFraction, maxHeightFraction],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF161616),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              _buildGrabber(),
              _buildHeader(),
              const Divider(color: Colors.white10, height: 1),
              Expanded(child: _buildBody(scrollController)),
              if (_replyingTo != null) _buildReplyBanner(),
              if (_pickedAttachment != null) _buildAttachmentPreview(),
              _buildInputBar(mq.viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrabber() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildHeader() {
    // عدّاد التعليقات الرئيسية فقط (بدون الردود)
    final topLevelCount =
        _comments.where((c) => c.parentId == null).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            splashRadius: 20,
          ),
          const SizedBox(width: 2),
          Icon(Icons.sort,
              color: Colors.white.withValues(alpha: 0.75), size: 20),
          const Spacer(),
          Text(
            '$topLevelCount تعليقًا',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController controller) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.royalRed,
          strokeWidth: 2.4,
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // نبني شجرة: top-level + children
    final topLevel =
        _comments.where((c) => c.parentId == null).toList();
    if (topLevel.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline,
                  color: Colors.white24, size: 56),
              SizedBox(height: 14),
              Text(
                'كن أول من يعلّق',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'شارك رأيك مع جمهور الأهلي',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // الردود مُرتّبة من الأقدم للأحدث (طبيعي في threaded view)
    final repliesByParent = <String, List<_CommentData>>{};
    for (final c in _comments.where((c) => c.parentId != null)) {
      repliesByParent.putIfAbsent(c.parentId!, () => []).add(c);
    }
    for (final list in repliesByParent.values) {
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: topLevel.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final c = topLevel[i];
        final replies = repliesByParent[c.id] ?? const [];
        return _CommentThread(
          comment: c,
          replies: replies,
          userCache: _userCache,
          currentUid: FirebaseAuth.instance.currentUser?.uid,
          onLike: _toggleCommentLike,
          onReply: _startReplyTo,
        );
      },
    );
  }

  Widget _buildReplyBanner() {
    final name = _userCache[_replyingTo!.userId]?.name ?? 'مستخدم';
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded,
              color: AppColors.royalRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'الرد على $name',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: const Icon(Icons.close, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    return Container(
      color: Colors.white.withValues(alpha: 0.04),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _pickedKind == _AttachmentKind.video
                ? Container(
                    width: 46,
                    height: 46,
                    color: Colors.black54,
                    child: const Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 26),
                  )
                : Image.file(
                    _pickedAttachment!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _pickedKind == _AttachmentKind.video
                  ? 'فيديو مرفق'
                  : _pickedKind == _AttachmentKind.gif
                      ? 'GIF مرفق'
                      : 'صورة مرفقة',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          if (_isUploadingAttachment)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.luminousGold,
              ),
            )
          else
            GestureDetector(
              onTap: _clearAttachment,
              child: const Icon(Icons.close, color: Colors.white54, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar(double keyboardPadding) {
    final user = FirebaseAuth.instance.currentUser;
    final currentAvatar = user?.photoURL ?? '';
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.6)),
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + keyboardPadding),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar(url: currentAvatar, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        focusNode: _inputFocus,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendComment(),
                        decoration: InputDecoration(
                          hintText: _replyingTo != null
                              ? 'اكتب ردك...'
                              : 'إضافة تعليق...',
                          hintStyle: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    // زر إرفاق صورة/فيديو/GIF (بديل الـ emoji)
                    GestureDetector(
                      onTap: _pickAttachment,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.luminousGold.withValues(alpha: 0.85),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              isSending: _isSending,
              onTap: _sendComment,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// MARK: thread = تعليق رئيسي + قائمة ردوده
// ═════════════════════════════════════════════════════════════════════
class _CommentThread extends StatefulWidget {
  final _CommentData comment;
  final List<_CommentData> replies;
  final Map<String, _UserProfile> userCache;
  final String? currentUid;
  final Future<void> Function(_CommentData) onLike;
  final void Function(_CommentData) onReply;

  const _CommentThread({
    required this.comment,
    required this.replies,
    required this.userCache,
    required this.currentUid,
    required this.onLike,
    required this.onReply,
  });

  @override
  State<_CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<_CommentThread> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentTile(
          comment: widget.comment,
          profile: widget.userCache[widget.comment.userId],
          currentUid: widget.currentUid,
          onLike: () => widget.onLike(widget.comment),
          onReply: () => widget.onReply(widget.comment),
        ),
        if (widget.replies.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(right: 46, top: 6),
            child: GestureDetector(
              onTap: () => setState(() => _showReplies = !_showReplies),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 26, height: 1, color: Colors.white24),
                  const SizedBox(width: 6),
                  Text(
                    _showReplies
                        ? 'إخفاء الردود'
                        : 'عرض ${widget.replies.length} ${widget.replies.length == 1 ? "رد" : "ردود"}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showReplies
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_showReplies)
            Padding(
              padding: const EdgeInsets.only(right: 40, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final r in widget.replies) ...[
                    _CommentTile(
                      comment: r,
                      profile: widget.userCache[r.userId],
                      currentUid: widget.currentUid,
                      compact: true,
                      onLike: () => widget.onLike(r),
                      onReply: () => widget.onReply(r),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// MARK: بطاقة تعليق/رد واحد
// ═════════════════════════════════════════════════════════════════════
class _CommentTile extends StatelessWidget {
  final _CommentData comment;
  final _UserProfile? profile;
  final String? currentUid;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final bool compact;

  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onReply,
    this.profile,
    this.currentUid,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? 'مستخدم';
    final avatar = profile?.avatar ?? '';
    final isLiked = currentUid != null && comment.isLikedByMe(currentUid!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(url: avatar, size: compact ? 28 : 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: compact ? 12 : 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              if (comment.text.isNotEmpty)
                Text(
                  comment.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 13.5 : 14.5,
                    height: 1.35,
                  ),
                ),
              if (comment.mediaUrl != null && comment.mediaUrl!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _CommentMedia(
                  url: comment.mediaUrl!,
                  type: comment.mediaType ?? 'image',
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    _formatTime(comment.timestamp),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11.5),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onReply,
                    behavior: HitTestBehavior.opaque,
                    child: const Text(
                      'رد',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (comment.repliesCount > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${comment.repliesCount} رد',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11.5),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // زر الإعجاب (شغّال)
        GestureDetector(
          onTap: onLike,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(isLiked),
                  size: compact ? 16 : 18,
                  color: isLiked
                      ? AppColors.brightRed
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                comment.likesCount > 0 ? _formatLikes(comment.likesCount) : '',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    final weeks = diff.inDays ~/ 7;
    if (weeks < 4) return 'منذ $weeks أ';
    final months = diff.inDays ~/ 30;
    if (months < 12) return 'منذ $months ش';
    return 'منذ ${diff.inDays ~/ 365} سنة';
  }

  String _formatLikes(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}م';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}ك';
    return '$n';
  }
}

// ═════════════════════════════════════════════════════════════════════
// MARK: عرض المرفق داخل التعليق
// ═════════════════════════════════════════════════════════════════════
class _CommentMedia extends StatelessWidget {
  final String url;
  final String type; // image / gif / video
  const _CommentMedia({required this.url, required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == 'video') {
      return _InlineVideoPlayer(url: url);
    }
    // image أو gif
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GestureDetector(
        onTap: () => _openFullscreen(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 220,
            maxWidth: 240,
          ),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 180,
              height: 180,
              color: Colors.white10,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.royalRed,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 180,
              height: 180,
              color: Colors.black26,
              child: const Icon(Icons.broken_image,
                  color: Colors.white38, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullscreenImageViewer(url: url),
      ),
    );
  }
}

class _FullscreenImageViewer extends StatelessWidget {
  final String url;
  const _FullscreenImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// مشغّل فيديو inline بسيط داخل التعليقات
class _InlineVideoPlayer extends StatefulWidget {
  final String url;
  const _InlineVideoPlayer({required this.url});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _c;
  bool _ready = false;
  bool _err = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(true);
    _c = c;
    c.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    }).catchError((_) {
      if (mounted) setState(() => _err = true);
    });
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_err) {
      return Container(
        width: 200,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.error_outline, color: Colors.white38),
      );
    }
    if (!_ready || _c == null) {
      return Container(
        width: 200,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              color: AppColors.royalRed, strokeWidth: 2),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _c!.value.isPlaying ? _c!.pause() : _c!.play();
          });
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 240,
            maxHeight: 220,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _c!.value.aspectRatio,
                child: VideoPlayer(_c!),
              ),
              if (!_c!.value.isPlaying)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 30),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// MARK: أفاتار دائري مع fallback
// ═════════════════════════════════════════════════════════════════════
class _Avatar extends StatelessWidget {
  final String url;
  final double size;
  const _Avatar({required this.url, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
        image: url.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: url.isEmpty
          ? Icon(Icons.person,
              color: Colors.white.withValues(alpha: 0.5), size: size * 0.6)
          : null,
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isSending;
  final VoidCallback onTap;

  const _SendButton({required this.isSending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSending ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.royalRed, AppColors.darkRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isSending
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send, color: Colors.white, size: 18),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// MARK: نماذج بيانات محلية
// ═════════════════════════════════════════════════════════════════════
enum _AttachmentKind { image, gif, video }

class _CommentData {
  final String id;
  final String userId;
  final String text;
  final DateTime timestamp;

  /// تعليق الأب لو ده رد (null → تعليق رئيسي)
  final String? parentId;

  /// URL الصورة/الفيديو المرفق (لو موجود)
  final String? mediaUrl;

  /// نوع المرفق: image / gif / video
  final String? mediaType;

  /// خريطة likes (uid → true). بنحسب منها العدّاد + هل أعجبني
  final Map<String, bool> likes;

  /// عدّاد الردود
  final int repliesCount;

  const _CommentData({
    required this.id,
    required this.userId,
    required this.text,
    required this.timestamp,
    this.parentId,
    this.mediaUrl,
    this.mediaType,
    this.likes = const {},
    this.repliesCount = 0,
  });

  int get likesCount => likes.length;
  bool isLikedByMe(String uid) => likes[uid] == true;

  factory _CommentData.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['timestamp'];
    DateTime time;
    if (ts is int) {
      time = DateTime.fromMillisecondsSinceEpoch(ts);
    } else if (ts is String) {
      final parsed = int.tryParse(ts);
      time = parsed != null
          ? DateTime.fromMillisecondsSinceEpoch(parsed)
          : DateTime.now();
    } else {
      time = DateTime.now();
    }

    // likes: ممكن تكون Map أو null
    final likesMap = <String, bool>{};
    final likesRaw = map['likes'];
    if (likesRaw is Map) {
      likesRaw.forEach((k, v) {
        if (v == true) likesMap[k.toString()] = true;
      });
    }

    int replies = 0;
    final rc = map['repliesCount'];
    if (rc is int) {
      replies = rc;
    } else if (rc is num) {
      replies = rc.toInt();
    }

    return _CommentData(
      id: id,
      userId: (map['uid'] ?? map['userId'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      timestamp: time,
      parentId: (map['parentId'] ?? '').toString().isEmpty
          ? null
          : map['parentId'].toString(),
      mediaUrl: (map['mediaUrl'] ?? '').toString().isEmpty
          ? null
          : map['mediaUrl'].toString(),
      mediaType: (map['mediaType'] ?? '').toString().isEmpty
          ? null
          : map['mediaType'].toString(),
      likes: likesMap,
      repliesCount: replies,
    );
  }
}

class _UserProfile {
  final String name;
  final String avatar;
  const _UserProfile({required this.name, required this.avatar});
}
