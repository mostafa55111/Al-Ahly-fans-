import 'package:gomhor_alahly_clean_new/features/leaderboard/domain/entities/leaderboard_entity.dart';

/// نموذج Leaderboard للـ Data Layer
class LeaderboardModel extends LeaderboardEntity {
  const LeaderboardModel({
    required super.rank,
    required super.userId,
    required super.userName,
    required super.profileImage,
    required super.totalPoints,
    required super.weeklyPoints,
    required super.monthlyPoints,
    required super.achievementsCount,
    required super.followersCount,
    required super.postsCount,
    required super.isVerified,
    required super.isCurrentUser,
    required super.level,
    required super.nextLevelProgress,
  });

  /// تحويل من JSON
  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      rank: json['rank'] as int? ?? 0,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      profileImage: json['profileImage'] as String? ?? '',
      totalPoints: json['totalPoints'] as int? ?? 0,
      weeklyPoints: json['weeklyPoints'] as int? ?? 0,
      monthlyPoints: json['monthlyPoints'] as int? ?? 0,
      achievementsCount: json['achievementsCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      postsCount: json['postsCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      level: json['level'] as int? ?? 1,
      nextLevelProgress: json['nextLevelProgress'] as int? ?? 0,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'userName': userName,
      'profileImage': profileImage,
      'totalPoints': totalPoints,
      'weeklyPoints': weeklyPoints,
      'monthlyPoints': monthlyPoints,
      'achievementsCount': achievementsCount,
      'followersCount': followersCount,
      'postsCount': postsCount,
      'isVerified': isVerified,
      'isCurrentUser': isCurrentUser,
      'level': level,
      'nextLevelProgress': nextLevelProgress,
    };
  }

  /// نسخ مع تعديل
  LeaderboardModel copyWith({
    int? rank,
    String? userId,
    String? userName,
    String? profileImage,
    int? totalPoints,
    int? weeklyPoints,
    int? monthlyPoints,
    int? achievementsCount,
    int? followersCount,
    int? postsCount,
    bool? isVerified,
    bool? isCurrentUser,
    int? level,
    int? nextLevelProgress,
  }) {
    return LeaderboardModel(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      profileImage: profileImage ?? this.profileImage,
      totalPoints: totalPoints ?? this.totalPoints,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      monthlyPoints: monthlyPoints ?? this.monthlyPoints,
      achievementsCount: achievementsCount ?? this.achievementsCount,
      followersCount: followersCount ?? this.followersCount,
      postsCount: postsCount ?? this.postsCount,
      isVerified: isVerified ?? this.isVerified,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      level: level ?? this.level,
      nextLevelProgress: nextLevelProgress ?? this.nextLevelProgress,
    );
  }
}

/// نموذج Level للـ Data Layer
class LevelModel extends LevelEntity {
  const LevelModel({
    required super.level,
    required super.name,
    required super.requiredPoints,
    required super.imageUrl,
    required super.color,
    required super.description,
  });

  /// تحويل من JSON
  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      level: json['level'] as int? ?? 1,
      name: json['name'] as String? ?? '',
      requiredPoints: json['requiredPoints'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      color: json['color'] as String? ?? '#000000',
      description: json['description'] as String? ?? '',
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'name': name,
      'requiredPoints': requiredPoints,
      'imageUrl': imageUrl,
      'color': color,
      'description': description,
    };
  }

  /// نسخ مع تعديل
  LevelModel copyWith({
    int? level,
    String? name,
    int? requiredPoints,
    String? imageUrl,
    String? color,
    String? description,
  }) {
    return LevelModel(
      level: level ?? this.level,
      name: name ?? this.name,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      description: description ?? this.description,
    );
  }
}
