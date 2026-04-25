import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gomhor_alahly_clean_new/core/design_system/theme/app_colors.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/active_celebration_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/celebration_seen_store.dart';
import 'package:lottie/lottie.dart';

// ════════════════════════════════════════════════════════════════════════════
// مسارات الأصول — متزامنة مع قسم `flutter: assets:` في pubspec.yaml
// ════════════════════════════════════════════════════════════════════════════
class _CelebrationAssets {
  /// أنيميشن النسر بصيغة dotLottie (مدعومة في حزمة `lottie ^3.x`).
  static const String lottieEagle = 'assets/animations/eagle_animation.lottie';

  /// نسخة JSON احتياطية في حال فشل تحميل ملف dotLottie.
  static const String lottieEagleFallback = 'assets/animations/nesr_eagle.json';

  /// صوت احتفال النسر — `audioplayers` يستخدم مساراً بدون البادئة `assets/`.
  static const String cheerMp3 = 'sounds/nesr_cheer.mp3';
}

// ════════════════════════════════════════════════════════════════════════════
// NesrCelebrationOverlay — الغلاف الجذري الذي يراقب RTDB ويعرض الاحتفال
// ════════════════════════════════════════════════════════════════════════════

/// يُعرض لأول مرة لكل مستخدم ما لم ينتهِ وقت `showUntilServerMs`.
class NesrCelebrationOverlay extends StatefulWidget {
  const NesrCelebrationOverlay({
    super.key,
    required this.child,
    required this.serverTime,
    required this.repository,
    required this.seenStore,
  });

  final Widget child;
  final EgyptServerTimeService serverTime;
  final CrowdRepository repository;
  final CelebrationSeenStore seenStore;

  @override
  State<NesrCelebrationOverlay> createState() => _NesrCelebrationOverlayState();
}

