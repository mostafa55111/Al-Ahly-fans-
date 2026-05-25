import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/notifications/presentation/widgets/bow_arrow_notification_icon.dart';

/// ألوان الهوية لكل نادٍ — شارة صغيرة لا تزحم الواجهة.
abstract final class ClubBadgePalette {
  /// الأهلي: أحمر ملكي + ذهبي.
  static const Color ahlyRed = Color(0xFFC7102E);
  static const Color ahlyGold = Color(0xFFC5A059);

  /// الزمالك: أبيض على أزرق ملكي.
  static const Color zamalekBlue = Color(0xFF00247D);
  static const Color zamalekAccent = Color(0xFFFFFFFF);
}

/// تطبيع قيمة [app_source] من Firestore / social_graph أو حقول مشابهة.
bool clubSourceIsAhly(String? raw) {
  final s = (raw ?? '').trim().toLowerCase();
  if (s.isEmpty) return false;
  if (s.contains('zamalek')) return false;
  return s.contains('ahly') || s.contains('gomhor');
}

bool clubSourceIsZamalek(String? raw) {
  final s = (raw ?? '').trim().toLowerCase();
  return s.contains('zamalek');
}

String? audienceToClubSource(String? audience) {
  final a = (audience ?? '').trim().toLowerCase();
  if (a.isEmpty || a == 'all') return null;
  if (a == 'ahly' || a == 'zamalek') return a;
  return a;
}

/// شارة انتماء النادي — نسر للأهلي، قوس وسهم للزمالك.
///
/// [appSource] مثل `gomhor_ahly` أو `zamalekawy` كما في [SocialGraphService].
class ClubBadge extends StatelessWidget {
  const ClubBadge({super.key, required this.appSource, this.size = 16});

  final String? appSource;
  final double size;

  /// من حقل `audience` في المنتج (`ahly` / `zamalek` / `all`).
  factory ClubBadge.forAudience(String? audience, {double size = 16}) {
    return ClubBadge(
      appSource: audienceToClubSource(audience),
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ahly = clubSourceIsAhly(appSource);
    final zamalek = clubSourceIsZamalek(appSource);
    if (!ahly && !zamalek) {
      return SizedBox(width: size, height: size);
    }
    if (ahly) {
      return _ahlyEagleBadge(size);
    }
    return _zamalekBowBadge(size);
  }

  Widget _ahlyEagleBadge(double s) {
    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ClubBadgePalette.ahlyRed,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ClubBadgePalette.ahlyGold, width: 0.8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '🦅',
          style: TextStyle(fontSize: s * 0.65, height: 1),
        ),
      ),
    );
  }

  Widget _zamalekBowBadge(double s) {
    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ClubBadgePalette.zamalekBlue,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: ClubBadgePalette.zamalekAccent.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: BowArrowNotificationIcon(
        color: ClubBadgePalette.zamalekAccent,
        size: s * 0.68,
      ),
    );
  }
}

/// صفّ واحد: اسم + شارة (للقوائم).
class UserNameWithClubBadge extends StatelessWidget {
  const UserNameWithClubBadge({
    super.key,
    required this.name,
    required this.appSource,
    this.style,
    this.badgeSize = 16,
    this.spacing = 6,
    this.maxLines = 1,
  });

  final String name;
  final String? appSource;
  final TextStyle? style;
  final double badgeSize;
  final double spacing;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        SizedBox(width: spacing),
        ClubBadge(appSource: appSource, size: badgeSize),
      ],
    );
  }
}
