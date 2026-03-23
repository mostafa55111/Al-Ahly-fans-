import 'package:flutter/material.dart';

/// تأثيرات الإضاءة الحمراء المتقدمة للأزرار النشطة
class RedGlowEffect extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;

  const RedGlowEffect({
    super.key,
    required this.child,
    this.isActive = false,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<RedGlowEffect> createState() => _RedGlowEffectState();
}

class _RedGlowEffectState extends State<RedGlowEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(RedGlowEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(_glowAnimation.value * 0.6),
                blurRadius: 20 * _glowAnimation.value,
                spreadRadius: 5 * _glowAnimation.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// تأثير الموجة (Ripple) عند الضغط على الأزرار
class RippleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color rippleColor;

  const RippleEffect({
    super.key,
    required this.child,
    required this.onTap,
    this.rippleColor = Colors.red,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.5, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onTapDown() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTapDown,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.rippleColor.withOpacity(_opacityAnimation.value),
                  boxShadow: [
                    BoxShadow(
                      color: widget.rippleColor.withOpacity(_opacityAnimation.value),
                      blurRadius: 20 * _scaleAnimation.value,
                      spreadRadius: 10 * _scaleAnimation.value,
                    ),
                  ],
                ),
                transform: Matrix4.identity()..scale(_scaleAnimation.value + 1),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// تأثير الاهتزاز (Shake) عند حدوث خطأ
class ShakeEffect extends StatefulWidget {
  final Widget child;
  final bool trigger;

  const ShakeEffect({
    super.key,
    required this.child,
    this.trigger = false,
  });

  @override
  State<ShakeEffect> createState() => _ShakeEffectState();
}

class _ShakeEffectState extends State<ShakeEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(ShakeEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shake = 10 * (0.5 - (_controller.value - 0.5).abs());
        return Transform.translate(
          offset: Offset(shake, 0),
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// تأثير الرقص (Bounce) للأيقونات
class BounceEffect extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;

  const BounceEffect({
    super.key,
    required this.child,
    this.isActive = true,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<BounceEffect> createState() => _BounceEffectState();
}

class _BounceEffectState extends State<BounceEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BounceEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_bounceAnimation.value * 0.1),
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
