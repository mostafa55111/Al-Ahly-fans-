import 'package:equatable/equatable.dart';

/// كيان شارة المستخدم (User Badge Entity)
/// نظام الرتب والشارات لتحفيز التفاعل
class UserBadgeEntity extends Equatable {
  final String id;
  final String userId;
  final String badgeType; // 'gold-fan', 'historian', 'match-analyst', 'content-creator', 'community-leader'
  final String badgeName;
  final String badgeIcon;
  final String description;
  final int level; // 1-5 (Bronze, Silver, Gold, Platinum, Diamond)
  final int pointsRequired;
  final int currentPoints;
  final DateTime earnedAt;
  final bool isActive;

  const UserBadgeEntity({
    required this.id,
    required this.userId,
    required this.badgeType,
    required this.badgeName,
    required this.badgeIcon,
    required this.description,
    required this.level,
    required this.pointsRequired,
    required this.currentPoints,
    required this.earnedAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    badgeType,
    badgeName,
    badgeIcon,
    description,
    level,
    pointsRequired,
    currentPoints,
    earnedAt,
    isActive,
  ];
}

/// أنواع الشارات المتاحة
class BadgeTypes {
  static const String goldFan = 'gold-fan'; // المشجع الذهبي
  static const String historian = 'historian'; // المؤرخ الأهلاوي
  static const String matchAnalyst = 'match-analyst'; // محلل المباريات
  static const String contentCreator = 'content-creator'; // منتج المحتوى
  static const String communityLeader = 'community-leader'; // قائد المجتمع
  static const String earlyAdopter = 'early-adopter'; // المتبني المبكر
  static const String eventAttendee = 'event-attendee'; // حضور الفعاليات
  static const String philanthropist = 'philanthropist'; // المتبرع

  static List<String> getAllBadges() => [
    goldFan,
    historian,
    matchAnalyst,
    contentCreator,
    communityLeader,
    earlyAdopter,
    eventAttendee,
    philanthropist,
  ];
}
