import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../bloc/reels_cubit.dart';
import '../../data/models/video_model.dart';

/// Reels View - TikTok style vertical scrolling reels
class ReelsView extends StatefulWidget {
  const ReelsView({super.key});

  @override
  State<ReelsView> createState() => _ReelsViewState();
}

class _ReelsViewState extends State<ReelsView> {
  late PageController _pageController;
  late List<VideoPlayerController> _videoControllers;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _videoControllers = [];
    
    // Fetch reels when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelsCubit>().fetchReels();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<ReelsCubit, ReelsState>(
        builder: (context, state) {
          if (state is ReelsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          if (state is ReelsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ReelsCubit>().refreshReels();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (state is ReelsLoaded) {
            final reels = state.reels;
            
            if (reels.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد فيديوهات حالياً',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Initialize video controllers
            _initializeVideoControllers(reels);

            return Stack(
              children: [
                // Main PageView for vertical scrolling
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: reels.length,
                  onPageChanged: (index) {
                    _currentIndex = index;
                    _playVideo(index);
                  },
                  itemBuilder: (context, index) {
                    final reel = reels[index];
                    return _ReelPage(
                      reel: reel,
                      videoController: _videoControllers[index],
                      onLike: () => _toggleLike(reel),
                      onShare: () => _shareReel(reel),
                      onSave: () => _saveReel(reel),
                    );
                  },
                ),

                // Right side actions overlay
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Like button
                      _ActionButton(
                        icon: Icons.favorite,
                        isActive: reels[_currentIndex].isLikedByCurrentUser,
                        count: reels[_currentIndex].likesCount,
                        onTap: () => _toggleLike(reels[_currentIndex]),
                      ),
                      
                      // Comment button
                      _ActionButton(
                        icon: Icons.comment,
                        count: reels[_currentIndex].commentsCount,
                        onTap: () => _showComments(reels[_currentIndex]),
                      ),
                      
                      // Share button
                      _ActionButton(
                        icon: Icons.share,
                        count: reels[_currentIndex].sharesCount,
                        onTap: () => _shareReel(reels[_currentIndex]),
                      ),
                      
                      // Save button
                      _ActionButton(
                        icon: Icons.bookmark,
                        count: reels[_currentIndex].savesCount,
                        onTap: () => _saveReel(reels[_currentIndex]),
                      ),
                    ],
                  ),
                ),

                // Top overlay
                Positioned(
                  top: 40,
                  left: 16,
                  right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              reels[_currentIndex].userProfilePic,
                            ),
                            backgroundColor: Colors.grey,
                            child: const Icon(Icons.person),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reels[_currentIndex].userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Caption
                      Text(
                        reels[_currentIndex].caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _initializeVideoControllers(List<VideoModel> reels) {
    // Dispose old controllers
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    
    // Create new controllers
    _videoControllers = reels.map((reel) {
      return VideoPlayerController.networkUrl(Uri.parse(reel.videoUrl));
    }).toList();

    // Initialize and play first video
    if (_videoControllers.isNotEmpty) {
      _playVideo(0);
    }
  }

  void _playVideo(int index) async {
    if (index >= 0 && index < _videoControllers.length) {
      // Pause all other videos
      for (int i = 0; i < _videoControllers.length; i++) {
        if (i != index) {
          _videoControllers[i].pause();
        }
      }

      // Play current video
      final controller = _videoControllers[index];
      try {
        await controller.initialize();
        controller.setLooping(true);
        controller.play();
      } catch (e) {
        debugPrint('Error playing video: $e');
      }
    }
  }

  void _toggleLike(VideoModel reel) {
    context.read<ReelsCubit>().toggleLike(
      reel.id,
      'current_user_id', // Replace with actual user ID
    );
  }

  void _shareReel(VideoModel reel) {
    context.read<ReelsCubit>().shareReel(reel.id);
    // You can add share functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم المشاركة!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveReel(VideoModel reel) {
    context.read<ReelsCubit>().saveReel(
      reel.id,
      'current_user_id', // Replace with actual user ID
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم الحفظ!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showComments(VideoModel reel) {
    // Navigate to comments screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(reelId: reel.id),
      ),
    );
  }
}

/// Individual Reel Page Widget
class _ReelPage extends StatelessWidget {
  final VideoModel reel;
  final VideoPlayerController videoController;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const _ReelPage({
    required this.reel,
    required this.videoController,
    required this.onLike,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        Center(
          child: videoController.value.isInitialized
              ? AspectRatio(
                  aspectRatio: videoController.value.aspectRatio,
                  child: VideoPlayer(videoController),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
        ),

        // Gradient overlay for better text visibility
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.transparent,
                Colors.black26,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int? count;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.count,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.red : Colors.white,
              size: 28,
            ),
            if (count != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatCount(count!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Comments Screen (placeholder)
class CommentsScreen extends StatelessWidget {
  final String reelId;

  const CommentsScreen({
    super.key,
    required this.reelId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'التعليقات',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text(
          'قسم التعليقات قيد التطوير',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
