import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/providers/video_cache_manager.dart';

class CachedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isFocused;
  final bool isMuted;
  final VideoCacheManager cacheManager;

  const CachedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isFocused,
    required this.isMuted,
    required this.cacheManager,
  });

  @override
  State<CachedVideoPlayer> createState() => _CachedVideoPlayerState();
}

class _CachedVideoPlayerState extends State<CachedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isDisposed = false;
  bool _isLoading = false;
  String? _cachedPath;

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 CACHED PLAYER: initState for ${widget.videoUrl} (focused: ${widget.isFocused})');
    if (widget.isFocused) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(CachedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    debugPrint('🎬 CACHED PLAYER: didUpdateWidget - focus: ${oldWidget.isFocused} → ${widget.isFocused}');
    
    // Handle focus changes
    if (widget.isFocused != oldWidget.isFocused) {
      if (widget.isFocused) {
        debugPrint('🎬 CACHED PLAYER: Gained focus, initializing video');
        _initializeVideo();
      } else {
        debugPrint('🎬 CACHED PLAYER: Lost focus, pausing video');
        _pauseVideo();
      }
    }
    
    // Handle mute changes
    if (widget.isMuted != oldWidget.isMuted && _controller != null && _isInitialized) {
      debugPrint('🎬 CACHED PLAYER: Volume changed: ${widget.isMuted}');
      _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
  }

  @override
  void dispose() {
    debugPrint('🎬 CACHED PLAYER: dispose called for ${widget.videoUrl}');
    _isDisposed = true;
    _disposeVideo();
    super.dispose();
    debugPrint('🎬 CACHED PLAYER: dispose completed');
  }

  Future<void> _initializeVideo() async {
    if (_isInitialized || _isDisposed) {
      debugPrint('🎬 CACHED PLAYER: Skipping initialization (initialized: $_isInitialized, disposed: $_isDisposed)');
      return;
    }
    
    debugPrint('🎬 CACHED PLAYER: Starting initialization for ${widget.videoUrl}');
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if video is already cached
      final cachedPath = await widget.cacheManager.getCachedVideoPath(widget.videoUrl);
      
      if (cachedPath != null) {
        // Use cached file
        _cachedPath = cachedPath;
        _controller = VideoPlayerController.file(
          _getCachedFile(cachedPath),
        );
        debugPrint('🎬 CACHED PLAYER: Using cached video: ${widget.videoUrl}');
      } else {
        // Cache and play
        _cachedPath = await widget.cacheManager.cacheVideo(widget.videoUrl);
        _controller = VideoPlayerController.file(
          _getCachedFile(_cachedPath!),
        );
        debugPrint('🎬 CACHED PLAYER: Cached and playing video: ${widget.videoUrl}');
      }
      
      // Initialize controller
      await _controller!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Video initialization timeout');
        },
      );
      
      if (_isDisposed) {
        _controller?.dispose();
        _controller = null;
        return;
      }
      
      // Configure controller
      _controller!.addListener(_videoListener);
      _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
      _controller!.setLooping(true);
      
      // Start playing if focused
      if (widget.isFocused) {
        await _controller!.play();
      }
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  File _getCachedFile(String path) {
    return File(path);
  }

  void _disposeVideo() {
    if (_controller != null) {
      debugPrint('🎬 CACHED PLAYER: Disposing controller for ${widget.videoUrl}');
      try {
        _controller!.removeListener(_videoListener);
        _controller!.pause();
        _controller!.dispose();
        _controller = null;
        debugPrint('🎬 CACHED PLAYER: Controller disposed successfully');
      } catch (e) {
        debugPrint('🎬 CACHED PLAYER: Error disposing controller: $e');
        _controller = null; // Force clear even on error
      }
    } else {
      debugPrint('🎬 CACHED PLAYER: No controller to dispose');
    }
    
    if (mounted && !_isDisposed) {
      setState(() {
        _isInitialized = false;
        _isPlaying = false;
        _isLoading = false;
      });
    }
  }

  void _videoListener() {
    if (_controller == null || _isDisposed || !mounted) return;
    
    final value = _controller!.value;
    
    // Only update state if playing status changed
    if (value.isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = value.isPlaying;
      });
    }
    
    // Auto-loop when video ends
    if (value.position >= value.duration && 
        value.duration.inMilliseconds > 0 && 
        widget.isFocused) {
      _controller!.seekTo(Duration.zero);
      _controller!.play();
    }
  }

  
  Future<void> _pauseVideo() async {
    if (_controller != null && _isInitialized && _isPlaying && !_isDisposed) {
      await _controller!.pause();
    }
  }

  void _togglePlayPause() {
    if (_controller != null && _isInitialized && !_isDisposed) {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: widget.isFocused 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading video...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: widget.isFocused 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.white54,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Video unavailable',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
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
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          
          // Cache indicator (for debugging)
          if (_cachedPath != null && widget.isFocused)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'CACHED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // Play/Pause Overlay
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
