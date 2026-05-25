import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_broadcast_layout.dart';

/// ثوابت بصرية موحّدة لملعب ليلة المباراة — بدون streams.
class StadiumVisualTokens {
  StadiumVisualTokens._(this.identity);

  final CrowdAppIdentity identity;

  static StadiumVisualTokens of(CrowdAppIdentity? id) =>
      StadiumVisualTokens._(id ?? CrowdAppIdentity.current);

  bool get isAhly => FanAppIdentity.registryAppId == 'ahly';

  Color get primary => identity.primaryColor;
  Color get secondary => identity.secondaryColor;
  Color get accentGlow => identity.accentGlow;
  Color get tacticalLine => identity.tacticalLineAccent;

  /// تبويب نشط — أحمر الأهلي / أبيض الزمالك.
  Color get activeTabFill => primary.withValues(alpha: isAhly ? 0.92 : 0.88);

  Color get glassFill => Colors.black.withValues(alpha: 0.42);
  Color get glassBorder => Colors.white.withValues(alpha: 0.14);

  /// توهج الكارت — ذهبي ناعم للأهلي، أبيض/أزرق خفيف للزمالك.
  Color get cardGlow => isAhly
      ? const Color(0xFFFFD700).withValues(alpha: 0.42)
      : Colors.white.withValues(alpha: 0.38);

  double get cardGlowBlur => isAhly ? 18 : 14;

  /// التصميم النهائي: Subs + Reserves + هيدر النادي (ويدجتات، ليس صورة ثابتة).
  bool get useBroadcastStadiumLayout => StadiumBroadcastLayout.enabled;

  double get vignetteEdgeAlpha => useBroadcastStadiumLayout ? 0.06 : 0.52;
  double get pitchDimAlpha => useBroadcastStadiumLayout ? 0.0 : 0.22;
  /// الملعب من [StadiumFoundationLayer] — opacity دائماً كاملة.
  double get stadiumImageOpacity => 1.0;

  /// خطوط تكتيكية قديمة — معطّلة بعد Foundation rebuild.
  bool get showPitchTacticalOverlay => false;

  BorderRadius get tabRadius => BorderRadius.circular(16);
  BorderRadius get pillRadius => BorderRadius.circular(12);

  TextStyle get tabLabelActive => const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 13,
        color: Colors.white,
      );

  TextStyle get tabLabelInactive => TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.72),
      );
}
