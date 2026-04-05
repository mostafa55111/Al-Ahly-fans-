import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gomhor_alahly_clean_new/core/screens/main_navigation_screen.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/pages/login_screen.dart'; // Corrected import

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
      
      await Future.delayed(const Duration(seconds: 2));
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      if (!mounted) return;

      debugPrint('🔄 Splash: Checking auth state...');
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        debugPrint('✅ Splash: User authenticated, navigating to MainNavigation');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        debugPrint('🔐 Splash: No user authenticated, navigating to Login');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Splash: Error in app logic: $e');
      debugPrint('❌ Splash: Stack trace: ${StackTrace.current}');
      
      // Navigate to login screen on error
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية ذهبية خفيفة
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/gold_pattern.png',
                repeat: ImageRepeat.repeat,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),

          // اللوجو كامل الشاشة
          Positioned.fill(
            child: ZoomIn(
              duration: const Duration(milliseconds: 1000),
              child: FadeIn(
                duration: const Duration(milliseconds: 1200),
                child: Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ Splash: Logo asset error: $error');
                        return const Icon(
                          Icons.sports_soccer,
                          size: 150,
                          color: Color(0xFFC5A059),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // مؤشر التحميل في الأسفل
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeInUp(
              delay: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 800),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Color(0xFFC5A059),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'نادي القرن الحقيقي',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFC5A059),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
