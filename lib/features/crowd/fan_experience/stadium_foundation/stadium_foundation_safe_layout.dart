import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_foundation/stadium_foundation_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_foundation/stadium_foundation_tokens.dart';

/// ملعب كامل الشاشة + محتوى آمن فوقه (notch / شاشات طويلة).
class StadiumFoundationSafeLayout extends StatelessWidget {
  const StadiumFoundationSafeLayout({
    super.key,
    required this.child,
    this.applySafeAreaToChild = true,
  });

  final Widget child;

  /// false = الملعب يملأ الشاشة والـ child يُرسم فوقه بدون inset (مثل طبقة التصويت).
  final bool applySafeAreaToChild;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content = child;
        if (applySafeAreaToChild) {
          content = SafeArea(
            minimum: StadiumFoundationTokens.safeMinimum,
            maintainBottomViewPadding: true,
            child: child,
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: StadiumFoundationLayer()),
            Positioned.fill(child: content),
          ],
        );
      },
    );
  }
}
