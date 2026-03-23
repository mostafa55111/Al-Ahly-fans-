import 'package:firebase_database/firebase_database.dart';

/// Firebase Service
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  // Database References
  late DatabaseReference _postsRef;
  late DatabaseReference _usersRef;
  late DatabaseReference _followsRef;
  late DatabaseReference _achievementsRef;
  late DatabaseReference _leaderboardRef;
  late DatabaseReference _matchesRef;
  late DatabaseReference _storiesRef;
  late DatabaseReference _commentsRef;
  late DatabaseReference _notificationsRef;

  /// تهيئة الـ References
  void initialize() {
    _postsRef = FirebaseDatabase.instance.ref('posts');
    _usersRef = FirebaseDatabase.instance.ref('users');
    _followsRef = FirebaseDatabase.instance.ref('follows');
    _achievementsRef = FirebaseDatabase.instance.ref('achievements');
    _leaderboardRef = FirebaseDatabase.instance.ref('leaderboard');
    _matchesRef = FirebaseDatabase.instance.ref('matches');
    _storiesRef = FirebaseDatabase.instance.ref('stories');
    _commentsRef = FirebaseDatabase.instance.ref('comments');
    _notificationsRef = FirebaseDatabase.instance.ref('notifications');

    print('✅ Firebase Service initialized');
  }

  // ==================== Posts ====================

  /// إنشاء منشور جديد
  Future<String> createPost(Map<String, dynamic> postData) async {
    try {
      final newPostRef = _postsRef.push();
      await newPostRef.set({
        ...postData,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return newPostRef.key!;
    } catch (e) {
      throw Exception('فشل إنشاء المنشور: $e');
    }
  }

  /// الحصول على جميع المنشورات
  Future<List<Map<String, dynamic>>> getAllPosts() async {
    try {
      final snapshot = await _postsRef.get();
      if (!snapshot.exists) return [];

      final posts = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        posts.add(Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>));
      }

      return posts;
    } catch (e) {
      throw Exception('فشل جلب المنشورات: $e');
    }
  }

  /// تحديث منشور
  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    try {
      await _postsRef.child(postId).update({
        ...updates,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل تحديث المنشور: $e');
    }
  }

  /// حذف منشور
  Future<void> deletePost(String postId) async {
    try {
      await _postsRef.child(postId).remove();
    } catch (e) {
      throw Exception('فشل حذف المنشور: $e');
    }
  }

  /// الإعجاب بمنشور
  Future<void> likePost(String postId, String userId) async {
    try {
      await _postsRef.child(postId).child('likes').child(userId).set(true);
      
      final snapshot = await _postsRef.child(postId).child('likesCount').get();
      final currentLikes = (snapshot.value as int?) ?? 0;
      await _postsRef.child(postId).update({'likesCount': currentLikes + 1});
    } catch (e) {
      throw Exception('فشل الإعجاب: $e');
    }
  }

  /// إلغاء الإعجاب
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _postsRef.child(postId).child('likes').child(userId).remove();
      
      final snapshot = await _postsRef.child(postId).child('likesCount').get();
      final currentLikes = (snapshot.value as int?) ?? 0;
      if (currentLikes > 0) {
        await _postsRef.child(postId).update({'likesCount': currentLikes - 1});
      }
    } catch (e) {
      throw Exception('فشل إلغاء الإعجاب: $e');
    }
  }

  // ==================== Users ====================

  /// إنشاء ملف تعريفي للمستخدم
  Future<void> createUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      await _usersRef.child(userId).set({
        ...userData,
        'createdAt': DateTime.now().toIso8601String(),
        'followersCount': 0,
        'followingCount': 0,
        'postsCount': 0,
      });
    } catch (e) {
      throw Exception('فشل إنشاء الملف التعريفي: $e');
    }
  }

  /// الحصول على بيانات المستخدم
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final snapshot = await _usersRef.child(userId).get();
      if (!snapshot.exists) return null;

      return Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
    } catch (e) {
      throw Exception('فشل جلب بيانات المستخدم: $e');
    }
  }

  /// تحديث بيانات المستخدم
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _usersRef.child(userId).update(updates);
    } catch (e) {
      throw Exception('فشل تحديث الملف التعريفي: $e');
    }
  }

  // ==================== Follows ====================

  /// متابعة مستخدم
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      await _followsRef.child(currentUserId).child(targetUserId).set(true);

      final snapshot = await _usersRef.child(targetUserId).child('followersCount').get();
      final currentFollowers = (snapshot.value as int?) ?? 0;
      await _usersRef.child(targetUserId).update({'followersCount': currentFollowers + 1});

      final snapshot2 = await _usersRef.child(currentUserId).child('followingCount').get();
      final currentFollowing = (snapshot2.value as int?) ?? 0;
      await _usersRef.child(currentUserId).update({'followingCount': currentFollowing + 1});
    } catch (e) {
      throw Exception('فشل المتابعة: $e');
    }
  }

  /// إلغاء المتابعة
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      await _followsRef.child(currentUserId).child(targetUserId).remove();

      final snapshot = await _usersRef.child(targetUserId).child('followersCount').get();
      final currentFollowers = (snapshot.value as int?) ?? 0;
      if (currentFollowers > 0) {
        await _usersRef.child(targetUserId).update({'followersCount': currentFollowers - 1});
      }

      final snapshot2 = await _usersRef.child(currentUserId).child('followingCount').get();
      final currentFollowing = (snapshot2.value as int?) ?? 0;
      if (currentFollowing > 0) {
        await _usersRef.child(currentUserId).update({'followingCount': currentFollowing - 1});
      }
    } catch (e) {
      throw Exception('فشل إلغاء المتابعة: $e');
    }
  }

  // ==================== Achievements ====================

  /// إضافة إنجاز للمستخدم
  Future<void> addAchievement(String userId, Map<String, dynamic> achievement) async {
    try {
      final achievementRef = _achievementsRef.child(userId).push();
      await achievementRef.set({
        ...achievement,
        'unlockedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل إضافة الإنجاز: $e');
    }
  }

  /// الحصول على إنجازات المستخدم
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _achievementsRef.child(userId).get();
      if (!snapshot.exists) return [];

      final achievements = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        achievements.add(Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>));
      }

      return achievements;
    } catch (e) {
      throw Exception('فشل جلب الإنجازات: $e');
    }
  }

  // ==================== Leaderboard ====================

  /// تحديث ترتيب المستخدم
  Future<void> updateLeaderboardRank(String userId, Map<String, dynamic> rankData) async {
    try {
      await _leaderboardRef.child(userId).set({
        ...rankData,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل تحديث الترتيب: $e');
    }
  }

  /// الحصول على الترتيبات
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 100}) async {
    try {
      final snapshot = await _leaderboardRef.limitToFirst(limit).get();
      if (!snapshot.exists) return [];

      final leaderboard = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        leaderboard.add(Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>));
      }

      return leaderboard;
    } catch (e) {
      throw Exception('فشل جلب الترتيبات: $e');
    }
  }

  // ==================== Matches ====================

  /// إنشاء مباراة جديدة
  Future<String> createMatch(Map<String, dynamic> matchData) async {
    try {
      final newMatchRef = _matchesRef.push();
      await newMatchRef.set({
        ...matchData,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return newMatchRef.key!;
    } catch (e) {
      throw Exception('فشل إنشاء المباراة: $e');
    }
  }

  /// تحديث حالة المباراة
  Future<void> updateMatchStatus(String matchId, String status) async {
    try {
      await _matchesRef.child(matchId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل تحديث حالة المباراة: $e');
    }
  }

  /// الحصول على المباريات المباشرة
  Future<List<Map<String, dynamic>>> getLiveMatches() async {
    try {
      final snapshot = await _matchesRef.orderByChild('status').equalTo('live').get();
      if (!snapshot.exists) return [];

      final matches = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        matches.add(Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>));
      }

      return matches;
    } catch (e) {
      throw Exception('فشل جلب المباريات المباشرة: $e');
    }
  }
}
