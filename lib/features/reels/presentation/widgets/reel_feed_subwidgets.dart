import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'reels_feed_theme.dart';

/// أيقونة تعليق تيك توك (فقاعة + ثلاث نقاط).
class ReelCommentBubbleIcon extends StatelessWidget {
  const ReelCommentBubbleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final bubble = Colors.white.withValues(alpha: 0.95);
    return SizedBox(
      width: 36,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.chat_bubble_rounded,
            color: bubble,
            size: 32,
            shadows: const [Shadow(blurRadius: 10, color: Colors.black54)],
          ),
          Positioned(
            bottom: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dotW(Colors.black54),
                const SizedBox(width: 2.5),
                _dotW(Colors.black54),
                const SizedBox(width: 2.5),
                _dotW(Colors.black54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dotW(Color c) {
    return Container(
      width: 2.5,
      height: 2.5,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}

/// زر لايك منفصل لإعادة البناء فقط عند تغيّر الحالة (أداء أفضل عند التمرير).
class ReelLikeActionButton extends StatelessWidget {
  const ReelLikeActionButton({
    super.key,
    required this.isLiked,
    required this.countLabel,
    required this.onTap,
  });

  final bool isLiked;
  final String countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = isLiked
        ? ReelsFeedTheme.rose.withValues(alpha: 0.98)
        : Colors.white.withValues(alpha: 0.95);
    return TikTokSideActionButton(
      icon: Icon(
        Icons.favorite_rounded,
        color: c,
        size: 36,
        shadows: const [Shadow(blurRadius: 12, color: Colors.black45)],
      ),
      label: countLabel,
      onTap: onTap,
    );
  }
}

/// زر جانبي عام (أيقونة + رقم) — لايك، حفظ، مشاركة، إلخ.
class TikTokSideActionButton extends StatelessWidget {
  const TikTokSideActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: ReelsFeedTheme.sideActionCount,
          ),
        ],
      ),
    );
  }
}

/// خلفية أثناء التحميل أو عند فشل الفيديو: صورة مصغّرة إن وُجدت، وإلا لون داكن — وليس شاشة سوداء فقط.
class ReelVideoBackdrop extends StatelessWidget {
  const ReelVideoBackdrop({
    super.key,
    required this.isLoading,
    required this.isError,
    this.thumbnailUrl,
    this.onRetry,
  });

  final bool isLoading;
  final bool isError;
  final String? thumbnailUrl;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final thumb = thumbnailUrl?.trim() ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumb.isNotEmpty)
          CachedNetworkImage(
            imageUrl: thumb,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: ReelsFeedTheme.sheetDarker),
            errorWidget: (_, __, ___) => Container(color: ReelsFeedTheme.sheetDarker),
          )
        else
          Container(color: ReelsFeedTheme.sheetDarker),
        Container(
          color: Colors.black.withValues(alpha: isError ? 0.5 : 0.38),
        ),
        if (isLoading)
          const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.8,
              ),
            ),
          ),
        if (isError)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_off_outlined,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 52,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تعذّر تشغيل الفيديو',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تحقق من الاتصال أو جرّب لاحقاً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, color: ReelsFeedTheme.rose),
                      label: const Text(
                        'إعادة المحاولة',
                        style: TextStyle(color: ReelsFeedTheme.rose, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
