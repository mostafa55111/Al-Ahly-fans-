
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/user_activity_summary.dart';

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

  /// إجمالي عدد مرّات المشاهدة (يحدَّث تلقائياً من [ReelsRankingService])
  final int viewsCount;

  /// إجمالي ثواني المشاهدة عبر جميع المستخدمين
  final int totalWatchTime;

  final bool isLikedByCurrentUser; // This will be set in the repository layer

  /// حالة الحفظ الخاصة بالمستخدم الحالي (محلياً) — تأتي من
  /// `users/{uid}/savedVideos/{videoId}` لا من الريل نفسه.
  final bool isSavedByCurrentUser;

  /// هل الريل خاص؟ (يظهر في تبويب "الخاص" بالبروفايل فقط ولا يظهر في الفيد العام)
  /// ═══════════════════════════════════════════════════════════════
  /// لما يبقى true → ما يظهرش في `For You` ولا `Following`، فقط لصاحبه.
  final bool isPrivate;

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
    this.viewsCount = 0,
    this.totalWatchTime = 0,
    this.isLikedByCurrentUser = false, // Default to false
    this.isSavedByCurrentUser = false,
    this.isPrivate = false,
  });

  /// حساب الـ score للترتيب الذكي (For You feed - TikTok style)
  /// ═══════════════════════════════════════════════════════════════
  /// score = likesCount*2
  ///       + commentsCount*3
  ///       + sharesCount*4
  ///       + viewsCount
  ///       + freshness
  /// ═══════════════════════════════════════════════════════════════
  /// - share له أعلى وزن (أعمق engagement).
  /// - comment وزنه أعلى من like (تفاعل نصّي > تفاعل سريع).
  /// - freshness: يضيف حتى 50 نقطة للريل الجديد، يتلاشى خلال 7 أيام.
  double get score =>
      (likesCount * 2.0) +
      (commentsCount * 3.0) +
      (sharesCount * 4.0) +
      viewsCount.toDouble() +
      freshness;

  /// معامل "الحداثة" — يعطي دفعة للريلز الجديدة ويخفت مع الوقت.
  /// ═══════════════════════════════════════════════════════════════
  /// - يبدأ بـ 50 نقطة عند الرفع.
  /// - يتلاشى خطياً على مدى 7 أيام إلى 0.
  /// - لا يصبح سالباً أبداً (clamp).
  double get freshness {
    final ageHours = DateTime.now().difference(timestamp).inMinutes / 60.0;
    const decayWindowHours = 7 * 24.0; // 7 أيام
    const maxBoost = 50.0;
    final factor = 1.0 - (ageHours / decayWindowHours);
    return (maxBoost * factor).clamp(0.0, maxBoost);
  }

  /// حساب الـ personalScore بناءً على سلوك المستخدم السابق.
  /// ═══════════════════════════════════════════════════════
  /// personalScore =
  ///     baseScore
  ///   + (userWatchTime * 2)   → مكافأة لو شاهد الريل سابقاً
  ///   + 5                     → مكافأة إضافية لو عمل like
  ///   - 10                    → عقوبة لو تخطّاه بسرعة (watchTime < 3s)
  /// ═══════════════════════════════════════════════════════
  /// لو ما فيش activity (ريل لم يشاهده المستخدم) → يُستخدم الـ baseScore فقط.
  double personalScore(UserActivitySummary? activity) {
    double p = score;
    if (activity == null) return p;
    if (activity.hasWatched) {
      p += activity.watchTime * 2.0;
    }
    if (activity.liked) p += 5.0;
    // تقليل ظهور الفيديوهات اللي تم تخطيها بسرعة
    if (activity.skippedQuickly) p -= 10.0;
    return p;
  }

  factory VideoModel.fromJson(Map<String, dynamic> map, String id) {
    // Helper to safely parse int values, defaulting to 0
    int parseInt(dynamic value) {
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
        debugPrint(' INT PARSE ERROR: $value - $e');
        return 0;
      }
    }

    // Helper to safely parse DateTime from various formats
    DateTime parseTimestamp(dynamic timestamp) {
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
        debugPrint(' TIMESTAMP PARSE ERROR: $timestamp - $e');
        return DateTime.now();
      }
    }

    // Helper to safely parse strings
    String parseString(dynamic value) {
      try {
        if (value == null) return '';
        if (value is String) return value;
        if (value is int || value is double || value is bool) return value.toString();
        return '';
      } catch (e) {
        debugPrint(' STRING PARSE ERROR: $value - $e');
        return '';
      }
    }

    try {
      return VideoModel(
        id: id,
        videoUrl: parseString(map['videoUrl']),
        thumbnailUrl: parseString(map['thumbnailUrl']),
        caption: parseString(map['caption']),
        userId: parseString(map['userId']),
        userName: parseString(map['userName']).isEmpty ? 'مستخدم' : parseString(map['userName']),
        userProfilePic: parseString(map['userProfilePic']),
        fixtureId: map['fixtureId']?.toString(),
        timestamp: parseTimestamp(map['timestamp']),
        likesCount: parseInt(map['likesCount'] ?? map['likes'] ?? 0),
        commentsCount: parseInt(map['commentsCount'] ?? map['comments'] ?? 0),
        sharesCount: parseInt(map['sharesCount'] ?? map['shares'] ?? 0),
        savesCount: parseInt(map['savesCount'] ?? map['saves'] ?? 0),
        viewsCount: parseInt(map['viewsCount'] ?? map['views'] ?? 0),
        // نقرأ الحقل الجديد مع fallback على القديم للـ backward compatibility
        totalWatchTime:
            parseInt(map['totalWatchTime'] ?? map['watchTime'] ?? 0),
        isLikedByCurrentUser: false, // This will be set in the repository layer
        isPrivate: map['isPrivate'] == true,
      );
    } catch (e, stackTrace) {
      // Return a default VideoModel if parsing fails
      debugPrint(' VIDEO MODEL ERROR: Failed to parse VideoModel: $e');
      debugPrint(' Stack trace: $stackTrace');
      debugPrint(' Problematic data: ${map.toString()}');
      
      // Create minimal valid model to prevent app crashes
      return VideoModel(
        id: id,
        videoUrl: parseString(map['videoUrl']),
        thumbnailUrl: parseString(map['thumbnailUrl']),
        caption: parseString(map['caption']),
        userId: parseString(map['userId']),
        userName: parseString(map['userName']).isEmpty ? 'مستخدم' : parseString(map['userName']),
        userProfilePic: parseString(map['userProfilePic']),
        timestamp: DateTime.now(),
        likesCount: parseInt(map['likesCount'] ?? map['likes'] ?? 0),
        commentsCount: parseInt(map['commentsCount'] ?? map['comments'] ?? 0),
        sharesCount: parseInt(map['sharesCount'] ?? map['shares'] ?? 0),
        savesCount: parseInt(map['savesCount'] ?? map['saves'] ?? 0),
        viewsCount: parseInt(map['viewsCount'] ?? map['views'] ?? 0),
        totalWatchTime:
            parseInt(map['totalWatchTime'] ?? map['watchTime'] ?? 0),
        isLikedByCurrentUser: false,
        isPrivate: map['isPrivate'] == true,
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
      'viewsCount': viewsCount,
      'totalWatchTime': totalWatchTime,
      'isPrivate': isPrivate,
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
    int? viewsCount,
    int? totalWatchTime,
    bool? isLikedByCurrentUser,
    bool? isSavedByCurrentUser,
    bool? isPrivate,
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
      viewsCount: viewsCount ?? this.viewsCount,
      totalWatchTime: totalWatchTime ?? this.totalWatchTime,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isSavedByCurrentUser: isSavedByCurrentUser ?? this.isSavedByCurrentUser,
      isPrivate: isPrivate ?? this.isPrivate,
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
        other.viewsCount == viewsCount &&
        other.totalWatchTime == totalWatchTime &&
        other.isLikedByCurrentUser == isLikedByCurrentUser &&
        other.isSavedByCurrentUser == isSavedByCurrentUser;
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
      viewsCount,
      totalWatchTime,
      isLikedByCurrentUser,
      isSavedByCurrentUser,
    );
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, videoUrl: $videoUrl, caption: $caption, userId: $userId, userName: $userName, likesCount: $likesCount, commentsCount: $commentsCount, sharesCount: $sharesCount, savesCount: $savesCount, isLikedByCurrentUser: $isLikedByCurrentUser)';
  }
}
