import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_foundation/stadium_foundation_safe_layout.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_visual_tokens.dart';

/// هوية بصرية لوحة التحكم — نفس tokens المشجع، سطح owner منفصل.
class AdminControlVisualSystem {
  AdminControlVisualSystem._();

  static StadiumVisualTokens tokens(CrowdAppIdentity identity) =>
      StadiumVisualTokens.of(identity);

  static BoxDecoration scaffoldDecoration(CrowdAppIdentity identity) {
    final t = tokens(identity);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF050505),
          t.primary.withValues(alpha: 0.08),
          const Color(0xFF0A0A0A),
        ],
      ),
    );
  }

  static PreferredSizeWidget cmsAppBar({
    required CrowdAppIdentity identity,
    required String title,
    PreferredSizeWidget? bottom,
  }) {
    final t = tokens(identity);
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          color: Colors.white,
          shadows: [
            Shadow(color: t.primary.withValues(alpha: 0.45), blurRadius: 8),
          ],
        ),
      ),
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.72),
                  t.primary.withValues(alpha: 0.22),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: t.glassBorder),
              ),
            ),
          ),
        ),
      ),
      foregroundColor: Colors.white,
      bottom: bottom,
    );
  }

  static Widget glassTabBar({
    required TabController controller,
    required List<String> labels,
    required CrowdAppIdentity identity,
  }) {
    final t = tokens(identity);
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: ClipRRect(
          borderRadius: t.tabRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: t.glassFill,
                borderRadius: t.tabRadius,
                border: Border.all(color: t.glassBorder),
              ),
              child: TabBar(
                controller: controller,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: t.pillRadius,
                  color: t.activeTabFill,
                  boxShadow: [
                    BoxShadow(
                      color: t.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: t.tabLabelActive.copyWith(fontSize: 12),
                unselectedLabelStyle: t.tabLabelInactive.copyWith(fontSize: 12),
                tabs: [for (final l in labels) Tab(text: l)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget glassPanel({
    required Widget child,
    CrowdAppIdentity? identity,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    bool featured = false,
  }) {
    final id = identity ?? CrowdAppIdentity.current;
    final t = tokens(id);
    const radius = 12.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(featured ? 16 : radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: featured ? 14 : 10,
          sigmaY: featured ? 14 : 10,
        ),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: featured ? 0.52 : 0.45),
            borderRadius: BorderRadius.circular(featured ? 16 : radius),
            border: Border.all(
              color: featured
                  ? t.secondary.withValues(alpha: 0.28)
                  : t.glassBorder,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// معاينة الملعب في CMS — نفس طبقات المشجع بدون cubit إضافي.
  static Widget cmsPitchPreview({
    required Widget child,
    CrowdAppIdentity? identity,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 420,
        child: StadiumFoundationSafeLayout(
          applySafeAreaToChild: false,
          child: child,
        ),
      ),
    );
  }

  static Widget entryTile({
    required CrowdAppIdentity identity,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final t = tokens(identity);
    return AdminControlVisualSystem.glassPanel(
      identity: identity,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: t.secondary),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
          ),
        ),
        trailing: Icon(Icons.chevron_left, color: t.primary.withValues(alpha: 0.7)),
        onTap: onTap,
      ),
    );
  }
}
