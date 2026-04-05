import 'package:firebase_database/firebase_database.dart';

class VideoModel {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String userId;
  final String userName;
  final String userProfilePic;
  final String? fixtureId;
  final DateTime timestamp;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;
  final bool isLikedByCurrentUser; // This will be set in the repository layer

  VideoModel({
    required this.id,
    required this.videoUrl,
    this.thumbnailUrl = '', // Default to empty string if not provided
    required this.caption,
    required this.userId,
    required this.userName,
    this.userProfilePic = '', // Default to empty string if not provided
    this.fixtureId,
    required this.timestamp,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.isLikedByCurrentUser = false, // Default to false
  });

  factory VideoModel.fromJson(Map<String, dynamic> map, String id) {
    // Helper to safely parse int values, defaulting to 0
    int _parseInt(dynamic value) {
      try {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) {
          if (value.isEmpty) return 0;
          return int.tryParse(value) ?? 0;
        }
        if (value is double) return value.toInt();
        if (value is bool) return value ? 1 : 0;
        return 0;
      } catch (e) {
        print('⚠️ INT PARSE ERROR: $value - $e');
        return 0;
      }
    }

    // Helper to safely parse DateTime from various formats
    DateTime _parseTimestamp(dynamic timestamp) {
      try {
        if (timestamp == null) return DateTime.now();
        if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (timestamp is String) {
          if (timestamp.isEmpty) return DateTime.now();
          final parsed = int.tryParse(timestamp);
          if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
          return DateTime.now();
        }
        return DateTime.now();
      } catch (e) {
        print('⚠️ TIMESTAMP PARSE ERROR: $timestamp - $e');
        return DateTime.now();
      }
    }

    // Helper to safely parse strings
    String _parseString(dynamic value) {
      try {
        if (value == null) return '';
        if (value is String) return value;
        if (value is int || value is double || value is bool) return value.toString();
        return '';
      } catch (e) {
        print('⚠️ STRING PARSE ERROR: $value - $e');
        return '';
      }
    }

    try {
      return VideoModel(
        id: id,
        videoUrl: _parseString(map['videoUrl']),
        thumbnailUrl: _parseString(map['thumbnailUrl']),
        caption: _parseString(map['caption']),
        userId: _parseString(map['userId']),
        userName: _parseString(map['userName']).isEmpty ? 'مستخدم' : _parseString(map['userName']),
        userProfilePic: _parseString(map['userProfilePic']),
        fixtureId: map['fixtureId']?.toString(),
        timestamp: _parseTimestamp(map['timestamp']),
        likesCount: _parseInt(map['likesCount'] ?? map['likes'] ?? 0),
        commentsCount: _parseInt(map['commentsCount'] ?? map['comments'] ?? 0),
        sharesCount: _parseInt(map['sharesCount'] ?? map['shares'] ?? 0),
        savesCount: _parseInt(map['savesCount'] ?? map['saves'] ?? 0),
        isLikedByCurrentUser: false, // This will be set in the repository layer
      );
    } catch (e, stackTrace) {
      // Return a default VideoModel if parsing fails
      print('❌ VIDEO MODEL ERROR: Failed to parse VideoModel: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ Problematic data: ${map.toString()}');
      
      // Create minimal valid model to prevent app crashes
      return VideoModel(
        id: id,
        videoUrl: _parseString(map['videoUrl']),
        thumbnailUrl: _parseString(map['thumbnailUrl']),
        caption: _parseString(map['caption']),
        userId: _parseString(map['userId']),
        userName: _parseString(map['userName']).isEmpty ? 'مستخدم' : _parseString(map['userName']),
        userProfilePic: _parseString(map['userProfilePic']),
        timestamp: DateTime.now(),
        likesCount: _parseInt(map['likesCount'] ?? map['likes'] ?? 0),
        commentsCount: _parseInt(map['commentsCount'] ?? map['comments'] ?? 0),
        sharesCount: _parseInt(map['sharesCount'] ?? map['shares'] ?? 0),
        savesCount: _parseInt(map['savesCount'] ?? map['saves'] ?? 0),
        isLikedByCurrentUser: false,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'fixtureId': fixtureId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'savesCount': savesCount,
    };
  }

  VideoModel copyWith({
    String? id,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    String? userId,
    String? userName,
    String? userProfilePic,
    String? fixtureId,
    DateTime? timestamp,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? savesCount,
    bool? isLikedByCurrentUser,
  }) {
    return VideoModel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      fixtureId: fixtureId ?? this.fixtureId,
      timestamp: timestamp ?? this.timestamp,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      savesCount: savesCount ?? this.savesCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoModel &&
        other.id == id &&
        other.videoUrl == videoUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.caption == caption &&
        other.userId == userId &&
        other.userName == userName &&
        other.userProfilePic == userProfilePic &&
        other.fixtureId == fixtureId &&
        other.timestamp == timestamp &&
        other.likesCount == likesCount &&
        other.commentsCount == commentsCount &&
        other.sharesCount == sharesCount &&
        other.savesCount == savesCount &&
        other.isLikedByCurrentUser == isLikedByCurrentUser;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      videoUrl,
      thumbnailUrl,
      caption,
      userId,
      userName,
      userProfilePic,
      fixtureId,
      timestamp,
      likesCount,
      commentsCount,
      sharesCount,
      savesCount,
      isLikedByCurrentUser,
    );
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, videoUrl: $videoUrl, caption: $caption, userId: $userId, userName: $userName, likesCount: $likesCount, commentsCount: $commentsCount, sharesCount: $sharesCount, savesCount: $savesCount, isLikedByCurrentUser: $isLikedByCurrentUser)';
  }
}
