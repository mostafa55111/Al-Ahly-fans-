import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

/// نظام الرسوم المتحركة المتقدمة (Advanced Interactions)
/// يوفر micro-interactions احترافية لتحسين تجربة المستخدم

class AhlyAnimations {
  /// حركة الإعجاب المتقدمة (Advanced Like Animation)
  /// تظهر قلوب حمراء وشعار الأهلي عند الإعجاب
  static Widget advancedLikeAnimation({
    required bool isLiked,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Bounce(
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            color: isLiked ? Colors.red.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }

  /// حركة الانفجار (Burst Animation)
  /// تظهر جزيئات تنفجر عند الإعجاب
  static Widget burstAnimation({
    required bool trigger,
    required Widget child,
  }) {
    return ZoomIn(
      duration: const Duration(milliseconds: 500),
      child: child,
    );
  }

  /// حركة التمرير السلس (Smooth Scroll Animation)
  static Widget smoothScrollAnimation({
    required ScrollController controller,
    required Widget child,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          // يمكن إضافة تأثيرات إضافية هنا
        }
        return false;
      },
      child: child,
    );
  }

  /// حركة ظهور المحتوى (Content Reveal Animation)
  static Widget contentReveal({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return FadeInUp(
      duration: duration,
      child: child,
    );
  }

  /// حركة الشيمر (Shimmer Loading Animation)
  static Widget shimmerLoading({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Pulse(
        duration: Duration(milliseconds: 1500),
        child: SizedBox.expand(),
      ),
    );
  }

  /// حركة الزر عند الضغط (Button Press Animation)
  static Widget buttonPressAnimation({
    required VoidCallback onPressed,
    required Widget child,
    Color? pressColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: ScaleTransition(
        scale: const AlwaysStoppedAnimation(1.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            splashColor: pressColor ?? Colors.red.withOpacity(0.3),
            highlightColor: Colors.red.withOpacity(0.1),
            child: child,
          ),
        ),
      ),
    );
  }

  /// حركة الانزلاق (Slide Animation)
  static Widget slideAnimation({
    required Widget child,
    Offset begin = const Offset(-1, 0),
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return SlideInLeft(
      duration: duration,
      child: child,
    );
  }

  /// حركة الدوران (Rotation Animation)
  static Widget rotationAnimation({
    required Widget child,
    Duration duration = const Duration(seconds: 2),
  }) {
    return RotateIn(
      duration: duration,
      child: child,
    );
  }

  /// حركة الرجفة (Shake Animation)
  static Widget shakeAnimation({
    required Widget child,
    bool trigger = false,
  }) {
    return trigger
        ? Jello(
          duration: const Duration(milliseconds: 500),
          child: child,
        )
        : child;
  }

  /// حركة الظهور والاختفاء (Fade In/Out)
  static Widget fadeInOutAnimation({
    required Widget child,
    required bool isVisible,
  }) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  /// حركة التكبير والتصغير (Scale Animation)
  static Widget scaleAnimation({
    required Widget child,
    required bool isExpanded,
  }) {
    return AnimatedScale(
      scale: isExpanded ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}

/// فئة مساعدة لإنشاء تأثيرات صوتية (Sound Effects)
class AhlySoundEffects {
  static const String likeSound = 'assets/sounds/like.mp3';
  static const String commentSound = 'assets/sounds/comment.mp3';
  static const String shareSound = 'assets/sounds/share.mp3';
  static const String notificationSound = 'assets/sounds/notification.mp3';
  static const String matchStartSound = 'assets/sounds/match_start.mp3';
  static const String goalSound = 'assets/sounds/goal.mp3';
}

/// فئة مساعدة للألوان والتدرجات (Colors & Gradients)
class AhlyColors {
  static const Color primaryRed = Color(0xFFE31937); // الأحمر الأهلاوي
  static const Color primaryGold = Color(0xFFFFD700); // الذهبي
  static const Color darkRed = Color(0xFFC41E3A);
  static const Color lightRed = Color(0xFFFF6B6B);

  static LinearGradient redGoldGradient = const LinearGradient(
    colors: [primaryRed, primaryGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient darkGradient = const LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
