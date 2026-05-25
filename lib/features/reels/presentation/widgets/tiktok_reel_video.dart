import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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
/// - تتبّع عتبة المشاهدة (≥70%) لتسجيل مشاهدة مؤهّلة في الخوارزمية (مرّة واحدة لكل جلسة عرض).
class TikTokReelVideo extends StatefulWidget {
  final VideoPlayerController? controller;
  final bool isActive;
  final bool hasError;
  final VoidCallback? onTogglePlayPause;
  final VoidCallback? onDoubleTap;

  /// يُستدعى مرة واحدة عند وصول التقديم إلى ≥ [watchThresholdFraction] من مدة الفيديو.
  final VoidCallback? onWatchThresholdReached;

  /// ضغط مطوّل (خيارات مثل «غير مهتم»).
  final VoidCallback? onLongPress;

  /// نسبة من مدة الفيديو (0–1) تُعتبر «مشاهدة مؤهّلة».
  final double watchThresholdFraction;

  const TikTokReelVideo({
    super.key,
    required this.controller,
    required this.isActive,
    this.hasError = false,
    this.onTogglePlayPause,
    this.onDoubleTap,
    this.onWatchThresholdReached,
    this.onLongPress,
    this.watchThresholdFraction = 0.7,
  });

  @override
  State<TikTokReelVideo> createState() => _TikTokReelVideoState();
}

class _TikTokReelVideoState extends State<TikTokReelVideo> {
  VideoPlayerController? _listened;
  bool _thresholdReported = false;
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _attachListener(widget.controller);
  }

  @override
  void didUpdateWidget(covariant TikTokReelVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _thresholdReported = false;
      _detachListener();
      _attachListener(widget.controller);
    }
    if (!widget.isActive && oldWidget.isActive) {
      _thresholdReported = false;
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _detachListener();
    super.dispose();
  }

  void _onVideoTap() {
    _tapCount++;
    if (_tapCount == 1) {
      _tapTimer?.cancel();
      _tapTimer = Timer(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        if (_tapCount == 1) {
          widget.onTogglePlayPause?.call();
        }
        _tapCount = 0;
      });
    } else if (_tapCount == 2) {
      _tapTimer?.cancel();
      _tapCount = 0;
      widget.onDoubleTap?.call();
    }
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
    _maybeReportWatchThreshold();
    setState(() {});
  }

  /// لو شاهد المستخدم ≥70% من الريل نبلّغ الطبقة العليا مرة واحدة (Firestore / الخوارزمية).
  void _maybeReportWatchThreshold() {
    if (_thresholdReported ||
        !widget.isActive ||
        widget.onWatchThresholdReached == null) {
      return;
    }
    final c = widget.controller;
    if (c == null || !c.value.isInitialized || c.value.hasError) return;
    final total = c.value.duration;
    if (total.inMilliseconds <= 0) return;
    final pos = c.value.position;
    final limit =
        (total.inMilliseconds * widget.watchThresholdFraction).round();
    if (pos.inMilliseconds >= limit) {
      _thresholdReported = true;
      widget.onWatchThresholdReached!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final initialized = c != null && c.value.isInitialized;
    final isPaused = initialized && !c.value.isPlaying && widget.isActive;

    return Semantics(
      label: 'فيديو الريل: اضغط للتشغيل أو الإيقاف المؤقت',
      button: true,
      child: Tooltip(
        message: 'تشغيل أو إيقاف مؤقت',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onVideoTap,
          onLongPress: widget.onLongPress,
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
        ),
      ),
    );
  }
}

/// تحميل الفيديو — تأثير Shimmer بأسلوب تيك توك (مع دلالات لاختبارات Robo).
class _VideoLoadingView extends StatelessWidget {
  const _VideoLoadingView();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'جاري تحميل الفيديو، يرجى الانتظار',
      excludeSemantics: false,
      child: Tooltip(
        message: 'تحميل الفيديو قيد التنفيذ',
        child: Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.06),
          highlightColor: Colors.white.withValues(alpha: 0.18),
          period: const Duration(milliseconds: 1100),
          child: Container(
            color: Colors.white.withValues(alpha: 0.04),
          ),
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
