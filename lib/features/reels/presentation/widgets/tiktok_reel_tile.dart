import 'package:animate_do/animate_do.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_hashtag_utils.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/providers/video_controller_manager.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/tiktok_reel_video.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/tiktok_side_actions.dart';

/// عنصر ريل واحد بكامل الشاشة بأسلوب تيك توك.
///
/// **التخزين المؤقت:** لا يُنشئ هذا الـ Widget مشغّلاً من الرابط مباشرة.
/// [VideoControllerManager] يجلب الملف عبر [flutter_cache_manager]
/// (`getSingleFile`) ثم يشغّل عبر [VideoPlayerController.file] — أي تدفّق من القرص بعد التخزين.
///
/// مُزوّد بـ [AutomaticKeepAliveClientMixin] للحفاظ على حالة الـ UI
/// (مثل animation القلب، والموضع بين الصفحات) عند العودة إلى نفس الـ index
/// دون إعادة تهيئة كاملة. الـ controller نفسه يدار من [VideoControllerManager].
class TikTokReelTile extends StatefulWidget {
  final int index;
  final VideoModel reel;
  final VideoControllerManager manager;
  final bool isActive;
  final bool isFollowing;

  /// زر القلب: يتنقل بين like/unlike
  final VoidCallback onLike;

  /// الـ double tap: يعمل like فقط (لا يُلغي الإعجاب أبداً — أسلوب تيك توك)
  final VoidCallback onLikeOnly;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onFollow;
  final VoidCallback onProfileTap;

  /// عند تجاوز عتبة مشاهدة (~70%) لمرّة واحدة لكل ظهور للبلاطة.
  final VoidCallback? onQualifiedWatch;

  /// عند الضغط على هاشتاج في الوصف (النص بدون # مُطبَّع).
  final ValueChanged<String>? onHashtagTap;

  /// فتح صفحة الترند الصوتي — ضغطة على شريط الموسيقى.
  final VoidCallback? onMusicTap;

  /// قائمة خيارات (مثل «غير مهتم») بعد ضغط مطوّل على الفيديو.
  final VoidCallback? onVideoLongPress;

  const TikTokReelTile({
    super.key,
    required this.index,
    required this.reel,
    required this.manager,
    required this.isActive,
    required this.isFollowing,
    required this.onLike,
    required this.onLikeOnly,
    required this.onComment,
    required this.onShare,
    required this.onSave,
    required this.onFollow,
    required this.onProfileTap,
    this.onQualifiedWatch,
    this.onHashtagTap,
    this.onMusicTap,
    this.onVideoLongPress,
  });

  @override
  State<TikTokReelTile> createState() => _TikTokReelTileState();
}

