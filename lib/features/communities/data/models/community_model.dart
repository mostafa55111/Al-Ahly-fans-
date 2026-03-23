import 'package:gomhor_alahly_clean_new/features/communities/domain/entities/community_entity.dart';

/// نموذج المجتمع (Community Model)
/// يتعامل مع تحويل البيانات من Firebase إلى Entity
class CommunityModel extends CommunityEntity {
  const CommunityModel({
    required super.id,
    required super.name,
    required super.description,
    required super.imageUrl,
    required super.creatorId,
    required super.membersCount,
    required super.postsCount,
    required super.createdAt,
    required super.tags,
    required super.category,
    required super.isVerified,
    required super.isMuted,
    required super.privacy,
  });

  /// تحويل من JSON إلى Model
  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      creatorId: json['creatorId'] ?? '',
      membersCount: json['membersCount'] ?? 0,
      postsCount: json['postsCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] ?? 'General',
      isVerified: json['isVerified'] ?? false,
      isMuted: json['isMuted'] ?? false,
      privacy: json['privacy'] ?? 'public',
    );
  }

  /// تحويل من Model إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'membersCount': membersCount,
      'postsCount': postsCount,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'category': category,
      'isVerified': isVerified,
      'isMuted': isMuted,
      'privacy': privacy,
    };
  }

  /// تحويل من Entity إلى Model
  factory CommunityModel.fromEntity(CommunityEntity entity) {
    return CommunityModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      imageUrl: entity.imageUrl,
      creatorId: entity.creatorId,
      membersCount: entity.membersCount,
      postsCount: entity.postsCount,
      createdAt: entity.createdAt,
      tags: entity.tags,
      category: entity.category,
      isVerified: entity.isVerified,
      isMuted: entity.isMuted,
      privacy: entity.privacy,
    );
  }
}
