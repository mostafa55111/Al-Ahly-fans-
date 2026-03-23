import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/core/firebase/firebase_config.dart';
import 'package:gomhor_alahly_clean_new/core/firebase/firebase_service.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/splash_screen.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/login_screen.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/profile_screen.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/reels_screen.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/presentation/pages/match_center_screen.dart';
import 'firebase_options.dart';

// Gemini API Configuration
const String geminiApiKey = 'AIzaSyCNlqhPN6dkOTjF8DfV9IE4wyEzWjrCgjQ';

// Football API Configuration
const String footballApiKey = '8c16585903c335eb82435488feac3937';

// Cloudinary API Configuration
const String cloudinaryApiKey = '497232166977864';
const String cloudinaryCloudName = 'dubc6k1iy';

/// Initialize Gemini API Key
void initializeGeminiAPI() {
  debugPrint('Gemini API initialized successfully');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    await FirebaseConfig.initialize();
    FirebaseService().initialize();
    initializeGeminiAPI();
  } catch (e) {
    debugPrint('❌ Initialization error: $e');
  }
  
  runApp(const AlAhlySuperApp());
}

class AlAhlySuperApp extends StatelessWidget {
  const AlAhlySuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'جمهور الأهلي - نادي القرن',
      theme: AppTheme.darkTheme(),
      home: const SplashScreen(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Stream<User?> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MainHomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ReelsScreen(),
    const MatchCenterScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: const Color(0xFF111318),
            selectedItemColor: const Color(0xFFE1306C),
            unselectedItemColor: const Color(0xFF8E8E93),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.smart_display_outlined),
                activeIcon: Icon(Icons.smart_display_rounded),
                label: 'الريلز',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sports_soccer_outlined),
                activeIcon: Icon(Icons.sports_soccer),
                label: 'المباريات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
