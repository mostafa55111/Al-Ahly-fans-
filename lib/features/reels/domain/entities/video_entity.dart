import 'package:equatable/equatable.dart';

class VideoEntity extends Equatable {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String userId; // Added for consistency with VideoModel and saving
  final String userName;
  final String userProfilePic; // Added for consistency with VideoModel and saving
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;

  const VideoEntity({
    required this.id,
    required this.videoUrl,
    this.thumbnailUrl = '',
    required this.caption,
    required this.userId,
    required this.userName,
    this.userProfilePic = '',
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
  });

  VideoEntity copyWith({
    String? id,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    String? userId,
    String? userName,
    String? userProfilePic,
    int? likes,
    int? comments,
    int? shares,
    bool? isLiked,
  }) {
    return VideoEntity(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  List<Object?> get props => [
        id,
        videoUrl,
        thumbnailUrl,
        caption,
        userId,
        userName,
        userProfilePic,
        likes,
        comments,
        shares,
        isLiked,
      ];
}
