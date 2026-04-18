import 'package:equatable/equatable.dart';

class Reel extends Equatable {
  final String videoUrl;
  final String userName;
  final String caption;
  final bool isLiked;
  final int likes;
  final int comments;
  final bool isFollowed;

  const Reel({
    required this.videoUrl,
    required this.userName,
    required this.caption,
    this.isLiked = false,
    this.likes = 0,
    this.comments = 0,
    this.isFollowed = false,
  });

  Reel copyWith({
    String? videoUrl,
    String? userName,
    String? caption,
    bool? isLiked,
    int? likes,
    int? comments,
    bool? isFollowed,
  }) {
    return Reel(
      videoUrl: videoUrl ?? this.videoUrl,
      userName: userName ?? this.userName,
      caption: caption ?? this.caption,
      isLiked: isLiked ?? this.isLiked,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }

  @override
  List<Object?> get props => [
        videoUrl,
        userName,
        caption,
        isLiked,
        likes,
        comments,
        isFollowed
      ];
}