class _NesrCelebrationOverlayState extends State<NesrCelebrationOverlay>
    with WidgetsBindingObserver {
  ActiveCelebrationDto? _pending;
  ActiveCelebrationDto? _lastFromStream;

  /// يمنع تكرار الصوت لنفس جلسة الاحتفال (يُصفَّر عند كل `uniqueKey` جديد).
  bool _cheerPlayedForThisOverlay = false;

  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 7),
  );

  /// مشغّل صوت `nesr_cheer.mp3` — يُهيَّأ مرة واحدة ويُحرَّر في [dispose].
  final AudioPlayer _audioCheer = AudioPlayer();
  StreamSubscription<ActiveCelebrationDto?>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = widget.repository.watchActiveCelebration().listen((data) async {
      _lastFromStream = data;
      await _evaluateCelebration(data);
    });
  }

  @override
  void dispose() {
    // إغلاق صحيح لكل الموارد عند تدمير الواجهة (انتهاء الاحتفال أو الخروج)
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _confetti.stop();
    _confetti.dispose();
    // إيقاف ثم تحرير موارد الصوت قبل التدمير
    unawaited(_releaseAudio());
    super.dispose();
  }

  /// تحرير مشغّل الصوت عند إزالة الغلاف من الشجرة (لا يُستدعى مرتين).
  Future<void> _releaseAudio() async {
    try {
      await _audioCheer.dispose();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppResumed());
    }
  }

  Future<void> _onAppResumed() async {
    await widget.serverTime.refreshOffset();
    await _evaluateCelebration(_lastFromStream);
  }

  Future<void> _evaluateCelebration(ActiveCelebrationDto? data) async {
    if (!mounted) return;
    if (data == null || data.playerId.isEmpty || data.uniqueKey.isEmpty) {
      if (mounted) setState(() => _pending = null);
      return;
    }
    await widget.serverTime.refreshOffset();
    if (widget.serverTime.serverNowMs > data.showUntilServerMs) {
      if (mounted) setState(() => _pending = null);
      return;
    }
    final kind = _kindKey(data.kind);
    if (widget.seenStore.hasSeen(kind, data.uniqueKey)) {
      if (mounted) setState(() => _pending = null);
      return;
    }
    if (mounted) {
      setState(() {
        _pending = data;
        _cheerPlayedForThisOverlay = false;
      });
    }
    _confetti.play();
    // الصوت يُشغَّل من [onEagleReady] عند تحميل [Lottie.asset] أو عند الاعتماد على الأيقونة الاحتياطية
  }

  /// يُستدعى مرة واحدة عند جاهزية أنيميشن النسر (أو البديل البصري).
  void _onEagleReady() {
    if (!mounted || _pending == null || _cheerPlayedForThisOverlay) return;
    _cheerPlayedForThisOverlay = true;
    unawaited(_playCheerSound());
  }

  /// تشغيل صوت `assets/sounds/nesr_cheer.mp3` بمجرد ظهور النسر.
  /// يُتجاهل الفشل بصمت (مثلاً عند غياب الملف أو على بعض المنصات).
  Future<void> _playCheerSound() async {
    try {
      await _audioCheer.stop();
      await _audioCheer.setReleaseMode(ReleaseMode.stop);
      await _audioCheer.play(
        AssetSource(_CelebrationAssets.cheerMp3),
        volume: 0.9,
      );
    } catch (_) {
      // يفشل بصمت — الاحتفال البصري يستمر بدون صوت
    }
  }

  String _kindKey(CelebrationKind k) => switch (k) {
        CelebrationKind.month => 'month',
        CelebrationKind.season => 'season',
        CelebrationKind.match => 'match',
      };

  Future<void> _dismiss(ActiveCelebrationDto d) async {
    // تخزين أن المستخدم رأى الاحتفال (لا يُعرض مرة أخرى لنفس uniqueKey)
    await widget.seenStore.markSeen(_kindKey(d.kind), d.uniqueKey);
    // إيقاف الصوت والـ Confetti فوراً لمنع تسرب الموارد
    _confetti.stop();
    try {
      await _audioCheer.stop();
    } catch (_) {}
    if (mounted) setState(() => _pending = null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_pending != null)
          _CelebrationScaffold(
            data: _pending!,
            confetti: _confetti,
            onEagleReady: _onEagleReady,
            onClose: () => _dismiss(_pending!),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _CelebrationScaffold — الشاشة الاحتفالية الكاملة
// ════════════════════════════════════════════════════════════════════════════

class _CelebrationScaffold extends StatelessWidget {
  const _CelebrationScaffold({
    required this.data,
    required this.confetti,
    required this.onEagleReady,
    required this.onClose,
  });

  final ActiveCelebrationDto data;
  final ConfettiController confetti;
  final VoidCallback onEagleReady;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.95),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── خلفية متدرجة أهلاوية ──────────────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF3A0808),
                  Color(0xFF100000),
                  Colors.black,
                ],
              ),
            ),
          ),

          // ── ألعاب نارية برمجية (Custom Painter — بدون Lottie) ──
          const Positioned.fill(child: _FireworksCanvas()),

          // ── confetti من الأعلى ────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.12,
              numberOfParticles: 28,
              minBlastForce: 6,
              maxBlastForce: 15,
              colors: const [
                Color(0xFFD4AF37),
                Color(0xFFFFD54F),
                Color(0xFFE53935),
                Color(0xFFFFFFFF),
              ],
            ),
          ),

          // ── المحتوى المركزي ───────────────────────────────────
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // أنيميشن النسر — `eagle_animation.lottie` (zip/dotLottie) ثم JSON احتياطي
                      SizedBox(
                        height: 180,
                        child: _EagleLottie(onReady: onEagleReady),
                      ),

                      const SizedBox(height: 10),

                      // عنوان الاحتفال
                      Text(
                        _titleForKind(data.kind),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          shadows: [
                            Shadow(
                              color: AppColors.secondary.withValues(alpha: 0.65),
                              blurRadius: 22,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 420.ms)
                          .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),

                      const SizedBox(height: 14),

                      // صورة اللاعب
                      if (data.photoUrl != null && data.photoUrl!.isNotEmpty)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 28,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: data.photoUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                      const SizedBox(height: 12),

                      // اسم اللاعب
                      Text(
                        data.playerName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                      const SizedBox(height: 8),

                      // نصّ توضيحي صغير
                      Text(
                        _subtitleForKind(data.kind),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.52),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // زر الإغلاق
                      FilledButton(
                        onPressed: onClose,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: const Text('يلا الأهلي'),
                      ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleForKind(CelebrationKind k) => switch (k) {
        CelebrationKind.match => 'نسر المباراة',
        CelebrationKind.month => 'نسر الشهر',
        CelebrationKind.season => 'نسر الموسم',
      };

  String _subtitleForKind(CelebrationKind k) => switch (k) {
        CelebrationKind.match =>
          'يظهر لأول مرة لكل مستخدم خلال مدة العرض (يومان من وقت الخادم).',
        CelebrationKind.month =>
          'مجموع الأصوات التراكمي هو المعيار، لا عدد مرات الفوز بالمباراة.',
        CelebrationKind.season =>
          'حتى بداية الموسم الجديد كما يضبطه الأدمن في قاعدة البيانات.',
      };
}

/// أنيميشن النسر: يحمّل [Lottie.asset] من `eagle_animation.lottie`.
/// حزمة `lottie` 3.x تفكّك ملفات zip (صيغة dotLottie) عبر [LottieComposition.decodeZip].
/// عند الفشل: `nesr_eagle.json` ثم أيقونة ذهبية متحركة.
/// [onReady] يُستدعى مرة واحدة عند جاهزية الرسمة ليشغّل الأب صوت `nesr_cheer.mp3`.
class _EagleLottie extends StatefulWidget {
  const _EagleLottie({required this.onReady});

  final VoidCallback onReady;

  @override
  State<_EagleLottie> createState() => _EagleLottieState();
}

class _EagleLottieState extends State<_EagleLottie> {
  /// 0 = dotLottie، 1 = JSON احتياطي، 2 = أيقونة فقط
  int _stage = 0;

  /// يضمن استدعاء [onReady] مرة واحدة فقط (صوت + منطق الوالد).
  bool _readyNotified = false;

  void _notifyReadyOnce() {
    if (_readyNotified) return;
    _readyNotified = true;
    widget.onReady();
  }

  @override
  Widget build(BuildContext context) {
    if (_stage >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyReadyOnce();
      });
      return _eagleIconFallback();
    }

    final path = _stage == 0
        ? _CelebrationAssets.lottieEagle
        : _CelebrationAssets.lottieEagleFallback;

    return Lottie.asset(
      path,
      fit: BoxFit.contain,
      repeat: true,
      // ملفات .lottie أرشيف zip — نفس المفسّر الافتراضي، صريح للوضوح
      decoder: LottieComposition.decodeZip,
      onLoaded: (_) => _notifyReadyOnce(),
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            if (_stage == 0) {
              _stage = 1;
            } else if (_stage == 1) {
              _stage = 2;
            }
          });
        });
        return _eagleIconFallback();
      },
    );
  }

  /// بديل بصري خفيف عند تعذّر تحميل Lottie
  Widget _eagleIconFallback() {
    return Center(
      child: const Icon(
        Icons.military_tech_rounded,
        size: 110,
        color: AppColors.secondary,
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: 0,
            end: -20,
            duration: 1300.ms,
            curve: Curves.easeInOut,
          )
          .shimmer(
            duration: 1700.ms,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// نظام ألعاب نارية برمجي — CustomPainter + Ticker
// بدون أي ملف خارجي، خفيف وسلس 60fps.
// ════════════════════════════════════════════════════════════════════════════

/// جُسيم واحد من الانفجار.
class _Particle {
  double x, y;
  double vx, vy;
  final Color color;
  double life; // 1.0 → 0.0
  final double size;
  final bool isSpark;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    this.isSpark = false,
  }) : life = 1.0;

  /// تحديث الوضع لكل إطار (dt بالثواني).
  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    // جاذبية + مقاومة هواء
    vy += 160 * dt;
    vx *= 1 - 1.2 * dt;
    // تلاشي الشرارات أسرع من الجُسيمات العادية
    life -= dt * (isSpark ? 2.2 : 1.0);
  }

  bool get isDead => life <= 0;
}

