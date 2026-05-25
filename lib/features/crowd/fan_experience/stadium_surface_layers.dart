import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_foundation/stadium_foundation_safe_layout.dart';

/// @deprecated استخدم [StadiumFoundationSafeLayout] — يُبقى للتوافق مع CMS.
class StadiumSurfaceLayers extends StatelessWidget {
  const StadiumSurfaceLayers({
    super.key,
    required this.child,
    this.breathPhase01 = 0,
    this.phase,
  });

  final Widget child;
  final double breathPhase01;
  final Object? phase;

  @override
  Widget build(BuildContext context) {
    return StadiumFoundationSafeLayout(
      applySafeAreaToChild: false,
      child: child,
    );
  }
}
