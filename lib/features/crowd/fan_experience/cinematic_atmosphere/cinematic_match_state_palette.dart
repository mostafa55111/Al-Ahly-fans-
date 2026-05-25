import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';

/// ألوان وجو كل طور ليلة المباراة — أهلي / زمالك.
class CinematicMatchPalette {
  const CinematicMatchPalette({
    required this.phase,
    required this.ambientColor,
    required this.highlightColor,
    required this.ambientOpacity,
    required this.fieldDarkness,
    required this.vignetteEdge,
    required this.glowWarmth,
    required this.focusIntensity,
  });

  final MatchNightPhase phase;
  final Color ambientColor;
  final Color highlightColor;
  final double ambientOpacity;
  final double fieldDarkness;
  final double vignetteEdge;
  final double glowWarmth;
  final double focusIntensity;

  static CinematicMatchPalette forPhase(
    MatchNightPhase phase, {
    CrowdAppIdentity? identity,
  }) {
    final id = identity ?? CrowdAppIdentity.current;
    final isAhly = FanAppIdentity.registryAppId == 'ahly';

    final ambient = isAhly
        ? Color.lerp(const Color(0xFF1A0505), id.primaryColor, 0.35)!
        : const Color(0xFF121418);
    final highlight = isAhly
        ? const Color(0xFFFFD54F)
        : Colors.white.withValues(alpha: 0.92);

    final base = _phaseScalars(phase);
    return CinematicMatchPalette(
      phase: phase,
      ambientColor: ambient,
      highlightColor: highlight,
      ambientOpacity: base.ambient * (isAhly ? 1.0 : 0.88),
      fieldDarkness: base.darkness,
      vignetteEdge: base.vignette,
      glowWarmth: base.warmth * (isAhly ? 1.08 : 0.82),
      focusIntensity: base.focus,
    );
  }

  static ({double ambient, double darkness, double vignette, double warmth, double focus})
      _phaseScalars(MatchNightPhase phase) {
    return switch (phase) {
      MatchNightPhase.preMatch => (
          ambient: 0.22,
          darkness: 0.18,
          vignette: 0.48,
          warmth: 0.55,
          focus: 0.45,
        ),
      MatchNightPhase.liveVoting => (
          ambient: 0.28,
          darkness: 0.12,
          vignette: 0.42,
          warmth: 0.72,
          focus: 0.78,
        ),
      MatchNightPhase.closingSoon => (
          ambient: 0.34,
          darkness: 0.14,
          vignette: 0.46,
          warmth: 0.85,
          focus: 0.88,
        ),
      MatchNightPhase.finalizing => (
          ambient: 0.38,
          darkness: 0.26,
          vignette: 0.54,
          warmth: 0.5,
          focus: 0.55,
        ),
      MatchNightPhase.winnerReveal => (
          ambient: 0.32,
          darkness: 0.20,
          vignette: 0.50,
          warmth: 0.95,
          focus: 1.0,
        ),
      MatchNightPhase.hallOfFame => (
          ambient: 0.26,
          darkness: 0.22,
          vignette: 0.52,
          warmth: 0.62,
          focus: 0.4,
        ),
    };
  }
}
