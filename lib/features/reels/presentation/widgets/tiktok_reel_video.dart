import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';

/// مشغّل الفيديو للريل الواحد.
///
/// لا يدير دورة حياة الـ controller بنفسه — يتلقاه من [VideoControllerManager].
/// مسؤولياته فقط:
/// - عرض الفيديو عند توفّر controller جاهز.
/// - عرض loading indicator لو الـ controller لم يتهيأ بعد.
/// - تمرير نقرات المستخدم (tap / double tap) للـ parent.
/// - عرض شريط تقدم مخصص وإيكونة play overlay.
class TikTokReelVideo extends StatefulWidget {
  final VideoPlayerController? controller;
  final bool isActive;
  final bool hasError;
  final VoidCallback? onTogglePlayPause;
  final VoidCallback? onDoubleTap;

  const TikTokReelVideo({
    super.key,
    required this.controller,
    required this.isActive,
    this.hasError = false,
    this.onTogglePlayPause,
    this.onDoubleTap,
  });

  @override
  State<TikTokReelVideo> createState() => _TikTokReelVideoState();
}

class _TikTokReelVideoState extends State<TikTokReelVideo> {
  VideoPlayerController? _listened;

  @override
  void initState() {
    super.initState();
    _attachListener(widget.controller);
  }

  @override
  void didUpdateWidget(covariant TikTokReelVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachListener();
      _attachListener(widget.controller);
    }
  }

  @override
  void dispose() {
    _detachListener();
    super.dispose();
  }

  void _attachListener(VideoPlayerController? c) {
    if (c == null) return;
    c.addListener(_onControllerUpdate);
    _listened = c;
  }

  void _detachListener() {
    _listened?.removeListener(_onControllerUpdate);
    _listened = null;
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    // نُعيد البناء عند تغيّر حالة التشغيل/التهيئة فقط
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final initialized = c != null && c.value.isInitialized;
    final isPaused = initialized && !c.value.isPlaying && widget.isActive;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTogglePlayPause,
      onDoubleTap: widget.onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية سوداء
          Container(color: Colors.black),

          // الفيديو يغطي الشاشة بالكامل (BoxFit.cover)
          if (initialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
            )
          else if (widget.hasError)
            const _VideoErrorView()
          else if (widget.isActive)
            // نعرض الـ loading فقط على الفيديو الحالي كي لا نُجمّد باقي الشاشات
            const _VideoLoadingView(),

          // أيقونة play الكبيرة وسط الشاشة عند التوقف
          if (isPaused)
            Center(
              child: AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),

          // شريط تقدم ذهبي في الأسفل (فقط لو جاهز)
          if (initialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: AppColors.luminousGold,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loading indicator شفاف — يُعرض فقط أثناء تحميل الفيديو الحالي
class _VideoLoadingView extends StatelessWidget {
  const _VideoLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 38,
        height: 38,
        child: CircularProgressIndicator(
          color: AppColors.luminousGold,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

/// شاشة الخطأ — يُعرض عند فشل تحميل الفيديو
class _VideoErrorView extends StatelessWidget {
  const _VideoErrorView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.white38, size: 40),
            SizedBox(height: 8),
            Text(
              'تعذّر تشغيل الفيديو',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
