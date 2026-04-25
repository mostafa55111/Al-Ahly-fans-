import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';

/// أزرار التفاعل الجانبية بأسلوب تيك توك:
/// صورة المستخدم + زر متابعة + إعجاب + تعليق + حفظ + مشاركة
class TikTokSideActions extends StatelessWidget {
  /// UID صاحب الريل — يُستخدم لجلب أحدث صورة بروفايل من `/users/{uid}/profilePic`
  /// لو الصورة المحفوظة مع الريل كانت فاضية.
  final String userId;
  final String userProfilePic;
  final bool isFollowing;
  final bool isLiked;
  final bool isSaved;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onFollow;
  final VoidCallback onProfileTap;

  const TikTokSideActions({
    super.key,
    required this.userId,
    required this.userProfilePic,
    required this.isFollowing,
    required this.isLiked,
    required this.isSaved,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.savesCount,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
    required this.onFollow,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProfileAvatar(),
        const SizedBox(height: 22),
        _ActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          iconColor: isLiked ? AppColors.brightRed : Colors.white,
          count: _formatCount(likesCount),
          onTap: onLike,
          scale: isLiked ? 1.05 : 1.0,
        ),
        const SizedBox(height: 18),
        // أيقونة التعليق بستايل تيك توك — فقاعة حوار outlined بنهاية (tail)
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          iconColor: Colors.white,
          count: _formatCount(commentsCount),
          onTap: onComment,
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          iconColor: isSaved ? AppColors.luminousGold : Colors.white,
          count: _formatCount(savesCount),
          onTap: onSave,
          scale: isSaved ? 1.08 : 1.0,
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.reply,
          iconColor: Colors.white,
          count: _formatCount(sharesCount),
          onTap: onShare,
        ),
        const SizedBox(height: 18),
        _buildSpinningDisc(),
      ],
    );
  }

  /// صورة البروفايل مع زر + للمتابعة أسفلها
  Widget _buildProfileAvatar() {
    return SizedBox(
      width: 56,
      height: 74,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          GestureDetector(
            onTap: onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: _ReelAuthorAvatar(
                  userId: userId,
                  initialProfilePic: userProfilePic,
                  placeholder: _placeholderAvatar(),
                ),
              ),
            ),
          ),
          if (!isFollowing)
            Positioned(
              bottom: -2,
              child: GestureDetector(
                onTap: onFollow,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.royalRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.royalRed.withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      color: AppColors.darkBlack,
      child: const Icon(Icons.person, color: Colors.white54, size: 30),
    );
  }

  /// الأسطوانة الدوّارة (Music Disc) في أسفل العمود
  Widget _buildSpinningDisc() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 6),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 6.283,
          child: child,
        );
      },
      onEnd: () {},
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF333333), Color(0xFF0A0A0A)],
          ),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: const Center(
          child: Icon(
            Icons.music_note,
            color: AppColors.luminousGold,
            size: 18,
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

/// أفاتار ذكي لصاحب الريل
/// ═══════════════════════════════════════════════════════════════════
/// ‣ لو فيه `initialProfilePic` → يعرضها فوراً.
/// ‣ لو فاضية → يجلب الصورة من `users/{uid}/profilePic` لأول مرة، ثم
///   يكاشها في [_avatarCache] عشان ما يتعمل fetch تاني لنفس الـ uid.
/// ‣ لو كل المصادر فاضية → placeholder.
class _ReelAuthorAvatar extends StatefulWidget {
  final String userId;
  final String initialProfilePic;
  final Widget placeholder;

  const _ReelAuthorAvatar({
    required this.userId,
    required this.initialProfilePic,
    required this.placeholder,
  });

  @override
  State<_ReelAuthorAvatar> createState() => _ReelAuthorAvatarState();
}

/// كاش global للـ avatar URLs عشان كل الريلز لنفس المستخدم تستخدم نفس الصورة
/// بدون طلب إضافي للداتابيز (تحسين كبير للأداء في feed طويل).
final Map<String, String> _avatarCache = {};

class _ReelAuthorAvatarState extends State<_ReelAuthorAvatar> {
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialProfilePic.trim();
    if (_currentUrl.isEmpty && _avatarCache.containsKey(widget.userId)) {
      _currentUrl = _avatarCache[widget.userId]!;
    } else if (_currentUrl.isNotEmpty) {
      _avatarCache[widget.userId] = _currentUrl;
    }
    if (_currentUrl.isEmpty && widget.userId.isNotEmpty) {
      _fetchAvatar();
    }
  }

  Future<void> _fetchAvatar() async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref('users/${widget.userId}')
          .get()
          .timeout(const Duration(seconds: 6));
      if (!mounted || !snap.exists || snap.value is! Map) return;
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      final url = (map['profilePic'] ??
              map['photoURL'] ??
              map['avatar'] ??
              map['image'] ??
              '')
          .toString();
      if (url.isEmpty) return;
      _avatarCache[widget.userId] = url;
      if (mounted) setState(() => _currentUrl = url);
    } catch (e) {
      debugPrint('AuthorAvatar fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUrl.isEmpty) return widget.placeholder;
    return CachedNetworkImage(
      imageUrl: _currentUrl,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => widget.placeholder,
      placeholder: (_, __) => widget.placeholder,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String count;
  final VoidCallback onTap;
  final double scale;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: scale,
            child: Icon(
              icon,
              color: iconColor,
              size: 34,
              shadows: const [
                Shadow(color: Colors.black45, blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
