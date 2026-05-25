import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_visual_tokens.dart';

/// حالة فارغة سينمائية — بدون نصوص placeholder تقنية.
class PremiumEmptyState extends StatelessWidget {
  const PremiumEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.emoji_events_outlined,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final identity = CrowdAppIdentity.current;
    final tokens = StadiumVisualTokens.of(identity);
    final isDark = tokens.isAhly;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: compact ? 20 : 28,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: identity.primaryColor.withValues(alpha: 0.28),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.black.withValues(alpha: 0.35),
                ]
              : [
                  Colors.white.withValues(alpha: 0.85),
                  const Color(0xFFE8EAEE).withValues(alpha: 0.6),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: identity.primaryColor.withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 28 : 36,
            color: identity.primaryColor.withValues(alpha: 0.9),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A1A1E),
              fontWeight: FontWeight.w800,
              fontSize: compact ? 14 : 16,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF5C5C66),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
