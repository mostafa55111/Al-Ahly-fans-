import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/app_shell.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/pages/login_page.dart';

/// شاشة البداية: نفس لون وصورة [flutter_native_splash] فقط — لا واجهة ثانية فوقها.
/// تُزال الشاشة الأصلية عند الانتقال للتطبيق لتبدو كشاشة واحدة.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// لون موحّد مع Native Splash (#1A080C)
  static const Color _kSplash = Color(0xFF1A080C);
  static const Duration _kMinLogoDisplay = Duration(seconds: 3);

  bool _navigated = false;
  bool _navigationScheduled = false;
  late final DateTime _splashStartedAt;

  @override
  void initState() {
    super.initState();
    _splashStartedAt = DateTime.now();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _kSplash,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<AuthCubit>().checkInitialAuthState();
      if (mounted) _navigateIfReady();
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _navigateIfReady() {
    if (!mounted || _navigated || _navigationScheduled) return;
    final status = context.read<AuthCubit>().state.status;
    if (status == AuthStatus.unknown || status == AuthStatus.loading) {
      return;
    }
    final Widget next = status == AuthStatus.authenticated
        ? const AppShell(initialIndex: kReelsTabIndex)
        : const LoginPage();
    _scheduleNavigationAfterMinDisplay(next);
  }

  void _scheduleNavigationAfterMinDisplay(Widget page) {
    if (!mounted || _navigated || _navigationScheduled) return;
    _navigationScheduled = true;
    final elapsed = DateTime.now().difference(_splashStartedAt);
    final remaining = _kMinLogoDisplay - elapsed;
    Future<void>.delayed(
      remaining <= Duration.zero ? Duration.zero : remaining,
      () {
        if (!mounted) {
          _navigationScheduled = false;
          return;
        }
        _goTo(page);
      },
    );
  }

  void _goTo(Widget page) {
    if (_navigated || !mounted) return;
    _navigated = true;
    FlutterNativeSplash.remove();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) => _navigateIfReady(),
      child: const Scaffold(
        backgroundColor: _kSplash,
        body: ColoredBox(color: _kSplash),
      ),
    );
  }
}