class _TikTokReelTileState extends State<TikTokReelTile>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _heartController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    // double tap بأسلوب تيك توك = إعجاب فقط، ما بيلغيش الإعجاب
    widget.onLikeOnly();
    _heartController.forward(from: 0);
  }

  void _handleTogglePlay() {
    // نطلب من المدير تبديل التشغيل فقط إذا كان هذا هو الفيديو النشط
    if (widget.isActive) {
      widget.manager.togglePlayPause();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by KeepAlive

    return Stack(
      fit: StackFit.expand,
      children: [
        // ========== الفيديو (يعيد البناء فقط عند تغيّر المدير) ==========
        Positioned.fill(
          child: RepaintBoundary(
            child: ListenableBuilder(
            listenable: widget.manager,
            builder: (context, _) {
              final controller = widget.manager.controllerFor(widget.index);
              final hasError = widget.manager.hasError(widget.index);
              return TikTokReelVideo(
                controller: controller,
                isActive: widget.isActive,
                hasError: hasError,
                onTogglePlayPause: _handleTogglePlay,
                onDoubleTap: _handleDoubleTap,
                onLongPress: widget.onVideoLongPress,
                onWatchThresholdReached: widget.onQualifiedWatch,
              );
            },
          ),
          ),
        ),

        // ========== تدرّج سفلي لتحسين قراءة النص ==========
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
        ),

        // ========== قلب الـ double tap ==========
        _AnimatedHeart(controller: _heartController),

        // ملاحظة: شريط التابات + زر «جمهورك | الكل» في [TikTokReelsPage] —
        // لا نكررها داخل البلاطة.

        // ========== بيانات الفيديو (اسم + وصف + موسيقى) ==========
        Positioned(
          left: 16,
          right: 86,
          bottom: 20,
          child: SafeArea(
            top: false,
            child: widget.isActive
                ? FadeInUp(
                    duration: const Duration(milliseconds: 350),
                    from: 12,
                    child: _buildInfoSection(),
                  )
                : _buildInfoSection(),
          ),
        ),

        // ========== الأزرار الجانبية ==========
        Positioned(
          right: 10,
          bottom: 18,
          child: RepaintBoundary(
            child: SafeArea(
            top: false,
            child: ListenableBuilder(
              // نُعيد بناء الأزرار فقط عند تحديث بيانات الريل (likes, ...)
              listenable: widget.manager,
              builder: (context, _) {
                return TikTokSideActions(
                  userId: widget.reel.userId,
                  userProfilePic: widget.reel.userProfilePic,
                  isFollowing: widget.isFollowing,
                  isLiked: widget.reel.isLikedByCurrentUser,
                  isSaved: widget.reel.isSavedByCurrentUser,
                  likesCount: widget.reel.likesCount,
                  commentsCount: widget.reel.commentsCount,
                  sharesCount: widget.reel.sharesCount,
                  savesCount: widget.reel.savesCount,
                  onLike: () {
                    final willLike = !widget.reel.isLikedByCurrentUser;
                    widget.onLike();
                    if (willLike) _heartController.forward(from: 0);
                  },
                  onComment: widget.onComment,
                  onShare: widget.onShare,
                  onSave: widget.onSave,
                  onFollow: widget.onFollow,
                  onProfileTap: widget.onProfileTap,
                );
              },
            ),
          ),
        ),
        ),

        // الجمهور والصوت: يُداران من [TikTokReelsPage] (زر split) والفيديو يبقى بصوت طبيعي افتراضياً.
      ],
    );
  }

  Widget _buildInfoSection() {
    final name =
        widget.reel.userName.isNotEmpty ? widget.reel.userName : 'مستخدم';
    final caption = widget.reel.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // الاسم قابل للضغط → يفتح بروفايل صاحب الريل (مع دلالات للوصول / Robo)
        Semantics(
          button: true,
          label: 'فتح بروفايل @$name',
          child: Tooltip(
            message: 'بروفايل صاحب الريل',
            child: GestureDetector(
              onTap: widget.onProfileTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    '@$name',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 8),
                        Shadow(color: Colors.black54, blurRadius: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          _TikTokCaption(
            text: caption,
            onTagTap: widget.onHashtagTap,
          ),
        ],
        const SizedBox(height: 10),
        _MusicStrip(
          label: widget.reel.audioDisplayLabel,
          onTap: widget.onMusicTap,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: وصف الريل — هاشتاجات قابلة للضغط + طي/فتح
// ═══════════════════════════════════════════════════════════════════
class _TikTokCaption extends StatefulWidget {
  final String text;
  final ValueChanged<String>? onTagTap;

  const _TikTokCaption({
    required this.text,
    this.onTagTap,
  });

  @override
  State<_TikTokCaption> createState() => _TikTokCaptionState();
}

class _TikTokCaptionState extends State<_TikTokCaption> {
  bool _expanded = false;
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(covariant _TikTokCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  List<InlineSpan> _buildSpans() {
    _disposeRecognizers();
    const hashtagStyle = TextStyle(
      color: Color(0xFF9AD4FF),
      fontWeight: FontWeight.w700,
    );
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(#[\u0600-\u06FFA-Za-z0-9_]+)', unicode: true);
    var last = 0;
    final text = widget.text;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final rawTag = m.group(0)!;
      TapGestureRecognizer? rec;
      if (widget.onTagTap != null) {
        rec = TapGestureRecognizer()
          ..onTap = () {
            widget.onTagTap!(ReelsHashtagUtils.normalizeTag(rawTag));
          };
        _recognizers.add(rec);
      }
      spans.add(TextSpan(
        text: rawTag,
        style: hashtagStyle,
        recognizer: rec,
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.35,
      fontWeight: FontWeight.w500,
      shadows: [
        Shadow(color: Colors.black87, blurRadius: 8),
        Shadow(color: Colors.black54, blurRadius: 2),
      ],
    );

    final needsToggle = widget.text.length > 96 || widget.text.contains('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: baseStyle,
            children: _buildSpans(),
          ),
          maxLines: _expanded ? 12 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (needsToggle)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Semantics(
              button: true,
              label: _expanded ? 'طي وصف الريل' : 'توسيع وصف الريل',
              child: Tooltip(
                message: _expanded ? 'طي' : 'المزيد',
                child: GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'إخفاء' : 'المزيد',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: شريط الموسيقى السفلي (animated — يرمز لتشغيل الصوت)
// ═══════════════════════════════════════════════════════════════════
class _MusicStrip extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _MusicStrip({required this.label, this.onTap});

  @override
  State<_MusicStrip> createState() => _MusicStripState();
}

class _MusicStripState extends State<_MusicStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        RotationTransition(
          turns: _spin,
          child: const Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: 15,
            shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 6),
                Shadow(color: Colors.black54, blurRadius: 2),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.onTap == null) return row;

    return Semantics(
      button: true,
      label: 'فتح الترند الصوتي: ${widget.label}',
      child: Tooltip(
        message: 'فتح صفحة الصوت أو الموسيقى',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}

/// قلب يطفر ويتلاشى عند الـ double tap (scale + fade)
class _AnimatedHeart extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedHeart({required this.controller});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.value == 0) return const SizedBox.shrink();
            final t = controller.value;
            final scale = t < 0.3
                ? (t / 0.3) * 1.4
                : t < 0.6
                    ? 1.4 - (t - 0.3) * 0.5
                    : 1.1;
            final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3);
            final heartColor = FanAppIdentity.registryAppId == 'ahly'
                ? AppColors.royalRed
                : AppColors.royalBlue;
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  Icons.favorite,
                  color: heartColor,
                  size: 150,
                  shadows: [
                    Shadow(
                      color: heartColor.withValues(alpha: 0.65),
                      blurRadius: 28,
                    ),
                    const Shadow(
                      color: Colors.white54,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
