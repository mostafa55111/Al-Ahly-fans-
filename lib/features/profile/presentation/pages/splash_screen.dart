import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gomhor_alahly_clean_new/main.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/login_screen.dart';

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
    await Future.delayed(const Duration(seconds: 4));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (!mounted) return;

    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainHomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.sports_soccer, 
                        size: 150, 
                        color: Color(0xFFC5A059),
                      ),
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
