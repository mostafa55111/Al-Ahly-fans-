import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/video_entity.dart';

class ReelSideActions extends StatelessWidget {
  final VideoEntity reel;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const ReelSideActions({
    super.key,
    required this.reel,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // User Profile Picture
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Container(
              color: Colors.grey[600],
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Like Button
        _ActionButton(
          icon: reel.isLiked ? Icons.favorite : Icons.favorite_border,
          isActive: reel.isLiked,
          count: reel.likes.toString(),
          onTap: onLike,
        ),
        
        const SizedBox(height: 20),
        
        // Comment Button
        _ActionButton(
          icon: Icons.comment_outlined,
          isActive: false,
          count: reel.comments.toString(),
          onTap: onComment,
        ),
        
        const SizedBox(height: 20),
        
        // Share Button
        _ActionButton(
          icon: Icons.share,
          isActive: false,
          count: reel.shares.toString(),
          onTap: onShare,
        ),
        
        const SizedBox(height: 20),
        
        // Music Note (for TikTok-style reels)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(77),
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.music_note,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final String count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.isActive,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.red : Colors.white,
              size: 28,
            ),
          ),
        ),
        
        if (count.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            _formatCount(count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  String _formatCount(String count) {
    final number = int.tryParse(count) ?? 0;
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return count;
  }
}
