import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/firebase_options.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/splash_screen.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/test_reels_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('DEBUG: 🚀 Starting app initialization...');
    
    // Initialize Firebase with timeout
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('DEBUG: ⏰ Firebase initialization timeout - continuing without Firebase');
        throw TimeoutException('Firebase initialization timeout', const Duration(seconds: 10));
      },
    );
    
    print("DEBUG: Firebase Initialized successfully");
    print("DEBUG: Firebase App Name: ${Firebase.app().name}");
    print("DEBUG: Firebase Database URL: ${Firebase.app().options.databaseURL}");
    
    // Setup dependency injection with timeout
    await setupServiceLocator().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('DEBUG: ⏰ Service Locator setup timeout - continuing without DI');
        throw TimeoutException('Service Locator setup timeout', const Duration(seconds: 5));
      },
    );
    
    print('DEBUG: � Service Locator initialized successfully!');
    print('DEBUG: 🚀 App initialization complete!');
    print('DEBUG: 🔥 Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    print('DEBUG: 🔥 Realtime Database URL: ${FirebaseDatabase.instance.databaseURL}');

    runApp(
      const MyApp(),
    );
  } catch (e) {
    print('DEBUG: ❌ App initialization error: $e');
    print('DEBUG: ❌ Stack trace: ${StackTrace.current}');
    
    // Run app without Firebase if initialization fails
    runApp(
      const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlAhlySuperApp();
  }
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
