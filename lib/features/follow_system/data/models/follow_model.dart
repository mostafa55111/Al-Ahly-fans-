import 'package:gomhor_alahly_clean_new/features/follow_system/domain/entities/follow_entity.dart';

/// نموذج Follow للـ Data Layer
class FollowModel extends FollowEntity {
  const FollowModel({
    required String id,
    required super.followerId,
    required super.followingId,
    required super.followedAt,
    required bool isActive,
    required super.isMuted,
    required super.isBlocked,
    required super.isFavorite,
  }) : super(
    id: id,
    isActive: isActive,
  );

  /// تحويل من JSON
  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      id: json['id'] as String? ?? '',
      followerId: json['followerId'] as String? ?? '',
      followingId: json['followingId'] as String? ?? '',
      followedAt: json['followedAt'] != null
          ? DateTime.parse(json['followedAt'] as String)
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      isMuted: json['isMuted'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'followerId': followerId,
      'followingId': followingId,
      'followedAt': followedAt.toIso8601String(),
      'isActive': isActive,
      'isMuted': isMuted,
      'isBlocked': isBlocked,
      'isFavorite': isFavorite,
    };
  }

  /// نسخ مع تعديل
  FollowModel copyWith({
    String? id,
    String? followerId,
    String? followingId,
    DateTime? followedAt,
    bool? isActive,
    bool? isMuted,
    bool? isBlocked,
    bool? isFavorite,
  }) {
    return FollowModel(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followingId: followingId ?? this.followingId,
      followedAt: followedAt ?? this.followedAt,
      isActive: isActive ?? this.isActive,
      isMuted: isMuted ?? this.isMuted,
      isBlocked: isBlocked ?? this.isBlocked,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// نموذج بيانات المستخدم
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required String username,
    required String email,
    required String displayName,
    required super.profileImage,
    required super.bio,
    required super.followersCount,
    required super.followingCount,
    required super.postsCount,
    required super.isVerified,
    required super.isFollowing,
    required bool isFollowedBy,
    required bool isBlocked,
    required bool isMuted,
    required bool isFavorite,
    required DateTime createdAt,
    required DateTime lastUpdatedAt,
  }) : super(
    username: username,
    email: email,
    displayName: displayName,
    isFollowedBy: isFollowedBy,
    isBlocked: isBlocked,
    isMuted: isMuted,
    isFavorite: isFavorite,
    createdAt: createdAt,
    lastUpdatedAt: lastUpdatedAt,
  );

  /// تحويل من JSON
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      profileImage: json['profileImage'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      postsCount: json['postsCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isFollowing: json['isFollowing'] as bool? ?? false,
      isFollowedBy: json['isFollowedBy'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.parse(json['lastUpdatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'profileImage': profileImage,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isVerified': isVerified,
      'isFollowing': isFollowing,
      'isFollowedBy': isFollowedBy,
      'isBlocked': isBlocked,
      'isMuted': isMuted,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  /// نسخ مع تعديل
  UserProfileModel copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? profileImage,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isVerified,
    bool? isFollowing,
    bool? isFollowedBy,
    bool? isBlocked,
    bool? isMuted,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isVerified: isVerified ?? this.isVerified,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy ?? this.isFollowedBy,
      isBlocked: isBlocked ?? this.isBlocked,
      isMuted: isMuted ?? this.isMuted,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
