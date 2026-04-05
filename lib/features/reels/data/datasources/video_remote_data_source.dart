import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';

/// Remote data source for video operations
/// Integrates with Realtime Database for data storage and Cloudinary for video hosting
class VideoRemoteDataSource {
  final FirebaseDatabase _database;
  final String _reelsPath = 'reels';

  VideoRemoteDataSource() : _database = FirebaseDatabase.instance {
    if (kDebugMode) {
      debugPrint("VideoRemoteDataSource initialized");
      debugPrint("Realtime Database URL: ${_database.databaseURL}");
    }
  }

  /// Fetch reels from Realtime Database
  Future<List<VideoModel>> fetchReels() async {
    try {
      debugPrint('🎬 FETCH: Starting reels fetch with 15s timeout...');
      
      // Add timeout to the entire operation
      final ref = FirebaseDatabase.instance.ref(_reelsPath);
      final snapshot = await ref.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('🎬 FETCH: ❌ TIMEOUT: Firebase fetch timeout after 15 seconds');
          throw TimeoutException('Firebase fetch timeout after 15 seconds');
        },
      );

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('🎬 FETCH: No reels found in Firebase');
        return [];
      }

      // Hard Fix for Firebase Data Type Error: Ensure safe casting for top-level map
      final rawData = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final List<VideoModel> reels = [];

      debugPrint('🎬 FETCH: Processing ${rawData.length} raw reel entries...');

      for (var entry in rawData.entries) {
        try {
          if (entry.value is Map) {
            // Ensure safe casting for nested maps as well
            final item = Map<String, dynamic>.from(entry.value.map((k, v) => MapEntry(k.toString(), v)));
            
            // Create reel with basic data
            final reel = VideoModel.fromJson(item, entry.key.toString());
            
            // Only fetch user data if we have a valid userId and it's not empty
            if (reel.userId.isNotEmpty && reel.userId != 'anonymous_user') {
              try {
                final userSnapshot = await FirebaseDatabase.instance
                    .ref('users/${reel.userId}')
                    .get()
                    .timeout(const Duration(seconds: 3));
                    
                if (userSnapshot.exists && userSnapshot.value != null) {
                  final userData = Map<String, dynamic>.from(
                    (userSnapshot.value as Map).map((k, v) => MapEntry(k.toString(), v))
                  );
                  
                  // Merge user data with reel
                  final updatedReel = reel.copyWith(
                    userName: userData['name'] ?? userData['displayName'] ?? userData['username'] ?? 'مستخدم',
                    userProfilePic: userData['image'] ?? userData['photoURL'] ?? userData['profilePic'] ?? userData['avatar'] ?? '',
                  );
                  reels.add(updatedReel);
                } else {
                  // Use original reel but ensure we have at least a user name
                  final fallbackReel = reel.userName.isEmpty 
                    ? reel.copyWith(userName: 'مستخدم')
                    : reel;
                  reels.add(fallbackReel);
                }
              } catch (e) {
                debugPrint('🎬 FETCH: Failed to fetch user data for ${reel.userId}: $e');
                // Use original reel but ensure we have at least a user name
                final fallbackReel = reel.userName.isEmpty 
                  ? reel.copyWith(userName: 'مستخدم')
                  : reel;
                reels.add(fallbackReel);
              }
            } else {
              // For reels without userId, use default user info
              final defaultReel = reel.copyWith(
                userId: reel.userId.isEmpty ? 'anonymous_user' : reel.userId,
                userName: reel.userName.isEmpty ? 'مستخدم' : reel.userName,
              );
              reels.add(defaultReel);
            }
          }
        } catch (e) {
          debugPrint('🎬 FETCH: Error processing reel entry ${entry.key}: $e');
          // Continue processing other reels even if one fails
        }
      }

      debugPrint("🎬 FETCH: Successfully processed ${reels.length} reels");
      return reels.reversed.toList();
      
    } catch (e, stackTrace) {
      debugPrint('🎬 FETCH ERROR: Failed to fetch reels - $e');
      debugPrint('🎬 Stack trace: $stackTrace');
      
      // Don't rethrow - return empty list instead to prevent bloc from getting stuck
      // This allows the UI to show an empty state instead of infinite loading
      return [];
    }
  }

  /// Save reel to Realtime Database
  Future<void> saveReel(VideoModel video) async {
    final ref = FirebaseDatabase.instance.ref(_reelsPath);

    // Create reel data with user info
    final reelData = {
      "videoUrl": video.videoUrl,
      "userId": video.userId,
      "userName": video.userName,
      "userProfilePic": video.userProfilePic,
      "caption": video.caption,
      "thumbnailUrl": video.thumbnailUrl,
      "likes": 0,
      "comments": 0,
      "shares": 0,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    await ref.push().set(reelData);

    print("🎬 REEL: Saved reel to Firebase for user ${video.userId}");
  }

  /// Toggle like status for a video and update like count
  Future<void> toggleLike(String videoId, String userId, bool isLiked) async {
    final videoRef = FirebaseDatabase.instance.ref('$_reelsPath/$videoId');
    final likedByRef = videoRef.child('likedBy/$userId');

    if (isLiked) {
      await likedByRef.set(true);
      await videoRef.child('likesCount').set(ServerValue.increment(1));
    } else {
      await likedByRef.remove();
      await videoRef.child('likesCount').set(ServerValue.increment(-1));
    }
  }

  /// Add a comment to a video and update comment count
  Future<void> addComment(String videoId, String userId, String commentText) async {
    final videoRef = FirebaseDatabase.instance.ref('$_reelsPath/$videoId');
    final commentsRef = videoRef.child('comments').push();

    await commentsRef.set({
      'uid': userId,
      'text': commentText.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await videoRef.child('commentsCount').set(ServerValue.increment(1));
  }

  /// Fetch comments for a specific video
  Future<List<Map<String, dynamic>>> getComments(String videoId) async {
    final commentsRef = FirebaseDatabase.instance.ref('$_reelsPath/$videoId/comments');
    final snapshot = await commentsRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final rawData = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final List<Map<String, dynamic>> comments = [];

    rawData.forEach((key, value) {
      if (value is Map) {
        comments.add(Map<String, dynamic>.from(value.map((k, v) => MapEntry(k.toString(), v))));
      }
    });
    return comments;
  }

  /// Increment share count for a video
  Future<void> shareVideo(String videoId) async {
    final videoRef = FirebaseDatabase.instance.ref('$_reelsPath/$videoId');
    await videoRef.child('sharesCount').set(ServerValue.increment(1));
  }
}
