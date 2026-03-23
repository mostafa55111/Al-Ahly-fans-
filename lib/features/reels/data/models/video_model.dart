import 'package:firebase_database/firebase_database.dart';

class VideoModel {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String userId;
  final int likes;
  final int comments;
  final int shares;
  final DateTime timestamp;

  VideoModel({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.userId,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    required this.timestamp,
  });

  factory VideoModel.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return VideoModel(
      id: snapshot.key!,
      videoUrl: data['videoUrl'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String,
      caption: data['caption'] as String,
      userId: data['userId'] as String,
      likes: data['likes'] as int? ?? 0,
      comments: data['comments'] as int? ?? 0,
      shares: data['shares'] as int? ?? 0,
      timestamp: DateTime.parse(data['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'userId': userId,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  VideoModel copyWith({
    String? id,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    String? userId,
    int? likes,
    int? comments,
    int? shares,
    DateTime? timestamp,
  }) {
    return VideoModel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      userId: userId ?? this.userId,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
