import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/video_model.dart';

/// Reels Repository
/// Fetches videos from reels path in Firebase Realtime Database
class ReelsRepository {
  final DatabaseReference _database = FirebaseDatabase.instance.ref('reels');

  /// Get all reels
  Future<List<VideoModel>> getAllReels() async {
    try {
      final snapshot = await _database.get();
      
      if (snapshot.value == null) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return [];
      }

      final reels = <VideoModel>[];
      
      data.forEach((key, value) {
        try {
          if (value is Map) {
            final videoData = Map<String, dynamic>.from(value);
            final videoModel = VideoModel.fromJson(videoData, key.toString());
            reels.add(videoModel);
          }
        } catch (e) {
          debugPrint('Error parsing reel $key: $e');
        }
      });

      // Sort by timestamp (newest first)
      reels.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return reels;
    } catch (e) {
      debugPrint('Error fetching reels: $e');
      throw Exception('Failed to fetch reels: $e');
    }
  }

  /// Get reels stream
  Stream<List<VideoModel>> getReelsStream() {
    return _database.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return [];
      }

      final reels = <VideoModel>[];
      
      data.forEach((key, value) {
        try {
          if (value is Map) {
            final videoData = Map<String, dynamic>.from(value);
            final videoModel = VideoModel.fromJson(videoData, key.toString());
            reels.add(videoModel);
          }
        } catch (e) {
          debugPrint('Error parsing reel $key: $e');
        }
      });

      // Sort by timestamp (newest first)
      reels.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return reels;
    });
  }

  /// Get single reel by ID
  Future<VideoModel?> getReelById(String id) async {
    try {
      final snapshot = await _database.child(id).get();
      
      if (snapshot.value == null) {
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return VideoModel.fromJson(data, id);
    } catch (e) {
      debugPrint('Error fetching reel $id: $e');
      throw Exception('Failed to fetch reel: $e');
    }
  }

  /// Like/Unlike a reel
  Future<void> toggleLike(String reelId, String userId, bool isLiked) async {
    try {
      final likeRef = _database.child(reelId).child('likes').child(userId);
      
      if (isLiked) {
        await likeRef.remove();
      } else {
        await likeRef.set(true);
      }
      
      // Update likes count
      final reelRef = _database.child(reelId);
      final snapshot = await reelRef.get();
      
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int currentLikes = 0;
        
        if (data['likesCount'] != null) {
          currentLikes = int.tryParse(data['likesCount'].toString()) ?? 0;
        }
        
        final newLikesCount = isLiked ? currentLikes - 1 : currentLikes + 1;
        await reelRef.update({'likesCount': newLikesCount});
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Add comment to reel
  Future<void> addComment(String reelId, String userId, String userName, String comment) async {
    try {
      final commentsRef = _database.child(reelId).child('comments');
      final newComment = {
        'userId': userId,
        'userName': userName,
        'comment': comment,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await commentsRef.push().set(newComment);
      
      // Update comments count
      final reelRef = _database.child(reelId);
      final snapshot = await reelRef.get();
      
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int currentComments = 0;
        
        if (data['commentsCount'] != null) {
          currentComments = int.tryParse(data['commentsCount'].toString()) ?? 0;
        }
        
        final newCommentsCount = currentComments + 1;
        await reelRef.update({'commentsCount': newCommentsCount});
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Share a reel
  Future<void> shareReel(String reelId) async {
    try {
      final reelRef = _database.child(reelId);
      final snapshot = await reelRef.get();
      
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int currentShares = 0;
        
        if (data['sharesCount'] != null) {
          currentShares = int.tryParse(data['sharesCount'].toString()) ?? 0;
        }
        
        final newSharesCount = currentShares + 1;
        await reelRef.update({'sharesCount': newSharesCount});
      }
    } catch (e) {
      debugPrint('Error sharing reel: $e');
      throw Exception('Failed to share reel: $e');
    }
  }

  /// Save a reel
  Future<void> saveReel(String reelId, String userId) async {
    try {
      final savesRef = _database.child(reelId).child('saves').child(userId);
      await savesRef.set(true);
      
      // Update saves count
      final reelRef = _database.child(reelId);
      final snapshot = await reelRef.get();
      
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int currentSaves = 0;
        
        if (data['savesCount'] != null) {
          currentSaves = int.tryParse(data['savesCount'].toString()) ?? 0;
        }
        
        final newSavesCount = currentSaves + 1;
        await reelRef.update({'savesCount': newSavesCount});
      }
    } catch (e) {
      debugPrint('Error saving reel: $e');
      throw Exception('Failed to save reel: $e');
    }
  }

  /// Upload new reel
  Future<void> uploadReel(VideoModel reel) async {
    try {
      final newReelRef = _database.push();
      await newReelRef.set(reel.toMap());
    } catch (e) {
      debugPrint('Error uploading reel: $e');
      throw Exception('Failed to upload reel: $e');
    }
  }

  /// Delete a reel
  Future<void> deleteReel(String reelId) async {
    try {
      await _database.child(reelId).remove();
    } catch (e) {
      debugPrint('Error deleting reel: $e');
      throw Exception('Failed to delete reel: $e');
    }
  }

  /// Search reels by caption
  Future<List<VideoModel>> searchReels(String query) async {
    try {
      final allReels = await getAllReels();
      
      if (query.isEmpty) {
        return allReels;
      }
      
      final searchQuery = query.toLowerCase();
      return allReels.where((reel) {
        return reel.caption.toLowerCase().contains(searchQuery) ||
               reel.userName.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching reels: $e');
      throw Exception('Failed to search reels: $e');
    }
  }
}
