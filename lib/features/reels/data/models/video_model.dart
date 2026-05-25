
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/user_activity_summary.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_algorithm.dart';

class VideoModel {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String userId;
  final String userName;
  final String userProfilePic;
  /// رابط المقطع الصوتي المشترك (أو نفس [videoUrl] للصوت الأصلي) — لتجميع صفحة الصوت.
  final String audioUrl;
  final String? fixtureId;
  final DateTime timestamp;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;

  /// إجمالي عدد مرّات المشاهدة (يحدَّث تلقائياً من [ReelsRankingService])
  final int viewsCount;

  /// مشاهدات مؤهّلة في الخوارزمية (مثلاً بعد مشاهدة ≥70% من مدة الريل).
  final int watchCount;

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

  /// جمهور الريل: `zamalek` | `all` | `ahly`.
  final String visibility;

  /// مصدر التطبيق في Firestore للخوارزمية: `ahly` أو `zamalek`.
  final String appSource;

  /// مجموع تفاعلي محلي (likes + comments + views) — يطابق منطق العرض في التطبيق ؛
  /// في Firestore يُحدَّث الحقل `engagement_count` ذريًا عبر `FieldValue.increment`
  /// في [ReelsRemoteDataSource.incrementEngagementCount] عند كل تفاعل لتفادي سباقات الكتابة.
  final int engagementCount;

  /// آخر score متزامن من مستند Firestore (اختياري).
  final double? syncedRankingScore;

  VideoModel({
    required this.id,
    required this.videoUrl,
    this.thumbnailUrl = '', // Default to empty string if not provided
    required this.caption,
    required this.userId,
    required this.userName,
    this.userProfilePic = '', // Default to empty string if not provided
    this.audioUrl = '',
    this.fixtureId,
    required this.timestamp,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.viewsCount = 0,
    this.watchCount = 0,
    this.totalWatchTime = 0,
    this.isLikedByCurrentUser = false, // Default to false
    this.isSavedByCurrentUser = false,
    this.isPrivate = false,
    this.visibility = 'all',
    this.appSource = '',
    this.engagementCount = 0,
    this.syncedRankingScore,
  });

  /// نقاط الترتيب الخوارزمية — (likes×2)+(comments×3)+(views×1) مع انحلال زمني ([ReelsAlgorithm]).
  double get score => ReelsAlgorithm.computeRankingScore(
        likes: likesCount,
        comments: commentsCount,
        views: viewsCount,
        watchCount: watchCount,
        uploadedAt: timestamp,
      );

  /// مفتاح واحد لجميع الريلز التي تشترك في نفس المصدر الصوتي (Firestore `audioUrl` أو رابط الفيديو كاحتياط).
  String get audioTrackKey => audioUrl.isNotEmpty ? audioUrl : videoUrl;

  /// عنوان يُعرض في شريط الصوت وصفحة الترند الصوتي.
  String get audioDisplayLabel {
    final name = userName.isNotEmpty ? userName : 'مستخدم';
    return caption.isNotEmpty ? 'الصوت الأصلي — $name' : 'الصوت الأصلي — أهلاوي';
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

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    try {
      final lc = parseInt(map['likesCount'] ?? map['likes'] ?? 0);
      final cc = parseInt(map['commentsCount'] ?? map['comments'] ?? 0);
      final vc = parseInt(map['viewsCount'] ?? map['views'] ?? 0);
      final wc = parseInt(map['watch_count'] ?? 0);
      final eg = map['engagement_count'] != null
          ? parseInt(map['engagement_count'])
          : lc + cc + vc + wc;

      return VideoModel(
        id: id,
        videoUrl: parseString(map['videoUrl']),
        thumbnailUrl: parseString(map['thumbnailUrl']),
        caption: parseString(map['caption']),
        userId: parseString(map['userId']),
        userName: parseString(map['userName']).isEmpty ? 'مستخدم' : parseString(map['userName']),
        userProfilePic: parseString(map['userProfilePic']),
        audioUrl: parseString(map['audioUrl']),
        fixtureId: map['fixtureId']?.toString(),
        timestamp: parseTimestamp(map['timestamp']),
        likesCount: lc,
        commentsCount: cc,
        sharesCount: parseInt(map['sharesCount'] ?? map['shares'] ?? 0),
        savesCount: parseInt(map['savesCount'] ?? map['saves'] ?? 0),
        viewsCount: vc,
        watchCount: wc,
        // نقرأ الحقل الجديد مع fallback على القديم للـ backward compatibility
        totalWatchTime:
            parseInt(map['totalWatchTime'] ?? map['watchTime'] ?? 0),
        isLikedByCurrentUser: false, // This will be set in the repository layer
        isPrivate: map['isPrivate'] == true,
        visibility: _parseVisibility(map['visibility']),
        appSource: _parseAppSource(map['app_source']),
        engagementCount: eg,
        syncedRankingScore: parseDouble(map['score']),
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
        audioUrl: parseString(map['audioUrl']),
        timestamp: DateTime.now(),
        likesCount: parseInt(map['likesCount'] ?? map['likes'] ?? 0),
        commentsCount: parseInt(map['commentsCount'] ?? map['comments'] ?? 0),
        sharesCount: parseInt(map['sharesCount'] ?? map['shares'] ?? 0),
        savesCount: parseInt(map['savesCount'] ?? map['saves'] ?? 0),
        viewsCount: parseInt(map['viewsCount'] ?? map['views'] ?? 0),
        watchCount: parseInt(map['watch_count'] ?? 0),
        totalWatchTime:
            parseInt(map['totalWatchTime'] ?? map['watchTime'] ?? 0),
        isLikedByCurrentUser: false,
        isPrivate: map['isPrivate'] == true,
        visibility: _parseVisibility(map['visibility']),
        appSource: _parseAppSource(map['app_source']),
        engagementCount: parseInt(map['engagement_count']),
        syncedRankingScore: parseDouble(map['score']),
      );
    }
  }

