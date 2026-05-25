import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';

/// هوية ناعمة للنادي — بدون شعارات ضخمة.
class PremiumCardClubIdentity {
  const PremiumCardClubIdentity({
    required this.ambientWarmth,
    required this.prestigeAccent,
    required this.edgeHighlight,
    required this.nameAccent,
    required this.scrimTint,
  });

  final Color ambientWarmth;
  final Color prestigeAccent;
  final Color edgeHighlight;
  final Color nameAccent;
  final Color scrimTint;

  static PremiumCardClubIdentity current({Color? primary, Color? secondary}) {
    final isAhly = FanAppIdentity.registryAppId == 'ahly';
    if (isAhly) {
      final red = primary ?? const Color(0xFFC8102E);
      final gold = secondary ?? const Color(0xFFFFD54F);
      return PremiumCardClubIdentity(
        ambientWarmth: red.withValues(alpha: 0.18),
        prestigeAccent: gold,
        edgeHighlight: gold.withValues(alpha: 0.55),
        nameAccent: gold.withValues(alpha: 0.92),
        scrimTint: const Color(0xFF1A0808),
      );
    }
    final white = secondary ?? Colors.white;
    final graphite = primary ?? const Color(0xFF2A2D34);
    return PremiumCardClubIdentity(
      ambientWarmth: graphite.withValues(alpha: 0.22),
      prestigeAccent: white.withValues(alpha: 0.92),
      edgeHighlight: white.withValues(alpha: 0.48),
      nameAccent: white.withValues(alpha: 0.9),
      scrimTint: const Color(0xFF101218),
    );
  }
}
