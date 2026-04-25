import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

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

      debugPrint(' FOLLOW: Successfully followed user $targetUserId');
    } catch (e) {
      debugPrint(' FOLLOW ERROR: Failed to follow user $targetUserId - $e');
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

      debugPrint(' FOLLOW: Successfully unfollowed user $targetUserId');
    } catch (e) {
      debugPrint(' FOLLOW ERROR: Failed to unfollow user $targetUserId - $e');
      rethrow;
    }
  }

  /// Check if current user is following target user
  static Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final snapshot = await _db.ref().child('follows/$currentUserId/$targetUserId').get();
      return snapshot.exists;
    } catch (e) {
      debugPrint(' FOLLOW ERROR: Failed to check follow status - $e');
      return false;
    }
  }

  /// Get followers count for a user
  static Future<int> getFollowersCount(String userId) async {
    try {
      final snapshot = await _db.ref().child('users/$userId/followersCount').get();
      return snapshot.value as int? ?? 0;
    } catch (e) {
      debugPrint(' FOLLOW ERROR: Failed to get followers count - $e');
      return 0;
    }
  }

  /// Get following count for a user
  static Future<int> getFollowingCount(String userId) async {
    try {
      final snapshot = await _db.ref().child('users/$userId/followingCount').get();
      return snapshot.value as int? ?? 0;
    } catch (e) {
      debugPrint(' FOLLOW ERROR: Failed to get following count - $e');
      return 0;
    }
  }

  /// Get list of followers for a user
  static Future<List<String>> getFollowersList(String userId) async {
    try {
      final snapshot = await _db.ref().child('followers/$userId').get();
      if (!snapshot.exists) return [];
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.keys.toList();
    } catch (e) {
      debugPrint(' FOLLOW ERROR: Failed to get followers list - $e');
      return [];
    }
  }

  /// Get list of users that current user is following
  static Future<List<String>> getFollowingList(String userId) async {
    try {
      final snapshot = await _db.ref().child('follows/$userId').get();
      if (!snapshot.exists) return [];
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.keys.toList();
    } catch (e) {
      debugPrint(' FOLLOW ERROR: Failed to get following list - $e');
      return [];
    }
  }
}
