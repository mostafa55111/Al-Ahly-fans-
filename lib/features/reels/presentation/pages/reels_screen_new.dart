import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/bloc/reels_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/reel_item.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/loading_widget.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/error_widget.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/cache_info_widget.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/providers/video_preload_manager.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'dart:io'; // For File type in upload

class ReelsScreenNew extends StatefulWidget {
  const ReelsScreenNew({super.key});

  @override
  State<ReelsScreenNew> createState() => _ReelsScreenStateNew();
}

class _ReelsScreenStateNew extends State<ReelsScreenNew> {
  late PageController _pageController;
  late VideoPreloadManager _preloadManager;
  int _currentPage = 0;
  int _targetPage = 0;
  bool _isPageChanging = false;

  // Get current user ID (replace with actual auth service integration)
  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';
  String get _currentUserName => FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous';
  String get _currentUserProfilePic => FirebaseAuth.instance.currentUser?.photoURL ?? '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _preloadManager = VideoPreloadManager();

    // Load initial reels
    context.read<ReelsBloc>().add(const LoadReelsEvent());

    // Listen to page changes for pagination
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _preloadManager.disposeAll();
    super.dispose();
  }

  void _onPageChanged() {
    final newPage = _pageController.page?.round() ?? 0;

    if (newPage != _targetPage) {
      _targetPage = newPage;
      _isPageChanging = true;

      _preloadManager.updateCurrentIndex(newPage);

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && newPage == _targetPage) {
          setState(() {
            _currentPage = newPage;
            _isPageChanging = false;
          });
          _loadMoreIfNeeded();
        }
      });
    }
  }

  void _loadMoreIfNeeded() {
    final bloc = context.read<ReelsBloc>();
    if (bloc.state is ReelsLoaded) {
      final currentState = bloc.state as ReelsLoaded;
      if (_currentPage >= currentState.reels.length - 2 && currentState.hasMore) {
        bloc.add(const LoadMoreReelsEvent());
      }
    }
  }

  void _showCommentDialog(BuildContext context, String videoId) {
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Add a comment...', 
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (commentController.text.isNotEmpty) {
                      context.read<ReelsBloc>().add(
                        AddCommentEvent(
                          videoId: videoId,
                          userId: _currentUserId,
                          commentText: commentController.text,
                        ),
                      );
                      Navigator.pop(context); // Close the dialog
                    }
                  },
                  child: const Text('Post Comment'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Placeholder for video upload (integrate with image picker/file picker)
  void _uploadVideoPlaceholder() {
    // In a real app, you would use image_picker or file_picker here
    // For demonstration, let's simulate an upload with a dummy file and data
    // This part needs actual implementation to select a video file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload functionality not fully implemented yet. Select a video file first.')),
    );
    // Example of how you would dispatch the event once a file is selected:
    // final File videoFile = File('path/to/your/video.mp4');
    // context.read<ReelsBloc>().add(
    //   UploadVideoEvent(
    //     file: videoFile,
    //     caption: 'My new reel!',
    //     userId: _currentUserId,
    //     userName: _currentUserName,
    //     userProfilePic: _currentUserProfilePic,
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<ReelsBloc, ReelsState>(
        listener: (context, state) {
          if (state is ReelsLoaded) {
            // Optimize: Set video URLs for preloading only when the list changes
            final videoUrls = state.reels.map((reel) => reel.videoUrl).toList();
            _preloadManager.setVideoUrls(videoUrls);
          }
        },
        builder: (context, state) {
          if (state is ReelsInitial || state is ReelsLoading) {
            return const LoadingWidget();
          }

          if (state is ReelsError) {
            return ReelsErrorWidget(
              message: state.message,
              onRetry: () => context.read<ReelsBloc>().add(const LoadReelsEvent()),
            );
          }

          if (state is ReelsLoaded) {
            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: state.reels.length,
                  itemBuilder: (context, index) {
                    final reel = state.reels[index];

                    final pageDiff = (index - _currentPage).abs();
                    if (pageDiff > 2) {
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            'Reel ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }

                    return VisibilityDetector(
                      key: Key('reel_${reel.id}'),
                      onVisibilityChanged: (visibilityInfo) {
                        if (visibilityInfo.visibleFraction > 0.5) {
                          // Reel is visible, you can add analytics here
                        }
                      },
                      child: ReelItem(
                        reel: reel,
                        isFocused: index == _currentPage && !_isPageChanging,
                        videoIndex: index,
                        preloadManager: _preloadManager,
                        onLike: () {
                          context.read<ReelsBloc>().add(
                            ToggleLikeEvent(
                              videoId: reel.id,
                              userId: _currentUserId,
                              isLiked: !reel.isLiked,
                            ),
                          );
                        },
                        onComment: () {
                          _showCommentDialog(context, reel.id);
                        },
                        onShare: () {
                          context.read<ReelsBloc>().add(
                            ShareVideoEvent(
                              videoId: reel.id,
                              userId: _currentUserId,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                if (state.isLoadingMore)
                  const Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),

                Positioned(
                  top: 50,
                  left: 10,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CacheInfoWidget(
                          preloadManager: _preloadManager,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.storage,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadVideoPlaceholder,
        child: const Icon(Icons.cloud_upload),
      ),
    );
  }
}
