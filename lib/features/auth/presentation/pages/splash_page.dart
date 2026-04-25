import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/app_shell.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/pages/login_page.dart';

/// الشاشة الترحيبية - تستعرض شعار التطبيق ملء الشاشة
/// ثم تقرر الانتقال للتسجيل أو الشاشة الرئيسية حسب حالة المصادقة
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _minDelayDone = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _minDelayDone = true);
      _navigateIfReady();
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// عند اكتمال التأخير + معرفة حالة المصادقة → ينتقل للشاشة المناسبة
  void _navigateIfReady() {
    if (!mounted) return;
    final status = context.read<AuthCubit>().state.status;
    if (!_minDelayDone || status == AuthStatus.unknown) return;

    if (status == AuthStatus.authenticated) {
      _goTo(const AppShell());
    } else {
      _goTo(const LoginPage());
    }
  }

  void _goTo(Widget page) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) => _navigateIfReady(),
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // خلفية متدرجة بألوان النادي (أسود → أحمر → ذهبي)
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Color(0xFF1A0505),
                    AppColors.deepBlack,
                    Colors.black,
                  ],
                ),
              ),
            ),

            // الشعار بملء الشاشة مع أنيميشن
            Center(
              child: ZoomIn(
                duration: const Duration(milliseconds: 900),
                child: Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buildFallbackLogo(),
                  ),
                ),
              ),
            ),

            // عنوان + مؤشر تحميل في الأسفل
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeInUp(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 700),
                child:                 const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'جمهور الأهلي',
                      style: TextStyle(
                        color: AppColors.luminousGold,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'نادي القرن',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 4,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    SizedBox(height: 28),
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.royalRed),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// شعار احتياطي في حال عدم وجود ملف الصورة
  Widget _buildFallbackLogo() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.royalRed, AppColors.darkRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalRed.withValues(alpha: 0.45),
            blurRadius: 30,
            spreadRadius: 8,
          ),
        ],
        border: Border.all(color: AppColors.luminousGold, width: 4),
      ),
      child: const Icon(
        Icons.shield,
        color: AppColors.luminousGold,
        size: 90,
      ),
    );
  }
}
