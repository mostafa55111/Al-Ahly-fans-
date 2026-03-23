import 'package:equatable/equatable.dart';

/// كيان لوحة المتصدرين (Leaderboard)
/// تعرض أفضل المشجعين بناءً على النقاط
class LeaderboardEntity extends Equatable {
  /// الترتيب
  final int rank;
  
  /// معرف المستخدم
  final String userId;
  
  /// اسم المستخدم
  final String userName;
  
  /// صورة الملف الشخصي
  final String profileImage;
  
  /// النقاط الإجمالية
  final int totalPoints;
  
  /// نقاط هذا الأسبوع
  final int weeklyPoints;
  
  /// نقاط هذا الشهر
  final int monthlyPoints;
  
  /// عدد الإنجازات المفتوحة
  final int achievementsCount;
  
  /// عدد المتابعين
  final int followersCount;
  
  /// عدد المنشورات
  final int postsCount;
  
  /// هل المستخدم معروف (Verified)
  final bool isVerified;
  
  /// هل هذا المستخدم الحالي
  final bool isCurrentUser;
  
  /// المستوى (Level)
  final int level;
  
  /// النسبة المئوية للمستوى التالي
  final int nextLevelProgress;

  const LeaderboardEntity({
    required this.rank,
    required this.userId,
    required this.userName,
    required this.profileImage,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.monthlyPoints,
    required this.achievementsCount,
    required this.followersCount,
    required this.postsCount,
    required this.isVerified,
    required this.isCurrentUser,
    required this.level,
    required this.nextLevelProgress,
  });

  @override
  List<Object?> get props => [
    rank,
    userId,
    userName,
    profileImage,
    totalPoints,
    weeklyPoints,
    monthlyPoints,
    achievementsCount,
    followersCount,
    postsCount,
    isVerified,
    isCurrentUser,
    level,
    nextLevelProgress,
  ];
}

/// نوع لوحة المتصدرين
enum LeaderboardType {
  overall,  // الترتيب العام
  weekly,   // الترتيب الأسبوعي
  monthly,  // الترتيب الشهري
  friends,  // ترتيب الأصدقاء
}

/// نقاط المستويات
class LevelEntity extends Equatable {
  /// رقم المستوى
  final int level;
  
  /// اسم المستوى
  final String name;
  
  /// النقاط المطلوبة للوصول لهذا المستوى
  final int requiredPoints;
  
  /// صورة المستوى
  final String imageUrl;
  
  /// اللون المرتبط بالمستوى
  final String color;
  
  /// الوصف
  final String description;

  const LevelEntity({
    required this.level,
    required this.name,
    required this.requiredPoints,
    required this.imageUrl,
    required this.color,
    required this.description,
  });

  @override
  List<Object?> get props => [
    level,
    name,
    requiredPoints,
    imageUrl,
    color,
    description,
  ];
}
