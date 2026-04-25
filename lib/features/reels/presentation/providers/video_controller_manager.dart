import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

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
  /// كم فيديو نحتفظ به خلف الفيديو الحالي (لتسريع العودة)
  static const int _backwardKeep = 1;

  /// كم فيديو نفتحه أمام الفيديو الحالي (Preload)
  /// ═══════════════════════════════════════════════════════════════
  /// 2 = الفيديو التالي + اللي بعده → لما المستخدم يقلب ما يستناش تحميل،
  /// وكمان اللي بعد التالي بيكون جاهز فأي تقليب سريع ما يقف.
  static const int _forwardPreload = 2;

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
      if (c.value.isInitialized && c.value.isPlaying) c.pause();
    }
    notifyListeners();
  }

  /// استئناف الفيديو الحالي فقط + إلغاء flag الإيقاف العام.
  void resumeCurrent() {
    if (_disposed) return;
    _globallyPaused = false;
    final c = _controllers[_currentIndex];
    if (c != null && c.value.isInitialized && !c.value.isPlaying) {
      c.play();
      notifyListeners();
    }
  }

  // ========== internals ==========

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
      _initControllerFor(i);
    }
  }

  Future<void> _initControllerFor(int index) {
    final url = _urls[index];
    if (url.isEmpty) {
      debugPrint('[VCM] skip init: empty url at #$index');
      return Future.value();
    }

    debugPrint('[VCM] preload controller #$index -> $url');
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controllers[index] = controller;
    _indexToUrl[index] = url;
    final completer = Completer<void>();
    _initializers[index] = completer;

    controller.initialize().then((_) {
      if (_disposed) {
        controller.dispose();
        return;
      }
      // في حال تم إخراج هذا الـ index من النافذة أثناء التحميل
      if (!_controllers.containsKey(index) ||
          _controllers[index] != controller) {
        controller.dispose();
        return;
      }
      controller
        ..setLooping(true)
        ..setVolume(_isMuted ? 0 : 1);

      debugPrint('[VCM] ✅ video loaded #$index (${controller.value.size})');
      // لا نشغّل تلقائياً لو التبويب مش نشط (المستخدم فاتح شاشة تانية).
      if (index == _currentIndex && !_globallyPaused) {
        controller.play();
      }
      if (!completer.isCompleted) completer.complete();
      notifyListeners();
    }).catchError((e, st) {
      debugPrint('[VCM] ❌ video error #$index -> $e');
      if (!completer.isCompleted) completer.completeError(e, st);
      notifyListeners();
    });

    return completer.future;
  }

  /// يشغّل الـ controller الحالي، ويوقف/يعيد البقية للبداية.
  /// لا يُشغّل أي شيء لو كان [_globallyPaused] = true.
  void _applyPlaybackState() {
    _controllers.forEach((i, c) {
      if (!c.value.isInitialized) return;
      if (i == _currentIndex) {
        if (!c.value.isPlaying && !_globallyPaused) c.play();
      } else {
        if (c.value.isPlaying) c.pause();
        // نحافظ على البداية للفيديوهات المُحاطة بالنافذة لتجربة أسرع عند العودة
        if (c.value.position > Duration.zero) {
          c.seekTo(Duration.zero);
        }
      }
    });
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
    super.dispose();
  }
}
