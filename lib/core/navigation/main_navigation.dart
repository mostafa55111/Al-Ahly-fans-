import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/animations/advanced_animations.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/reels_screen.dart';
import 'package:gomhor_alahly_clean_new/features/marketplace/presentation/pages/marketplace_screen.dart';
import 'package:gomhor_alahly_clean_new/features/bus_booking/presentation/pages/bus_booking_screen.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/presentation/pages/match_center_screen.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 4; // يبدأ على البروفايل كما طلب المستخدم

  final List<Widget> _screens = [
    const ReelsScreen(),
    const MatchCenterScreen(), // شاشة التصويت والجمهور
    const MarketplaceScreen(),
    const BusBookingScreen(), // شاشة الترحال
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // زخرفة ذهبية خفيفة في الخلفية
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/gold_pattern.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          _screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Colors.amber.withAlpha((0.3 * 255).toInt()),
                  width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: Colors.red, // إضاءة حمراء للزر النشط
          unselectedItemColor: Colors.amber
              .withAlpha((0.6 * 255).toInt()), // ذهبي مطفي لغير النشط
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            _buildNavItem(Icons.video_library_rounded, 'الريلز', 0),
            _buildNavItem(Icons.how_to_vote_rounded, 'التصويت', 1),
            _buildNavItem(Icons.shopping_cart_rounded, 'المتجر', 2),
            _buildNavItem(Icons.directions_bus_rounded, 'الترحال', 3),
            _buildNavItem(Icons.person_rounded, 'البروفايل', 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: RedGlowEffect(
        isActive: isSelected,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: isSelected
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withAlpha((0.5 * 255).toInt()),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                )
              : null,
          child: Icon(icon),
        ),
      ),
      label: label,
    );
  }
}
