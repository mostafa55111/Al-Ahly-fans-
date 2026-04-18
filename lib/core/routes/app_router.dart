import 'package:go_router/go_router.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/pages/login_screen.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/profile_screen.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/reels_screen.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const ReelsScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
