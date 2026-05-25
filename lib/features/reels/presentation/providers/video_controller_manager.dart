import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/reel_video_file_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_video_precache_service.dart';

/// مدير مركزي لدورة حياة مشغّلات الفيديو في شاشة الريلز
///
/// الفكرة:
/// - يحتفظ بنافذة [currentIndex - 1 .. currentIndex + 1] من الـ controllers
/// - يُشغّل الفيديو الحالي تلقائياً ويوقف الباقي
/// - يعمل Preload للفيديو التالي (index + 1) وهو صامت
/// - يتخلّص من أي controller خارج النافذة لتحرير الذاكرة
/// - يحافظ على نفس الـ controllers عند التنقل ذهاباً وإياباً في مدى ±1
/// - يُطلق notifyListeners لإعادة بناء واجهات المستمعين فقط (لا rebuild للـ PageView)
class VideoControllerManager extends ChangeNotifier {
  VideoControllerManager({
    ReelVideoFileResolver? fileResolver,
  }) : _fileResolver = fileResolver ?? DefaultReelVideoFileResolver();

  /// كم فيديو نحتفظ به خلف الفيديو الحالي (لتسريع العودة)
  static const int _backwardKeep = 1;

  /// كم فيديو نفتحه أمام الفيديو الحالي (Preload)
  /// ═══════════════════════════════════════════════════════════════
  /// 3 = التالي + اثنين أمامهم + تحميل مسبق للملف على القرص → تقليل التقطيع.
  static const int _forwardPreload = 3;

  /// أقصى عدد لمهام التحميل المسبق في الخلفية بالتوازي (تخفيف قفزات CPU).
  static const int _maxConcurrentPrefetches = 3;

  final ReelVideoFileResolver _fileResolver;

  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, Completer<void>> _initializers = {};
  final Map<int, String> _indexToUrl = {};

  List<String> _urls = const [];
  int _currentIndex = 0;
  bool _isMuted = false;
  bool _disposed = false;

  /// إيقاف عام — لما يبقى true لا يُشغَّل أي فيديو تلقائياً حتى لو تم تحميله.
  /// يُستخدم عند خروج المستخدم من تبويب الريلز لتبويب آخر.
  bool _globallyPaused = false;

  /// آخر إندكس طُبّق عليه منطق التشغيل/الإيقاف — لتحديد ترك الريل السابق فقط عند التنقل الحقيقي.
  int? _lastPlaybackCurrentIndex;

  /// عدّاد مهام التحميل المسبق الجارية (حد أقصى [_maxConcurrentPrefetches]).
  int _prefetchInFlight = 0;

  int get currentIndex => _currentIndex;
  bool get isMuted => _isMuted;
  int get activeControllersCount => _controllers.length;

  /// إعادة ضبط قائمة روابط الفيديوهات.
  /// لو تغيّر الرابط عند نفس الـ index (مثلاً بعد إضافة ريل جديد في الأول)
  /// يتم التخلّص من الـ controller المتعارض وإعادة فتحه.
  void setUrls(List<String> urls) {
    if (_disposed) return;

    // تحديد أي controllers لم تعد تطابق الرابط عند الـ index الخاص بها
    final toRemove = <int>[];
    _controllers.forEach((i, _) {
      if (i >= urls.length || _indexToUrl[i] != urls[i]) {
        toRemove.add(i);
      }
    });
    for (final i in toRemove) {
      _disposeController(i);
    }

    _urls = List<String>.unmodifiable(urls);
    _syncWindow();
    _applyPlaybackState();
    notifyListeners();
    _logMemorySnapshot('setUrls');
  }

  /// تحديث الـ index الحالي عند انتقال المستخدم بين الصفحات
  void setCurrentIndex(int index) {
    if (_disposed || index == _currentIndex) return;
    if (index < 0 || index >= _urls.length) return;

    debugPrint('[VCM] index change: $_currentIndex -> $index');
    _currentIndex = index;
    _syncWindow();
    _applyPlaybackState();
    notifyListeners();
    _logMemorySnapshot('setCurrentIndex');
    hintScrollToward(index);
  }

  /// بعد تقليب الصفحة: تحميل مسبق فوري للفيديو التالي (و+2) لتقليل التقطيع.
  void hintScrollToward(int visibleIndex) {
    if (_disposed) return;
    for (var step = 1; step <= 2; step++) {
      final j = visibleIndex + step;
      if (j >= 0 && j < _urls.length) {
        final u = _urls[j];
        if (u.isNotEmpty) {
          unawaited(ReelsVideoPrecacheService.prefetchUrlOffMainThread(u));
        }
      }
    }
  }

