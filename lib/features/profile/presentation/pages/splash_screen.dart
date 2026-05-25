import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gomhor_alahly_clean_new/core/screens/main_navigation_screen.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/pages/login_screen.dart';

/// نسخة احتياطية لمسار قديم: نفس مظهر [SplashPage] — شعار النادي فقط + FAN Technology.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _startAppLogic();
  }

  Future<void> _startAppLogic() async {
    try {
      debugPrint('🔄 Splash: Starting app logic...');

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF2B090D),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      await Future<void>.delayed(Duration.zero);

      if (!mounted) return;

      debugPrint('🔄 Splash: Checking auth state...');
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        debugPrint('✅ Splash: User authenticated, navigating to MainNavigation');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (_) => false,
        );
      } else {
        debugPrint('🔐 Splash: No user authenticated, navigating to Login');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Splash: Error in app logic: $e');
      debugPrint('❌ Splash: Stack trace: ${StackTrace.current}');
      
      // Navigate to login screen on error
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  static const Color _kTop = Color(0xFF5C1018);
  static const Color _kMid = Color(0xFF3D0E14);
  static const Color _kBottom = Color(0xFF2B090D);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: _kTop,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _kTop,
              _kMid,
              _kBottom,
              Color(0xFF000000),
            ],
            stops: [0.0, 0.38, 0.72, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const horizontalPad = 12.0;
                    final maxW = math.max(
                      0.0,
                      constraints.maxWidth - horizontalPad * 2,
                    );
                    final maxH = constraints.maxHeight * 0.96;
                    return Center(
                      child: ZoomIn(
                        duration: const Duration(milliseconds: 1000),
                        child: FadeIn(
                          duration: const Duration(milliseconds: 1200),
                          child: Hero(
                            tag: 'app_club_logo',
                            child: Image.asset(
                              'assets/images/ahly_logo.png',
                              width: maxW,
                              height: maxH,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.sports_soccer,
                                size: math.min(maxW, maxH) * 0.35,
                                color: AppColors.luminousGold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 800),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    12 + mq.padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/fan_technology_logo.png',
                        height: 64,
                        width: mq.size.width * 0.88,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.luminousGold.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
