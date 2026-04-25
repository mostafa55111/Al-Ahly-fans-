import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/providers/video_controller_manager.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/tiktok_reel_video.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/tiktok_side_actions.dart';

/// عنصر ريل واحد بكامل الشاشة بأسلوب تيك توك.
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
  final VoidCallback onToggleMute;

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
    required this.onToggleMute,
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
    // double tap بأسلوب تيك توك = إعجاب فقط، ما بيلغيش الإعجاب
    // → يمنع تذبذب العدّاد عند الضغط المزدوج على ريل أُعجب به من قبل
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
              );
            },
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

        // ملاحظة: شريط التابات "متابَعون | لك" مرسوم مرة واحدة في
        // [TikTokReelsPage] عبر [_FeedTabsBar]، فلا نكرّره هنا.

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
                  onLike: widget.onLike,
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

        // ========== زر كتم الصوت — منطقة ضغط كبيرة + animation واضح ==========
        Positioned(
          top: 50,
          left: 10,
          child: SafeArea(
            child: ListenableBuilder(
              listenable: widget.manager,
              builder: (context, _) {
                final isMuted = widget.manager.isMuted;
                return Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onToggleMute,
                    splashColor: Colors.white24,
                    highlightColor: Colors.white10,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 0.8,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          key: ValueKey(isMuted),
                          color: isMuted
                              ? const Color(0xFFFF5C5C)
                              : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
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
        // الاسم قابل للضغط → يفتح بروفايل صاحب الريل (بارز زي تيك توك)
        GestureDetector(
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
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          _TikTokCaption(text: caption),
        ],
        const SizedBox(height: 10),
        // صف الموسيقى بستايل تيك توك (أيقونة موسيقى + marquee خفيف)
        _MusicStrip(
          label: caption.isNotEmpty
              ? 'الصوت الأصلي — $name'
              : 'الصوت الأصلي — جمهور الأهلي',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: وصف الريل بستايل تيك توك — ألوان للهاشتاقات + "...المزيد"
// ═══════════════════════════════════════════════════════════════════
class _TikTokCaption extends StatefulWidget {
  final String text;
  const _TikTokCaption({required this.text});

  @override
  State<_TikTokCaption> createState() => _TikTokCaptionState();
}

class _TikTokCaptionState extends State<_TikTokCaption> {
  bool _expanded = false;

  /// تقسيم النص لكلمات عادية + هاشتاقات بنمط مميز (أزرق فاتح بولد).
  List<TextSpan> _buildSpans(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(#[\u0600-\u06FFA-Za-z0-9_]+)');
    int last = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(
          color: Color(0xFF9AD4FF),
          fontWeight: FontWeight.w700,
        ),
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

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: RichText(
        maxLines: _expanded ? 10 : 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: baseStyle,
          children: [
            ..._buildSpans(widget.text),
            if (!_expanded)
              const TextSpan(
                text: '  المزيد',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: شريط الموسيقى السفلي (animated — يرمز لتشغيل الصوت)
// ═══════════════════════════════════════════════════════════════════
class _MusicStrip extends StatefulWidget {
  final String label;
  const _MusicStrip({required this.label});

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
    return Row(
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
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  Icons.favorite,
                  color: AppColors.brightRed,
                  size: 120,
                  shadows: [
                    Shadow(
                      color: AppColors.brightRed.withValues(alpha: 0.6),
                      blurRadius: 24,
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
