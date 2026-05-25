import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// يفصل مسار جلب ملف الفيديو من الكاش عن [VideoControllerManager] لسهولة الاختبار والتهيئة.
abstract class ReelVideoFileResolver {
  Future<File> getSingleFile(String url);
}

/// التنفيذ الافتراضي عبر [DefaultCacheManager] (إنتاج).
/// الإنشاء كسول — لا يُفعَّل [path_provider] حتى أول [getSingleFile].
class DefaultReelVideoFileResolver implements ReelVideoFileResolver {
  DefaultReelVideoFileResolver([BaseCacheManager? injected]) : _injected = injected;

  final BaseCacheManager? _injected;
  BaseCacheManager? _cache;

  BaseCacheManager get _manager => _injected ?? (_cache ??= DefaultCacheManager());

  @override
  Future<File> getSingleFile(String url) => _manager.getSingleFile(url);
}