  static String _parseVisibility(dynamic v) {
    if (v == null) return 'all';
    final s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return 'all';
    if (s == 'zamalek' || s == 'all' || s == 'ahly') return s;
    return 'all';
  }

  static String _parseAppSource(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim().toLowerCase();
    if (s == 'ahly' || s == 'zamalek') return s;
    return '';
  }

  /// يظهر في فيد أهلاوي عندما يكون الجمهور `ahly` أو `all`.
  bool get isVisibleInAhlyFeed {
    final v = visibility.toLowerCase();
    return v == 'ahly' || v == 'all';
  }

  /// يظهر في فيد تطبيق الزملكاوي فقط لـ `zamalek` أو `all`.
  bool get isVisibleInZamalekFeed {
    final v = visibility.toLowerCase();
    return v == 'zamalek' || v == 'all';
  }

  Map<String, dynamic> toMap() {
    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'audioUrl': audioUrl.isNotEmpty ? audioUrl : videoUrl,
      'fixtureId': fixtureId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'savesCount': savesCount,
      'viewsCount': viewsCount,
      'watch_count': watchCount,
      'totalWatchTime': totalWatchTime,
      'isPrivate': isPrivate,
      'visibility': visibility,
    };
  }

  Map<String, dynamic> toFirestoreFlatMap() {
    return {
      ...toMap(),
      if (appSource.isNotEmpty) 'app_source': appSource,
      'engagement_count': engagementCount,
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
    String? audioUrl,
    String? fixtureId,
    DateTime? timestamp,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? savesCount,
    int? viewsCount,
    int? watchCount,
    int? totalWatchTime,
    bool? isLikedByCurrentUser,
    bool? isSavedByCurrentUser,
    bool? isPrivate,
    String? visibility,
    String? appSource,
    int? engagementCount,
    double? syncedRankingScore,
  }) {
    return VideoModel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      audioUrl: audioUrl ?? this.audioUrl,
      fixtureId: fixtureId ?? this.fixtureId,
      timestamp: timestamp ?? this.timestamp,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      savesCount: savesCount ?? this.savesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      watchCount: watchCount ?? this.watchCount,
      totalWatchTime: totalWatchTime ?? this.totalWatchTime,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isSavedByCurrentUser: isSavedByCurrentUser ?? this.isSavedByCurrentUser,
      isPrivate: isPrivate ?? this.isPrivate,
      visibility: visibility ?? this.visibility,
      appSource: appSource ?? this.appSource,
      engagementCount: engagementCount ?? this.engagementCount,
      syncedRankingScore: syncedRankingScore ?? this.syncedRankingScore,
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
        other.audioUrl == audioUrl &&
        other.fixtureId == fixtureId &&
        other.timestamp == timestamp &&
        other.likesCount == likesCount &&
        other.commentsCount == commentsCount &&
        other.sharesCount == sharesCount &&
        other.savesCount == savesCount &&
        other.viewsCount == viewsCount &&
        other.watchCount == watchCount &&
        other.totalWatchTime == totalWatchTime &&
        other.isLikedByCurrentUser == isLikedByCurrentUser &&
        other.isSavedByCurrentUser == isSavedByCurrentUser &&
        other.visibility == visibility &&
        other.appSource == appSource &&
        other.engagementCount == engagementCount &&
        other.syncedRankingScore == syncedRankingScore;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      videoUrl,
      thumbnailUrl,
      caption,
      userId,
      userName,
      userProfilePic,
      audioUrl,
      fixtureId,
      timestamp,
      likesCount,
      commentsCount,
      sharesCount,
      savesCount,
      viewsCount,
      watchCount,
      totalWatchTime,
      isLikedByCurrentUser,
      isSavedByCurrentUser,
      visibility,
      appSource,
      engagementCount,
      syncedRankingScore,
    ]);
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, videoUrl: $videoUrl, caption: $caption, userId: $userId, userName: $userName, likesCount: $likesCount, commentsCount: $commentsCount, sharesCount: $sharesCount, savesCount: $savesCount, isLikedByCurrentUser: $isLikedByCurrentUser)';
  }
}
