import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class VideoCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'videoCache';
  static const _maxCacheObjects = 100;

  static VideoCacheManager? _instance;
  factory VideoCacheManager() {
    return _instance ??= VideoCacheManager._();
  }

  VideoCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: _maxCacheObjects,
      repo: JsonCacheInfoRepository(path: 'video_cache_info.json'),
      fileService: HttpFileService(),
    ),
  );

  Future<String> getFilePath() async {
    final directory = await getTemporaryDirectory();
    return path.join(directory.path, key);
  }

  /// Cache video from URL
  Future<String> cacheVideo(String url) async {
    try {
      final fileInfo = await getFileFromCache(url);
      if (fileInfo != null) {
        // Video already cached
        return fileInfo.file.path;
      }

      // Download and cache video
      final downloadedFile = await downloadFile(url);
      return downloadedFile.file.path;
    } catch (e) {
      throw Exception('Failed to cache video: $e');
    }
  }

  /// Check if video is cached
  Future<bool> isVideoCached(String url) async {
    try {
      final fileInfo = await getFileFromCache(url);
      return fileInfo != null && await fileInfo.file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get cached video file path
  Future<String?> getCachedVideoPath(String url) async {
    try {
      final fileInfo = await getFileFromCache(url);
      if (fileInfo != null && await fileInfo.file.exists()) {
        return fileInfo.file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Preload multiple videos
  Future<Map<String, String>> preloadVideos(List<String> urls) async {
    final results = <String, String>{};
    
    for (final url in urls) {
      try {
        final cachedPath = await cacheVideo(url);
        results[url] = cachedPath;
      } catch (e) {
        debugPrint('Failed to preload video $url: $e');
        results[url] = url; // Fallback to original URL
      }
    }
    
    return results;
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      await emptyCache();
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    try {
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory(path.join(directory.path, key));
      
      if (!await cacheDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final file in cacheDir.list()) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}
