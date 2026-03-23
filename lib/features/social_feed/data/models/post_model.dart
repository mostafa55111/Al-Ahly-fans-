import 'package:gomhor_alahly_clean_new/features/social_feed/domain/entities/post_entity.dart';

/// نموذج البيانات للمنشور - يتم استخدامه في طبقة البيانات
class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userProfileImage,
    required super.content,
    required super.imageUrls,
    super.videoUrl,
    super.location,
    required super.likesCount,
    required super.commentsCount,
    required super.sharesCount,
    required super.isLikedByCurrentUser,
    required super.hashtags,
    required super.mentions,
    required super.createdAt,
    super.updatedAt,
    required super.isPinned,
    required super.isDeleted,
    required super.postType,
    super.geoLocation,
    required super.reactions,
  });

  /// تحويل من JSON إلى PostModel
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userProfileImage: json['userProfileImage'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      videoUrl: json['videoUrl'] as String?,
      location: json['location'] as String?,
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      sharesCount: json['sharesCount'] as int? ?? 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
      hashtags: List<String>.from(json['hashtags'] as List? ?? []),
      mentions: List<String>.from(json['mentions'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      isPinned: json['isPinned'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      postType: _parsePostType(json['postType'] as String? ?? 'text'),
      geoLocation: json['geoLocation'] != null
          ? GeoLocation(
              latitude: json['geoLocation']['latitude'] as double,
              longitude: json['geoLocation']['longitude'] as double,
              address: json['geoLocation']['address'] as String?,
            )
          : null,
      reactions: List<String>.from(json['reactions'] as List? ?? []),
    );
  }

  /// تحويل من PostModel إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'content': content,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'location': location,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'hashtags': hashtags,
      'mentions': mentions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPinned': isPinned,
      'isDeleted': isDeleted,
      'postType': postType.toString().split('.').last,
      'geoLocation': geoLocation != null
          ? {
              'latitude': geoLocation!.latitude,
              'longitude': geoLocation!.longitude,
              'address': geoLocation!.address,
            }
          : null,
      'reactions': reactions,
    };
  }

  /// نسخ مع تعديل بعض الحقول
  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImage,
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
    String? location,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLikedByCurrentUser,
    List<String>? hashtags,
    List<String>? mentions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isDeleted,
    PostType? postType,
    GeoLocation? geoLocation,
    List<String>? reactions,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      location: location ?? this.location,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
      postType: postType ?? this.postType,
      geoLocation: geoLocation ?? this.geoLocation,
      reactions: reactions ?? this.reactions,
    );
  }

  /// تحويل PostType من String
  static PostType _parsePostType(String type) {
    switch (type) {
      case 'text':
        return PostType.text;
      case 'image':
        return PostType.image;
      case 'video':
        return PostType.video;
      case 'mixed':
        return PostType.mixed;
      case 'story':
        return PostType.story;
      case 'reel':
        return PostType.reel;
      default:
        return PostType.text;
    }
  }
}
