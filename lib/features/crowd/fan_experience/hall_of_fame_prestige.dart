import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/identity/club_award_labels.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_visual_tokens.dart';

/// تغليف هيبة قاعة الشرف — spacing وtypography فقط.
class HallOfFamePrestigeFrame extends StatelessWidget {
  const HallOfFamePrestigeFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.featured = false,
    this.identity,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool featured;
  final CrowdAppIdentity? identity;

  @override
  Widget build(BuildContext context) {
    final id = identity ?? CrowdAppIdentity.current;
    final tokens = StadiumVisualTokens.of(id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: featured ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: featured ? 22 : 18,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: tokens.primary.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(featured ? 20 : 16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: featured ? 14 : 10,
              sigmaY: featured ? 14 : 10,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(featured ? 20 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    tokens.primary.withValues(alpha: featured ? 0.12 : 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(featured ? 20 : 16),
                border: Border.all(
                  color: featured
                      ? tokens.secondary.withValues(alpha: 0.35)
                      : tokens.glassBorder,
                  width: featured ? 1.2 : 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

/// عنوان تبويب قاعة الشرف في الشريط العلوي.
String hallOfFameTabLabel() => ClubAwardLabels.hallOfFameTab;