/// انفجار واحد يحتوي على قائمة جُسيمات.
class _FireworkShell {
  final List<_Particle> particles;
  _FireworkShell(this.particles);

  void update(double dt) {
    for (final p in particles) {
      p.update(dt);
    }
    particles.removeWhere((p) => p.isDead);
  }

  bool get isDead => particles.isEmpty;
}

/// رسّام الجُسيمات — يُرسم فوق الخلفية وتحت المحتوى.
class _FireworksPainter extends CustomPainter {
  final List<_FireworkShell> shells;

  _FireworksPainter(this.shells);

  static final Paint _paint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    for (final shell in shells) {
      for (final p in shell.particles) {
        final alpha = (p.life.clamp(0.0, 1.0) * 255).round();
        // تأثير توهج بسيط عبر ضربة ضبابية خلف كل جسيم
        _paint
          ..color = p.color.withAlpha((alpha * 0.35).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.size * p.life.clamp(0.3, 1.0) * 1.8,
          _paint,
        );
        // النواة اللامعة
        _paint
          ..color = p.color.withAlpha(alpha)
          ..maskFilter = null;
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.size * p.life.clamp(0.3, 1.0),
          _paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) => true;
}

/// الويدجت الذي يدير الـ Ticker وينتج الانفجارات دورياً.
class _FireworksCanvas extends StatefulWidget {
  const _FireworksCanvas();

