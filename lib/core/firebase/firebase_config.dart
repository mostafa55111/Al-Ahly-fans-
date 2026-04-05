import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gomhor_alahly_clean_new/firebase_options.dart';

/// Firebase Configuration Class
class FirebaseConfig {
  static late FirebaseDatabase _database;
  static late FirebaseAuth _auth;
  static late FirebaseStorage _storage;

  /// تهيئة Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _database = FirebaseDatabase.instance;
      _database.setPersistenceEnabled(true);
      if (kDebugMode) {
        _database.setLoggingEnabled(true);
      }
      _auth = FirebaseAuth.instance;
      _storage = FirebaseStorage.instance;

      if (kDebugMode) {
        debugPrint('✅ Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firebase initialization error: $e');
      }
      rethrow;
    }
  }

  static FirebaseDatabase getDatabase() => _database;
  static FirebaseAuth getAuth() => _auth;
  static FirebaseStorage getStorage() => _storage;
  static String? getCurrentUserId() => _auth.currentUser?.uid;
  static bool isLoggedIn() => _auth.currentUser != null;
  static Future<void> logout() async => await _auth.signOut();
}
