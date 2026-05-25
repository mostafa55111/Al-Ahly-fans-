import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_visual_tokens.dart';

/// ثيم غرفة التحكم — بث رياضي، ليس لوحة إدارة تقليدية.
class ControlRoomTheme {
  ControlRoomTheme._(this.tokens, this.identity);

  final StadiumVisualTokens tokens;
  final CrowdAppIdentity identity;

  factory ControlRoomTheme.of(CrowdAppIdentity? id) {
    final identity = id ?? CrowdAppIdentity.current;
    return ControlRoomTheme._(StadiumVisualTokens.of(identity), identity);
  }

  Color get scaffold => tokens.isAhly ? const Color(0xFF08080A) : const Color(0xFFF4F5F7);

  Color get surface => tokens.isAhly ? const Color(0xFF141418) : Colors.white;

  Color get surfaceElevated =>
      tokens.isAhly ? const Color(0xFF1C1C22) : const Color(0xFFFAFAFC);

  Color get border => tokens.glassBorder;

  Color get primaryText => tokens.isAhly ? Colors.white : const Color(0xFF1A1A1E);

  Color get secondaryText =>
      tokens.isAhly ? Colors.white70 : const Color(0xFF5C5C66);

  LinearGradient get headerGradient => tokens.isAhly
      ? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            identity.primaryColor.withValues(alpha: 0.35),
            const Color(0xFF08080A),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF0F1F4)],
        );

  BoxDecoration panelDecoration({double radius = 16}) => BoxDecoration(
        color: surface.withValues(alpha: tokens.isAhly ? 0.92 : 0.98),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      );
}