  /// كتم/إلغاء كتم الصوت على كل الـ controllers الحالية
  void setMuted(bool muted) {
    if (_disposed || _isMuted == muted) return;
    _isMuted = muted;
    for (final c in _controllers.values) {
      if (c.value.isInitialized) {
        c.setVolume(muted ? 0 : 1);
      }
    }
    notifyListeners();
  }

  /// يعيد الـ controller المعروف لهذا الـ index (قد يكون null إذا كان خارج النافذة)
  VideoPlayerController? controllerFor(int index) => _controllers[index];

  /// هل الـ controller عند هذا الـ index جاهز للتشغيل؟
  bool isReady(int index) {
    final c = _controllers[index];
    return c != null && c.value.isInitialized && !c.value.hasError;
  }

  /// هل حدث خطأ في الفيديو عند هذا الـ index؟
  bool hasError(int index) {
    final c = _controllers[index];
    return c != null && c.value.hasError;
  }

  /// تبديل تشغيل/إيقاف الفيديو الحالي فقط (يُستدعى من onTap)
  void togglePlayPause() {
    if (_disposed) return;
    final c = _controllers[_currentIndex];
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    notifyListeners();
  }

  /// إيقاف كل الفيديوهات (مفيد عند مغادرة الشاشة مؤقتاً).
  /// يرفع flag `_globallyPaused` ليمنع أي autoplay بعد التحميل.
  void pauseAll() {
    if (_disposed) return;
    _globallyPaused = true;
    for (final c in _controllers.values) {
      if (!c.value.isInitialized) continue;
      try {
        c.pause();
        c.setVolume(0);
      } catch (_) {}
    }
    notifyListeners();
  }

  /// استئناف الفيديو الحالي فقط + إلغاء flag الإيقاف العام.
  void resumeCurrent() {
    if (_disposed) return;
    _globallyPaused = false;
    _applyPlaybackState();
    notifyListeners();
  }

  // ========== internals ==========

  /// تتبع استهلاك الذاكرة المرتبط بمجموعة مشغّلات الفيديو (مؤشرات تشغيل — ليس RSS كاملاً على Web).
  void _logMemorySnapshot(String tag, {String? extra}) {
    if (!kDebugMode) return;
    debugPrint(
      '[VCM|memory] $tag | '
      'controllers=${_controllers.length} | '
      'urls=${_urls.length} | '
      'prefetchInFlight=$_prefetchInFlight | '
      'paused=$_globallyPaused'
      '${extra != null ? ' | $extra' : ''}',
    );
  }

  void _syncWindow() {
    final minKeep = _currentIndex - _backwardKeep;
    final maxKeep = _currentIndex + _forwardPreload;

    // 1) تخلّص من أي controller خارج النافذة
    final outOfWindow = _controllers.keys
        .where((i) => i < minKeep || i > maxKeep)
        .toList(growable: false);
    for (final i in outOfWindow) {
      debugPrint('[VCM] dispose out-of-window controller #$i');
      _disposeController(i);
    }
    _logMemorySnapshot('after_dispose_out_of_window');

    // 2) فتح أي controller مفقود داخل النافذة.
    // ═══════════════════════════════════════════════════════════════
    // نرتّب الأولوية: الحالي أولاً → التالي → +2 → السابق، عشان
    // المستخدم لما يقلب، الفيديو التالي يكون جاهز يشتغل مباشرة بدون أي تحميل.
    final order = <int>[
      _currentIndex,
      for (int offset = 1; offset <= _forwardPreload; offset++)
        _currentIndex + offset,
      for (int offset = 1; offset <= _backwardKeep; offset++)
        _currentIndex - offset,
    ];

    for (final i in order) {
      if (i < minKeep || i > maxKeep) continue;
      if (i < 0 || i >= _urls.length) continue;
      if (_controllers.containsKey(i)) continue;
      _bootstrapController(i);
    }
  }

  /// يحمّل الملف عبر الكاش ثم يعرّف الـ controller — أو الشبكة كاحتياط.
  void _bootstrapController(int index) {
    final url = _urls[index];
    if (url.isEmpty) {
      debugPrint('[VCM] skip init: empty url at #$index');
      return;
    }

    debugPrint('[VCM] preload controller #$index -> $url');
    final completer = Completer<void>();
    _initializers[index] = completer;

    unawaited(_openControllerFromCacheOrNetwork(index, url, completer));
  }