  @override
  State<_FireworksCanvas> createState() => _FireworksCanvasState();
}

class _FireworksCanvasState extends State<_FireworksCanvas>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final List<_FireworkShell> _shells = [];
  final Random _rng = Random();
  double _nextBurstIn = 0.25; // ثواني حتى الانفجار التالي
  Size _canvasSize = Size.zero;

  /// لوحة ألوان النسر والأهلي: أحمر + ذهبي + أبيض
  static const List<Color> _palette = [
    Color(0xFFD4AF37), // ذهبي أساسي
    Color(0xFFFFD54F), // ذهبي فاتح
    Color(0xFFE8C547), // ذهبي متوسط
    Color(0xFFE53935), // أحمر ملكي
    Color(0xFFFF5252), // أحمر فاتح
    Color(0xFFC62828), // أحمر غامق
    Color(0xFFFFFFFF), // أبيض (شرارات)
    Color(0xFFFFE082), // عنبري
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    // تجاهل إطارات طويلة جداً (مثلاً عند الـ resume من الخلفية)
    if (dt <= 0 || dt > 0.12) return;

    for (final s in _shells) {
      s.update(dt);
    }
    _shells.removeWhere((s) => s.isDead);

    _nextBurstIn -= dt;
    if (_nextBurstIn <= 0 && _canvasSize != Size.zero) {
      _spawnShell();
      // فترة عشوائية 0.35 – 0.75 ثانية بين الانفجارات
      _nextBurstIn = 0.35 + _rng.nextDouble() * 0.4;
    }

    setState(() {});
  }

  /// توليد انفجار في موضع عشوائي في النصف + الربع العلوي من الشاشة.
  void _spawnShell() {
    final cx = _canvasSize.width * (0.12 + _rng.nextDouble() * 0.76);
    final cy = _canvasSize.height * (0.05 + _rng.nextDouble() * 0.48);

    final baseColor = _palette[_rng.nextInt(_palette.length)];
    // لون ثانوي للتشكيل الثنائي (أحمر + ذهبي في نفس الانفجار أحياناً)
    final mixRed = _rng.nextBool();
    final altColor = mixRed ? const Color(0xFFE53935) : const Color(0xFFD4AF37);

    final particles = <_Particle>[];

    // ── جُسيمات الانفجار الرئيسي ──
    final count = 24 + _rng.nextInt(18);
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * pi * 2 + (_rng.nextDouble() - 0.5) * 0.5;
      final speed = 55.0 + _rng.nextDouble() * 90;
      final pickAlt = _rng.nextDouble() < 0.35;
      particles.add(_Particle(
        x: cx,
        y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: pickAlt ? altColor : baseColor,
        size: 2.8 + _rng.nextDouble() * 2.8,
      ));
    }

    // ── شرارات أسرع وأصغر ──
    final sparkCount = 10 + _rng.nextInt(10);
    for (var i = 0; i < sparkCount; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 40.0 + _rng.nextDouble() * 110;
      particles.add(_Particle(
        x: cx,
        y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: Colors.white.withAlpha(230),
        size: 1.2 + _rng.nextDouble() * 1.6,
        isSpark: true,
      ));
    }

    _shells.add(_FireworkShell(particles));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        return CustomPaint(
          size: _canvasSize,
          painter: _FireworksPainter(List.unmodifiable(_shells)),
        );
      },
    );
  }
}
