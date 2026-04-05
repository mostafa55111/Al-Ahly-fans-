import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/providers/video_preload_manager.dart';

class ReelVideoPlayerPreloaded extends StatefulWidget {
  final String videoUrl;
  final int videoIndex;
  final bool isFocused;
  final bool isMuted;
  final VideoPreloadManager preloadManager;

  const ReelVideoPlayerPreloaded({
    super.key,
    required this.videoUrl,
    required this.videoIndex,
    required this.isFocused,
    required this.isMuted,
    required this.preloadManager,
  });

  @override
  State<ReelVideoPlayerPreloaded> createState() => _ReelVideoPlayerPreloadedState();
}

class _ReelVideoPlayerPreloadedState extends State<ReelVideoPlayerPreloaded> {
  bool _isPlaying = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _setupVideoListener();
  }

  @override
  void didUpdateWidget(ReelVideoPlayerPreloaded oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle focus changes
    if (widget.isFocused != oldWidget.isFocused) {
      if (widget.isFocused) {
        _playVideo();
      } else {
        _pauseVideo();
      }
    }
    
    // Handle mute changes
    if (widget.isMuted != oldWidget.isMuted) {
      _updateVolume();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _setupVideoListener() {
    // Listen to preload manager for controller updates
    widget.preloadManager.addListener(_onPreloadManagerChanged);
  }

  void _onPreloadManagerChanged() {
    if (!mounted || _isDisposed) return;
    
    final controller = widget.preloadManager.getController(widget.videoIndex);
    if (controller != null && widget.preloadManager.isInitialized(widget.videoIndex)) {
      _updatePlayingState();
    }
  }

  void _updatePlayingState() {
    final controller = widget.preloadManager.getController(widget.videoIndex);
    if (controller != null && widget.preloadManager.isInitialized(widget.videoIndex)) {
      final isPlaying = controller.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    }
  }

  void _playVideo() async {
    await widget.preloadManager.playVideo(widget.videoIndex);
    _updateVolume();
  }

  void _pauseVideo() async {
    await widget.preloadManager.pauseVideo(widget.videoIndex);
  }

  void _updateVolume() {
    final volume = widget.isMuted ? 0.0 : 1.0;
    widget.preloadManager.setVolume(widget.videoIndex, volume);
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.preloadManager.getController(widget.videoIndex);
    final isInitialized = widget.preloadManager.isInitialized(widget.videoIndex);
    
    // Show loading when not initialized
    if (!isInitialized || controller == null) {
      return Container(
        color: Colors.black,
        child: widget.isFocused 
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : const SizedBox.shrink(), // No loading indicator when not focused
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          
          // Play/Pause Overlay - only show when paused and focused
          if (!_isPlaying && widget.isFocused)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
