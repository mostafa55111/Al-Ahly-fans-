import 'package:firebase_database/firebase_database.dart';

class FollowService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Follow a user
  static Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      // Add follow relationship
      await _db.ref().child('follows/$currentUserId/$targetUserId').set(true);
      await _db.ref().child('followers/$targetUserId/$currentUserId').set(true);

      // Update counts
      await _db.ref().child('users/$currentUserId/followingCount')
          .runTransaction((value) => Transaction.success((value as int? ?? 0) + 1));

      await _db.ref().child('users/$targetUserId/followersCount')
          .runTransaction((value) => Transaction.success((value as int? ?? 0) + 1));

      print('🎬 FOLLOW: Successfully followed user $targetUserId');
    } catch (e) {
      print('🎬 FOLLOW ERROR: Failed to follow user $targetUserId - $e');
      rethrow;
    }
  }

  /// Unfollow a user
  static Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      // Remove follow relationship
      await _db.ref().child('follows/$currentUserId/$targetUserId').remove();
      await _db.ref().child('followers/$targetUserId/$currentUserId').remove();

      // Update counts
      await _db.ref().child('users/$currentUserId/followingCount')
          .runTransaction((value) => Transaction.success((value as int? ?? 0) - 1));

      await _db.ref().child('users/$targetUserId/followersCount')
          .runTransaction((value) => Transaction.success((value as int? ?? 0) - 1));

      print('🎬 FOLLOW: Successfully unfollowed user $targetUserId');
    } catch (e) {
      print('🎬 FOLLOW ERROR: Failed to unfollow user $targetUserId - $e');
      rethrow;
    }
  }

  /// Check if current user is following target user
  static Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final snapshot = await _db.ref().child('follows/$currentUserId/$targetUserId').get();
      return snapshot.exists;
    } catch (e) {
      print('🎬 FOLLOW ERROR: Failed to check follow status - $e');
      return false;
    }
  }

  /// Get user's followers count
  static Future<int> getFollowersCount(String userId) async {
    try {
      final snapshot = await _db.ref().child('users/$userId/followersCount').get();
      return snapshot.value as int? ?? 0;
    } catch (e) {
      print('🎬 FOLLOW ERROR: Failed to get followers count - $e');
      return 0;
    }
  }

  /// Get user's following count
  static Future<int> getFollowingCount(String userId) async {
    try {
      final snapshot = await _db.ref().child('users/$userId/followingCount').get();
      return snapshot.value as int? ?? 0;
    } catch (e) {
      print('🎬 FOLLOW ERROR: Failed to get following count - $e');
      return 0;
    }
  }

  /// Get user's followers list
  static Future<List<String>> getFollowersList(String userId) async {
    try {
      final snapshot = await _db.ref().child('followers/$userId').get();
      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.keys.toList();
    } catch (e) {
      print('🎬 FOLLOW ERROR: Failed to get followers list - $e');
      return [];
    }
  }

  /// Get user's following list
  static Future<List<String>> getFollowingList(String userId) async {
    try {
      final snapshot = await _db.ref().child('follows/$userId').get();
      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.keys.toList();
    } catch (e) {
      print('🎬 FOLLOW ERROR: Failed to get following list - $e');
      return [];
    }
  }
}
