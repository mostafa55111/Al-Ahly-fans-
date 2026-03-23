import 'package:equatable/equatable.dart';

/// كيان الإنجاز (Achievement)
/// يمثل إنجاز أو شارة يحصل عليها المستخدم
class AchievementEntity extends Equatable {
  /// معرف فريد للإنجاز
  final String id;
  
  /// اسم الإنجاز
  final String name;
  
  /// وصف الإنجاز
  final String description;
  
  /// رابط صورة الإنجاز
  final String imageUrl;
  
  /// نقاط الإنجاز
  final int points;
  
  /// مستوى الصعوبة (سهل، متوسط، صعب)
  final DifficultyLevel difficulty;
  
  /// نوع الإنجاز
  final AchievementType type;
  
  /// هل تم الحصول على الإنجاز
  final bool isUnlocked;
  
  /// وقت الحصول على الإنجاز
  final DateTime? unlockedAt;
  
  /// النسبة المئوية للإكمال (0-100)
  final int progressPercentage;
  
  /// الحد الأدنى للإكمال
  final int requiredCount;
  
  /// العدد الحالي
  final int currentCount;
  
  /// هل الإنجاز مثبت
  final bool isPinned;
  
  /// الترتيب
  final int order;

  const AchievementEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.points,
    required this.difficulty,
    required this.type,
    required this.isUnlocked,
    this.unlockedAt,
    required this.progressPercentage,
    required this.requiredCount,
    required this.currentCount,
    required this.isPinned,
    required this.order,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imageUrl,
    points,
    difficulty,
    type,
    isUnlocked,
    unlockedAt,
    progressPercentage,
    requiredCount,
    currentCount,
    isPinned,
    order,
  ];
}

/// مستويات الصعوبة
enum DifficultyLevel {
  easy,      // سهل
  medium,    // متوسط
  hard,      // صعب
  legendary, // أسطوري
}

/// أنواع الإنجازات
enum AchievementType {
  posts,          // الإنجازات المتعلقة بالمنشورات
  likes,          // الإنجازات المتعلقة بالإعجابات
  followers,      // الإنجازات المتعلقة بالمتابعين
  engagement,     // الإنجازات المتعلقة بالتفاعل
  streak,         // الإنجازات المتعلقة بالسلاسل
  voting,         // الإنجازات المتعلقة بالتصويت
  reels,          // الإنجازات المتعلقة بالريلز
  special,        // إنجازات خاصة
}

/// بيانات الشارة (Badge)
class BadgeEntity extends Equatable {
  /// معرف الشارة
  final String id;
  
  /// اسم الشارة
  final String name;
  
  /// صورة الشارة
  final String imageUrl;
  
  /// اللون المرتبط بالشارة
  final String color;
  
  /// وصف الشارة
  final String description;

  const BadgeEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.color,
    required this.description,
  });

  @override
  List<Object?> get props => [id, name, imageUrl, color, description];
}
