import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/reels_screen.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/pages/crowd_screen.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/profile_screen.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/bloc/reels_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          BlocProvider(
            create: (_) => getIt<ReelsBloc>(),
            lazy: false, // Load immediately for better UX
            child: const ReelsScreen(),
          ),
          const CrowdScreen(),
          const ProfileScreen(),
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
          unselectedItemColor: Colors.white.withAlpha(60),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library_outlined),
              activeIcon: Icon(Icons.video_library),
              label: 'الريلز',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt),
              label: 'الجمهور',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'الملف الشخصي',
            ),
          ],
        ),
      ),
    );
  }
}
