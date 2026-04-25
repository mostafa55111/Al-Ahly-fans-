import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/providers/video_cache_manager.dart';

class VideoPreloadManager extends ChangeNotifier {
  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, bool> _isInitialized = {};
  final Map<int, bool> _isDisposed = {};
  final int _maxControllers = 2;
  final VideoCacheManager _cacheManager;
  
  int _currentIndex = -1;
  int _totalVideos = 0;
  List<String> _videoUrls = [];

  VideoPreloadManager() : _cacheManager = VideoCacheManager();

  /// Set video URLs for preload management
  void setVideoUrls(List<String> urls) {
    _videoUrls = urls;
    _totalVideos = urls.length;
    _cleanupOldControllers();
  }

  /// Set total number of videos for preload management (legacy support)
  void setTotalVideos(int total) {
    _totalVideos = total;
    _cleanupOldControllers();
  }

  /// Update current index and manage preloading
  void updateCurrentIndex(int newIndex) {
    if (newIndex == _currentIndex) {
      debugPrint('🎥 INDEX: No change, current index is $_currentIndex');
      return;
    }
    
    final oldIndex = _currentIndex;
    _currentIndex = newIndex;
    
    debugPrint('🎥 INDEX CHANGED: $oldIndex → $newIndex');
    debugPrint('🎥 ACTIVE CONTROLLERS BEFORE UPDATE: ${_controllers.keys.toList()}');
    
    // Dispose previous controller (index - 1)
    if (oldIndex >= 0) {
      debugPrint('🎥 DISPOSING PREVIOUS: Index $oldIndex');
      _disposeController(oldIndex);
    }
    
    // Preload current video if not already loaded
    debugPrint('🎥 PRELOADING CURRENT: Index $newIndex');
    _preloadVideo(newIndex);
    
    // Preload next video
    debugPrint('🎥 PRELOADING NEXT: Index ${newIndex + 1}');
    _preloadVideo(newIndex + 1);
    
    // Cleanup any controllers beyond the allowed range
    debugPrint('🎥 CLEANUP: Checking for excess controllers');
    _cleanupOldControllers();
    
    debugPrint('🎥 ACTIVE CONTROLLERS AFTER UPDATE: ${_controllers.keys.toList()}');
    debugPrint('🎥 CONTROLLER COUNT: ${_controllers.length}/$_maxControllers');
  }

  /// Preload a single video with caching
  Future<void> _preloadVideo(int index) async {
    if (index < 0 || index >= _totalVideos) {
      debugPrint('🎥 PRELOAD: Index $index out of bounds (0-$_totalVideos)');
      return;
    }
    
    if (_controllers.containsKey(index)) {
      debugPrint('🎥 PRELOAD: Controller for index $index already exists');
      return;
    }
    
    if (_isDisposed[index] == true) {
      debugPrint('🎥 PRELOAD: Controller for index $index was disposed, skipping');
      return;
    }
    
    debugPrint('🎥 PRELOAD: Starting preload for index $index');
    debugPrint('🎥 ACTIVE CONTROLLERS: ${_controllers.length} (max allowed: $_maxControllers)');
    
    try {
      final videoUrl = _getVideoUrl(index);
      
      // Check if video is already cached
      final isCached = await _cacheManager.isVideoCached(videoUrl);
      
      VideoPlayerController controller;
      
      if (isCached) {
        // Use cached file
        final cachedPath = await _cacheManager.getCachedVideoPath(videoUrl);
        controller = VideoPlayerController.file(File(cachedPath!));
        debugPrint('🎥 PRELOAD: Using cached file for index $index');
      } else {
        // Cache and use network URL (will be cached during initialization)
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        debugPrint('🎥 PRELOAD: Using network URL for index $index');
      }
      
      // Track controller creation
      _controllers[index] = controller;
      _isDisposed[index] = false;
      debugPrint('🎥 CONTROLLER CREATED: Index $index (total: ${_controllers.length})');
      
      // Initialize with timeout
      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('🎥 TIMEOUT: Video initialization timeout for index $index');
          _disposeController(index);
        },
      );
      
      // Configure controller
      controller.setLooping(true);
      controller.setVolume(0.0); // Muted by default
      
