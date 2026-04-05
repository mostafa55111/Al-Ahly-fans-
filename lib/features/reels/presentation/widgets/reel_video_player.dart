import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isFocused;
  final bool isMuted;

  const ReelVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isFocused,
    required this.isMuted,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isDisposed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Only initialize if focused from the start
    if (widget.isFocused) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle focus changes - strict lifecycle management
    if (widget.isFocused != oldWidget.isFocused) {
      if (widget.isFocused) {
        _initializeVideo(); // Initialize when focused
      } else {
        _disposeVideo(); // Dispose when unfocused
      }
    }
    
    // Handle mute changes if controller exists
    if (widget.isMuted != oldWidget.isMuted && _controller != null && _isInitialized) {
      _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeVideo();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (_isInitialized || _isDisposed) return;
    
    try {
      // Create controller
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      
      // Initialize with timeout to prevent hanging
      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Video initialization timeout');
        },
      );
      
      if (_isDisposed) {
        _controller?.dispose();
        _controller = null;
        return;
      }
      
      // Add listener
      _controller!.addListener(_videoListener);
      
      // Configure controller
      _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
      _controller!.setLooping(true);
      
      // Start playing immediately if focused
      if (widget.isFocused) {
        await _controller!.play();
      }
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _errorMessage = 'VIDEO ERROR: ${e.toString()}';
        });
      }
      // Clean up on error
      _controller?.dispose();
      _controller = null;
    }
  }

  void _disposeVideo() {
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.pause();
      _controller!.dispose();
      _controller = null;
    }
    
    if (mounted && !_isDisposed) {
      setState(() {
        _isInitialized = false;
        _isPlaying = false;
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
    // Show error message if there's an error
    if (_errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'URL: ${widget.videoUrl}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show loading when not initialized
    if (!_isInitialized || _controller == null) {
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
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
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
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
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
