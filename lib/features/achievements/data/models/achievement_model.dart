import 'package:gomhor_alahly_clean_new/features/achievements/domain/entities/achievement_entity.dart';

/// نموذج Achievement للـ Data Layer
class AchievementModel extends AchievementEntity {
  const AchievementModel({
    required super.id,
    required String title,
    required super.description,
    required String icon,
    required super.points,
    required super.type,
    required super.difficulty,
    required int progress,
    required int maxProgress,
    required super.isUnlocked,
    required super.unlockedAt,
    required super.isPinned,
    required String category,
    required String rarity,
  }) : super(
    title: title,
    icon: icon,
    progress: progress,
    maxProgress: maxProgress,
    category: category,
    rarity: rarity,
  );

  /// تحويل من JSON
  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      type: _parseAchievementType(json['type'] as String?),
      difficulty: _parseDifficultyLevel(json['difficulty'] as String?),
      progress: json['progress'] as int? ?? 0,
      maxProgress: json['maxProgress'] as int? ?? 100,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      isPinned: json['isPinned'] as bool? ?? false,
      category: json['category'] as String? ?? '',
      rarity: json['rarity'] as String? ?? 'common',
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'points': points,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'progress': progress,
      'maxProgress': maxProgress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isPinned': isPinned,
      'category': category,
      'rarity': rarity,
    };
  }

  /// نسخ مع تعديل
  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? points,
    AchievementType? type,
    DifficultyLevel? difficulty,
    int? progress,
    int? maxProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    bool? isPinned,
    String? category,
    String? rarity,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      points: points ?? this.points,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      progress: progress ?? this.progress,
      maxProgress: maxProgress ?? this.maxProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
    );
  }
}

/// نموذج Badge للـ Data Layer
class BadgeModel extends BadgeEntity {
  const BadgeModel({
    required super.id,
    required super.name,
    required super.description,
    required String icon,
    required super.color,
    required bool isEarned,
    required DateTime? earnedAt,
    required String category,
  }) : super(
    icon: icon,
    isEarned: isEarned,
    earnedAt: earnedAt,
    category: category,
  );

  /// تحويل من JSON
  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      color: json['color'] as String? ?? '#000000',
      isEarned: json['isEarned'] as bool? ?? false,
      earnedAt: json['earnedAt'] != null
          ? DateTime.parse(json['earnedAt'] as String)
          : null,
      category: json['category'] as String? ?? '',
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'isEarned': isEarned,
      'earnedAt': earnedAt?.toIso8601String(),
      'category': category,
    };
  }

  /// نسخ مع تعديل
  BadgeModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    bool? isEarned,
    DateTime? earnedAt,
    String? category,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
      category: category ?? this.category,
    );
  }
}

/// دالة مساعدة لتحويل النص إلى AchievementType
AchievementType _parseAchievementType(String? value) {
  switch (value) {
    case 'social':
      return AchievementType.social;
    case 'match':
      return AchievementType.match;
    case 'leaderboard':
      return AchievementType.leaderboard;
    case 'special':
      return AchievementType.special;
    default:
      return AchievementType.social;
  }
}

/// دالة مساعدة لتحويل النص إلى DifficultyLevel
DifficultyLevel _parseDifficultyLevel(String? value) {
  switch (value) {
    case 'easy':
      return DifficultyLevel.easy;
    case 'medium':
      return DifficultyLevel.medium;
    case 'hard':
      return DifficultyLevel.hard;
    case 'expert':
      return DifficultyLevel.expert;
    default:
      return DifficultyLevel.easy;
  }
}
