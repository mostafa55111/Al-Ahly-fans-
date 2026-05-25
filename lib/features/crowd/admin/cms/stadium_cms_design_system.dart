import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/admin_control_visual_system.dart';

enum StadiumCmsSemantic {
  primary,
  live,
  warning,
  destructive,
  transient,
  idle,
}

/// توكنات تجميد UX — مقياس محدود فقط (spacing · type · touch · semantic · elevation · motion).
abstract final class StadiumCmsDesign {
  // — spacing scale
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;

  // — touch system
  static const double minTouchTarget = 44;
  static const double chipHeight = 40;

  // — typography scale
  static const double typeTitle = 16;
  static const double typeBody = 13;
  static const double typeCaption = 11;

  // — shape
  static const double cardRadius = 12;

  // — elevation hierarchy (0 = flat surface, 1 = card, 2 = emphasis)
  static const double elevationFlat = 0;
  static const double elevationCard = 1;
  static const double elevationEmphasis = 3;

  // — motion
  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionNormal = Duration(milliseconds: 240);
  static const Curve motionEase = Curves.easeOutCubic;

  // — surfaces
  static const Color scaffoldBg = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF151515);
  static const Color surfaceElevated = Color(0xFF181818);

  // — semantic colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF8A8A8A);
  static const Color borderSubtle = Color(0xFF2A2A2A);
  static const Color semanticLive = Color(0xFF4CAF50);
  static const Color semanticWarning = Color(0xFFFFB74D);
  static const Color semanticDestructive = Color(0xFFEF5350);
  static const Color semanticTransient = Color(0xFF64B5F6);

  static TextStyle title(CrowdAppIdentity id) => TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: typeTitle,
        letterSpacing: id.teamType == CrowdTeamType.ahly ? 0.2 : 0.4,
      );

  static const TextStyle subtitle = TextStyle(
    color: textSecondary,
    fontSize: typeBody,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    color: textMuted,
    fontSize: typeCaption,
  );

  static Color semanticColor(StadiumCmsSemantic s, CrowdAppIdentity id) {
    switch (s) {
      case StadiumCmsSemantic.primary:
        return id.primaryColor;
      case StadiumCmsSemantic.live:
        return semanticLive;
      case StadiumCmsSemantic.warning:
        return semanticWarning;
      case StadiumCmsSemantic.destructive:
        return semanticDestructive;
      case StadiumCmsSemantic.transient:
        return semanticTransient;
      case StadiumCmsSemantic.idle:
        return textMuted;
    }
  }

  static EdgeInsets pagePadding = const EdgeInsets.fromLTRB(spaceMd, spaceMd, spaceMd, 88);

  static InputDecoration fieldDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textSecondary, fontSize: typeBody),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
        ),
      );

  static ButtonStyle primaryButton(CrowdAppIdentity id) => FilledButton.styleFrom(
        minimumSize: const Size(0, minTouchTarget),
        backgroundColor: id.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      );

  static ButtonStyle liveButton() => FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(minTouchTarget),
        backgroundColor: semanticLive.withValues(alpha: 0.85),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      );

  static ButtonStyle destructiveOutlined() => OutlinedButton.styleFrom(
        minimumSize: const Size(0, minTouchTarget),
        foregroundColor: semanticDestructive,
        side: const BorderSide(color: semanticDestructive),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      );

  static ButtonStyle tonalButton(CrowdAppIdentity id) => FilledButton.styleFrom(
        minimumSize: const Size(0, minTouchTarget),
        backgroundColor: id.primaryColor.withValues(alpha: 0.18),
        foregroundColor: id.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      );

  static CardThemeData cardTheme() => const CardThemeData(
        color: surface,
        elevation: elevationCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      );

  static Widget sectionGap([double h = spaceMd]) => SizedBox(height: h);

  static Widget surfaceCard({
    required Widget child,
    double elevation = elevationCard,
    EdgeInsets padding = const EdgeInsets.all(spaceMd),
    CrowdAppIdentity? identity,
    bool glass = true,
  }) {
    if (glass) {
      return AdminControlVisualSystem.glassPanel(
        identity: identity,
        padding: padding,
        child: child,
      );
    }
    return Card(
      elevation: elevation,
      color: surface,
      child: Padding(padding: padding, child: child),
    );
  }

  static Widget statusChip({
    required String label,
    required StadiumCmsSemantic semantic,
    required CrowdAppIdentity identity,
    bool pulse = false,
  }) {
    final c = semanticColor(semantic, identity);
    return AnimatedContainer(
      duration: motionFast,
      curve: motionEase,
      padding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: pulse ? 0.28 : 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontSize: typeCaption, fontWeight: FontWeight.w700),
      ),
    );
  }

  static Widget sectionHeader(String text, CrowdAppIdentity id) {
    return Text(text, style: title(id));
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    String? hint,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: textMuted),
          sectionGap(spaceSm),
          Text(title, textAlign: TextAlign.center, style: subtitle.copyWith(color: textPrimary)),
          if (hint != null) ...[
            sectionGap(spaceXs),
            Text(hint, textAlign: TextAlign.center, style: caption),
          ],
          if (action != null) ...[sectionGap(spaceMd), action],
        ],
      ),
    );
  }

  static Widget loadingState() => inlineBusy(label: 'جاري التحميل…');

  static Widget inlineBusy({String label = 'جاري التنفيذ…'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: spaceSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: semanticTransient),
          ),
          const SizedBox(width: spaceSm),
          Text(label, style: caption.copyWith(color: semanticTransient)),
        ],
      ),
    );
  }

  static Widget errorState({
    required String message,
    VoidCallback? onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.all(spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: semanticWarning),
          sectionGap(spaceSm),
          Text(message, textAlign: TextAlign.center, style: subtitle),
          if (onRetry != null) ...[
            sectionGap(spaceMd),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    );
  }
}
