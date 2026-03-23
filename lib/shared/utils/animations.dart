import 'package:flutter/material.dart';

/// Animation Utilities
class AnimationUtils {
  /// Slide Transition
  static Widget slideTransition({
    required Animation<Offset> animation,
    required Widget child,
  }) {
    return SlideTransition(
      position: animation,
      child: child,
    );
  }

  /// Fade Transition
  static Widget fadeTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Scale Transition
  static Widget scaleTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  /// Rotation Transition
  static Widget rotationTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return RotationTransition(
      turns: animation,
      child: child,
    );
  }

  /// Size Transition
  static Widget sizeTransition({
    required Animation<double> animation,
    required Widget child,
    Axis axis = Axis.vertical,
  }) {
    return SizeTransition(
      sizeFactor: animation,
      axis: axis,
      child: child,
    );
  }

  /// Bounce Animation
  static Future<void> bounceAnimation({
    required AnimationController controller,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    await controller.forward();
    await controller.reverse();
  }

  /// Pulse Animation
  static Future<void> pulseAnimation({
    required AnimationController controller,
    Duration duration = const Duration(milliseconds: 1000),
  }) async {
    controller.repeat(reverse: true);
  }

  /// Shake Animation
  static Widget shakeAnimation({
    required Animation<double> animation,
    required Widget child,
  }) {
    return Transform.translate(
      offset: Offset(animation.value * 10, 0),
      child: child,
    );
  }
}

/// Custom Page Route Transitions
class CustomPageRoute<T> extends PageRoute<T> {
  final Widget Function(
    BuildContext,
    Animation<double>,
    Animation<double>,
    Widget,
  ) transitionsBuilder;
  final Widget page;
  @override
  final Duration transitionDuration;
  final Curve curve;

  CustomPageRoute({
    required this.page,
    required this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    super.settings,
  });

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return transitionsBuilder(context, animation, secondaryAnimation, child);
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;
}

/// Slide Page Route
class SlidePageRoute<T> extends CustomPageRoute<T> {
  SlidePageRoute({
    required super.page,
    super.transitionDuration,
    super.curve,
    super.settings,
  }) : super(
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: curve)),
        child: child,
      );
    },
  );
}

/// Fade Page Route
class FadePageRoute<T> extends CustomPageRoute<T> {
  FadePageRoute({
    required super.page,
    super.transitionDuration,
    super.curve,
    super.settings,
  }) : super(
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: curve),
        child: child,
      );
    },
  );
}

/// Scale Page Route
class ScalePageRoute<T> extends CustomPageRoute<T> {
  ScalePageRoute({
    required super.page,
    super.transitionDuration,
    super.curve,
    super.settings,
  }) : super(
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: animation, curve: curve),
        ),
        child: child,
      );
    },
  );
}

/// Rotation Page Route
class RotationPageRoute<T> extends CustomPageRoute<T> {
  RotationPageRoute({
    required super.page,
    super.transitionDuration,
    super.curve,
    super.settings,
  }) : super(
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return RotationTransition(
        turns: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: animation, curve: curve),
        ),
        child: child,
      );
    },
  );
}

/// Animated Container Helper
class AnimatedContainerHelper extends StatefulWidget {
  final Duration duration;
  final Color color;
  final double width;
  final double height;
  final Widget? child;
  final Curve curve;

  const AnimatedContainerHelper({
    super.key,
    this.duration = const Duration(milliseconds: 300),
    required this.color,
    required this.width,
    required this.height,
    this.child,
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedContainerHelper> createState() =>
      _AnimatedContainerHelperState();
}

class _AnimatedContainerHelperState extends State<AnimatedContainerHelper> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.duration,
      curve: widget.curve,
      color: widget.color,
      width: widget.width,
      height: widget.height,
      child: widget.child,
    );
  }
}

/// Staggered Animation Helper
class StaggeredAnimationHelper extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration duration;
  final Curve curve;

  const StaggeredAnimationHelper({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
  });

  @override
  State<StaggeredAnimationHelper> createState() =>
      _StaggeredAnimationHelperState();
}

class _StaggeredAnimationHelperState extends State<StaggeredAnimationHelper>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        widget.children.length,
        (index) => FadeTransition(
          opacity: _controllers[index],
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(_controllers[index]),
            child: widget.children[index],
          ),
        ),
      ),
    );
  }
}