  Future<void> _openControllerFromCacheOrNetwork(
    int index,
    String url,
    Completer<void> completer,
  ) async {
    VideoPlayerController controller;
    try {
      final file = await _fileResolver.getSingleFile(url);
      controller = VideoPlayerController.file(file);
    } catch (e) {
      debugPrint('[VCM] cache/network fallback #$index: $e');
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    if (_disposed) {
      await controller.dispose();
      if (!completer.isCompleted) completer.complete();
      return;
    }

    final minKeep = _currentIndex - _backwardKeep;
    final maxKeep = _currentIndex + _forwardPreload;
    if (index < minKeep ||
        index > maxKeep ||
        index < 0 ||
        index >= _urls.length) {
      await controller.dispose();
      if (!completer.isCompleted) completer.complete();
      return;
    }

    if (_controllers.containsKey(index)) {
      await controller.dispose();
      if (!completer.isCompleted) completer.complete();
      return;
    }

    _controllers[index] = controller;
    _indexToUrl[index] = url;

    controller.initialize().then((_) {
      if (_disposed) {
        controller.dispose();
        return;
      }
      if (!_controllers.containsKey(index) || _controllers[index] != controller) {
        controller.dispose();
        return;
      }
      controller
        ..setLooping(true)
        ..setVolume(_isMuted ? 0 : 1);

      debugPrint('[VCM] ✅ video loaded #$index (${controller.value.size})');
      if (index == _currentIndex && !_globallyPaused) {
        controller.play();
      }
      _warmForwardUrls(fromIndex: index);
      if (!completer.isCompleted) completer.complete();
      notifyListeners();
      _logMemorySnapshot('video_initialized', extra: 'index=$index');
    }).catchError((e, st) {
      debugPrint('[VCM] ❌ video error #$index -> $e');
      // مُكمل النافذة لا يُنتظر في الإنتاج — إكمال عادي يكفي ويمنع اختبارات الوحدة من السقوط.
      if (!completer.isCompleted) completer.complete();
      notifyListeners();
    });
  }

  /// تحميل مسبق للروابط الأمامية مع حد أقصى [_maxConcurrentPrefetches] متزامناً.
  void _warmForwardUrls({required int fromIndex}) {
    for (var d = 1; d <= _forwardPreload; d++) {
      final j = fromIndex + d;
      if (j >= 0 && j < _urls.length) {
        unawaited(_limitedPrefetch(_urls[j]));
      }
    }
  }

  Future<void> _limitedPrefetch(String url) async {
    if (url.isEmpty || _disposed) return;
    while (_prefetchInFlight >= _maxConcurrentPrefetches && !_disposed) {
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }
    if (_disposed) return;
    _prefetchInFlight++;
    try {
      await ReelsVideoPrecacheService.prefetchUrlOffMainThread(url);
    } finally {
      _prefetchInFlight--;
    }
  }

  /// يشغّل الـ controller الحالي، ويوقف البقية.
  /// إعادة الموضع للصفر فقط للريل الذي غادره المستخدم (تنقل حقيقي) — لا seek على كل إعادة بناء.
  void _applyPlaybackState() {
    final cur = _currentIndex;
    final prev = _lastPlaybackCurrentIndex;
    final navigated = prev != null && prev != cur;

    _controllers.forEach((i, c) {
      if (!c.value.isInitialized) return;
      if (i == cur) {
        try {
          c.setVolume(_isMuted ? 0 : 1);
        } catch (_) {}
        if (!c.value.isPlaying && !_globallyPaused) {
          c.play();
        }
      } else {
        try {
          c.setVolume(0);
        } catch (_) {}
        if (c.value.isPlaying) c.pause();
        if (navigated && i == prev && c.value.position > Duration.zero) {
          c.seekTo(Duration.zero);
        }
      }
    });

    _lastPlaybackCurrentIndex = cur;
  }

  void _disposeController(int index) {
    final c = _controllers.remove(index);
    _indexToUrl.remove(index);
    _initializers.remove(index);
    if (c != null) {
      try {
        c.pause();
      } catch (_) {}
      c.dispose();
    }
    _logMemorySnapshot('dispose_controller', extra: 'removed_index=$index');
  }

  @override
  void dispose() {
    _disposed = true;
    for (final c in _controllers.values) {
      try {
        c.pause();
      } catch (_) {}
      c.dispose();
    }
    _controllers.clear();
    _indexToUrl.clear();
    _initializers.clear();
    _logMemorySnapshot('dispose_manager');
    super.dispose();
  }
}
