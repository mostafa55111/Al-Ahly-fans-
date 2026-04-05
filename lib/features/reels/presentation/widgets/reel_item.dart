import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/video_entity.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/cached_video_player.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/reel_side_actions.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/reel_bottom_section.dart';
import 'package:gomhor_alahly_clean_new/core/services/follow_service.dart';

class ReelItem extends StatefulWidget {
  final VideoEntity reel;
  final bool isFocused;
  final int videoIndex;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final dynamic preloadManager;

  const ReelItem({
    super.key,
    required this.reel,
    required this.isFocused,
    required this.videoIndex,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.preloadManager,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> with SingleTickerProviderStateMixin {
  late AnimationController _heartAnimationController;
  late Animation<double> _heartAnimation;
  bool _isMuted = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null && currentUserId != widget.reel.userId) {
      try {
        final isFollowing = await FollowService.isFollowing(currentUserId, widget.reel.userId);
        if (mounted) {
          setState(() {
            _isFollowing = isFollowing;
          });
        }
      } catch (e) {
        print('🎬 FOLLOW ERROR: Failed to check follow status - $e');
      }
    }
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    widget.onLike();
    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reverse();
    });
  }

  Future<void> _toggleFollow() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId == widget.reel.userId) return;

    try {
      if (_isFollowing) {
        await FollowService.unfollowUser(currentUserId, widget.reel.userId);
      } else {
        await FollowService.followUser(currentUserId, widget.reel.userId);
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });

      print('🎬 FOLLOW: Successfully ${_isFollowing ? 'followed' : 'unfollowed'} user ${widget.reel.userId}');
    } catch (e) {
      print('🎬 FOLLOW ERROR: Failed to toggle follow - $e');
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video Player Background
        Positioned.fill(
          child: CachedVideoPlayer(
            videoUrl: widget.reel.videoUrl,
            isFocused: widget.isFocused,
            isMuted: _isMuted,
            cacheManager: widget.preloadManager.cacheManager,
          ),
        ),
        
        // Double Tap Like Overlay
        Positioned.fill(
          child: GestureDetector(
            onDoubleTap: _onDoubleTap,
            child: Stack(
              children: [
                // Heart Animation
                Center(
                  child: AnimatedBuilder(
                    animation: _heartAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _heartAnimation.value,
                        child: Transform.scale(
                          scale: 1.0 + (_heartAnimation.value * 0.5),
                          child: child,
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Mute Toggle Button
        Positioned(
          top: 50,
          right: 15,
          child: GestureDetector(
            onTap: _toggleMute,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        
        // Follow Button (TikTok Style)
        if (FirebaseAuth.instance.currentUser?.uid != widget.reel.userId)
          Positioned(
            top: 110,
            right: 15,
            child: GestureDetector(
              onTap: _toggleFollow,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isFollowing ? Colors.grey : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isFollowing ? "Following" : "Follow",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        
        // Side Actions (Like, Comment, Share)
        Positioned(
          right: 10,
          bottom: 100,
          child: ReelSideActions(
            reel: widget.reel,
            onLike: widget.onLike,
            onComment: widget.onComment,
            onShare: widget.onShare,
          ),
        ),
        
        // Bottom Section (Caption, User Info)
        Positioned(
          left: 10,
          right: 80,
          bottom: 20,
          child: ReelBottomSection(
            reel: widget.reel,
          ),
        ),
        
        // Progress Bar
        Positioned(
          top: 40,
          left: 10,
          right: 10,
          child: LinearProgressIndicator(
            value: 0.0, // Will be updated by video player
            color: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }
}