      _isInitialized[index] = true;
      debugPrint('🎥 CONTROLLER INITIALIZED: Index $index (cached: $isCached)');
      debugPrint('🎥 ACTIVE CONTROLLERS: ${_controllers.keys.toList()}');
      
    } catch (e) {
      debugPrint('🎥 ERROR: Failed to preload video $index: $e');
      _disposeController(index);
    }
  }

  /// Get controller for specific index
  VideoPlayerController? getController(int index) {
    return _controllers[index];
  }

  /// Check if video is initialized
  bool isInitialized(int index) {
    return _isInitialized[index] == true;
  }

  /// Set volume for a specific controller
  void setVolume(int index, double volume) {
    final controller = _controllers[index];
    if (controller != null && _isInitialized[index] == true) {
      controller.setVolume(volume);
    }
  }

  /// Play video at specific index
  Future<void> playVideo(int index) async {
    final controller = _controllers[index];
    if (controller != null && _isInitialized[index] == true) {
      await controller.play();
    }
  }

  /// Pause video at specific index
  Future<void> pauseVideo(int index) async {
    final controller = _controllers[index];
    if (controller != null && _isInitialized[index] == true) {
      await controller.pause();
    }
  }

  /// Dispose specific controller
  void _disposeController(int index) {
    final controller = _controllers[index];
    if (controller != null) {
      debugPrint('🎥 DISPOSE: Starting disposal for index $index');
      debugPrint('🎥 ACTIVE CONTROLLERS BEFORE: ${_controllers.keys.toList()}');
      
      try {
        controller.pause();
        controller.dispose();
        _controllers.remove(index);
        _isInitialized.remove(index);
        _isDisposed[index] = true;
        
        debugPrint('🎥 CONTROLLER DISPOSED: Index $index (remaining: ${_controllers.length})');
        debugPrint('🎥 ACTIVE CONTROLLERS AFTER: ${_controllers.keys.toList()}');
      } catch (e) {
        debugPrint('🎥 ERROR: Failed to dispose controller $index: $e');
        // Force cleanup even if dispose fails
        _controllers.remove(index);
        _isInitialized.remove(index);
        _isDisposed[index] = true;
      }
    } else {
      debugPrint('🎥 DISPOSE: No controller found for index $index');
    }
  }

  /// Cleanup old controllers beyond allowed range
  void _cleanupOldControllers() {
    final keysToRemove = <int>[];
    
    debugPrint('🎥 CLEANUP: Evaluating ${_controllers.length} controllers');
    debugPrint('🎥 CLEANUP: Current index: $_currentIndex, Keep range: [$_currentIndex, ${_currentIndex + 1}]');
    
    for (final key in _controllers.keys) {
      // Keep only current and next video
      if (key != _currentIndex && key != _currentIndex + 1) {
        keysToRemove.add(key);
        debugPrint('🎥 CLEANUP: Marked controller $key for removal');
      } else {
        debugPrint('🎥 CLEANUP: Keeping controller $key');
      }
    }
    
    debugPrint('🎥 CLEANUP: Removing ${keysToRemove.length} controllers');
    for (final key in keysToRemove) {
      _disposeController(key);
    }
    
    debugPrint('🎥 CLEANUP COMPLETE: ${_controllers.length}/$_maxControllers controllers active');
  }

  /// Dispose all controllers
  void disposeAll() {
    debugPrint('🎥 DISPOSE ALL: Starting disposal of ${_controllers.length} controllers');
    debugPrint('🎥 DISPOSE ALL: Controllers to dispose: ${_controllers.keys.toList()}');
    
    for (final controller in _controllers.values) {
      try {
        controller.pause();
        controller.dispose();
      } catch (e) {
        debugPrint('🎥 ERROR: Failed to dispose controller: $e');
      }
    }
    
    _controllers.clear();
    _isInitialized.clear();
    _isDisposed.clear();
    
    debugPrint('🎥 DISPOSE ALL: Complete - all controllers disposed');
  }

  /// Get video URL for index
  String _getVideoUrl(int index) {
    if (index >= 0 && index < _videoUrls.length) {
      return _videoUrls[index];
    }
    // Fallback to placeholder URL
    return 'https://example.com/video_$index.mp4';
  }

  /// Get current active controllers count
  int get activeControllersCount => _controllers.length;

  /// Get current index
  int get currentIndex => _currentIndex;

  /// Get cache manager
  VideoCacheManager get cacheManager => _cacheManager;

  /// Preload videos with caching
  Future<void> preloadVideosWithCache(List<String> urls) async {
    await _cacheManager.preloadVideos(urls);
  }

  /// Check if video is cached
  Future<bool> isVideoCached(String url) async {
    return await _cacheManager.isVideoCached(url);
  }

  /// Get cached video path
  Future<String?> getCachedVideoPath(String url) async {
    return await _cacheManager.getCachedVideoPath(url);
  }

  /// Clear video cache
  Future<void> clearCache() async {
    await _cacheManager.clearCache();
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    return await _cacheManager.getCacheSize();
  }
}
