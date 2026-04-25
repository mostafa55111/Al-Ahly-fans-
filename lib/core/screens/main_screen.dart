import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/reels_screen.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/pages/matches_screen.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/profile_screen.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/bloc/reels_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/bloc/matches_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ReelsBloc>()..add(const LoadReelsEvent()),
        ),
        BlocProvider(
          create: (_) => getIt<MatchesBloc>(),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: const [
            ReelsScreen(),
            MatchesScreen(),
            ProfileScreen(),
          ],
        ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.white.withValues(alpha: 0.6),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library_outlined),
              activeIcon: Icon(Icons.video_library),
              label: 'الريلز',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer_outlined),
              activeIcon: Icon(Icons.sports_soccer),
              label: 'المباريات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'الملف الشخصي',
            ),
          ],
        ),
      ),
      ),
    );
  }
}
