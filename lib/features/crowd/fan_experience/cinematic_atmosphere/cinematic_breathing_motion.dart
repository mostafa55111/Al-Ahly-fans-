import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_motion_tokens.dart';

/// نفس خفيف للكارت المختار/الفائز فقط — يتوقف عند خلفية التطبيق.
class CinematicBreathingMotion extends StatefulWidget {
  const CinematicBreathingMotion({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<CinematicBreathingMotion> createState() =>
      _CinematicBreathingMotionState();
}

class _CinematicBreathingMotionState extends State<CinematicBreathingMotion>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController? _controller;
  Animation<double>? _scale;
  Animation<double>? _opacity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();
  }

  void _initController() {
    _controller?.dispose();
    if (!widget.enabled) {
      _controller = null;
      return;
    }
    final c = AnimationController(
      vsync: this,
      duration: CinematicMotionTokens.breathFullCycle,
    );
    final curve = CurvedAnimation(parent: c, curve: Curves.easeInOut);
    _scale = Tween<double>(
      begin: CinematicMotionTokens.breathScaleMin,
      end: CinematicMotionTokens.breathScaleMax,
    ).animate(curve);
    _opacity = Tween<double>(
      begin: CinematicMotionTokens.breathOpacityMax,
      end: CinematicMotionTokens.breathOpacityMin,
    ).animate(curve);
    _controller = c;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      c.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CinematicBreathingMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _initController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null) return;
    if (state == AppLifecycleState.resumed && widget.enabled) {
      if (!c.isAnimating) c.repeat(reverse: true);
    } else {
      c.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _controller == null) return widget.child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale!.value,
            alignment: Alignment.bottomCenter,
            child: Opacity(opacity: _opacity!.value, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}
