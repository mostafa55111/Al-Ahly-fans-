import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom Loading Widget with consistent styling
class LoadingWidget extends StatelessWidget {
  final double? size;
  final Color? color;
  final String? message;
  final bool isFullScreen;
  final Widget? child;

  const LoadingWidget({
    super.key,
    this.size,
    this.color,
    this.message,
    this.isFullScreen = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final loadingContent = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSpinner(),
        if (message != null) ...[
          const SizedBox(height: 16),
          _buildMessage(),
        ],
      ],
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: loadingContent),
      );
    }

    if (child != null) {
      return Stack(
        children: [
          child!,
          Container(
            color: AppColors.background.withAlpha(128),
            child: Center(child: loadingContent),
          ),
        ],
      );
    }

    return Center(child: loadingContent);
  }

  Widget _buildSpinner() {
    return SizedBox(
      width: size ?? 24,
      height: size ?? 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildMessage() {
    return Text(
      message!,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Small Loading Indicator
class SmallLoadingWidget extends StatelessWidget {
  final Color? color;
  final double? size;

  const SmallLoadingWidget({
    super.key,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 16,
      height: size ?? 16,
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}

/// Loading Button Widget
class LoadingButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonStyle? style;
  final TextStyle? textStyle;
  final Widget? icon;

  const LoadingButtonWidget({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.style,
    this.textStyle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style ?? ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 4,
        shadowColor: AppColors.primaryWithOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: isLoading
          ? const SmallLoadingWidget()
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  const Icon(Icons.refresh),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: textStyle ?? const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Skeleton Loading Widget
class SkeletonLoadingWidget extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoadingWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.surfaceWithOpacity(0.5),
            AppColors.surface,
          ],
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
        ),
      ),
    );
  }
}

/// Animated Loading Widget with Fade Transition
class AnimatedLoadingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool isLoading;

  const AnimatedLoadingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.isLoading = true,
  });

  @override
  State<AnimatedLoadingWidget> createState() => _AnimatedLoadingWidgetState();
}

class _AnimatedLoadingWidgetState extends State<AnimatedLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedLoadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.isLoading ? const LoadingWidget() : widget.child,
    );
  }
}
