import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/fan_presence/fan_crowd_rank_system.dart';

/// هالة حضور خفيفة حول كرت اختيار المستخدم — بدون controllers إضافية.
class FanPresenceAuraRing extends StatelessWidget {
  const FanPresenceAuraRing({
    super.key,
    required this.child,
    required this.aura,
    required this.accent,
    this.phase01 = 0,
    this.enabled = true,
  });

  final Widget child;
  final FanPresenceAuraStyle aura;
  final Color accent;
  final double phase01;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || aura.strength < 0.1) return child;
    final pulse = 0.5 + 0.5 * math.sin(phase01 * math.pi * 2);
    final alpha = (aura.strength * (0.35 + 0.25 * pulse)).clamp(0.08, 0.55);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: alpha),
            blurRadius: 14 + aura.strength * 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
