import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gomhor_alahly_clean_new/core/config/firebase_oauth_config.dart';

/// Service for handling Google Sign-In authentication
class GoogleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const <String>['email', 'profile'],
    serverClientId: FirebaseOAuthConfig.firebaseAuthWebClientId,
  );

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        throw AuthException('User cancelled Google Sign-In');
      }

      // Obtain the auth details from the Google Sign-In
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null && kDebugMode) {
        debugPrint(
          'GoogleSignInService: idToken null — تحقق من Web Client ID (Firebase)',
        );
      }
      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      return AuthResult(
        user: userCredential.user!,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
      );
    } on FirebaseAuthException catch (e, st) {
      debugPrint('GoogleSignInService FirebaseAuthException: $e\n$st');
      throw AuthException('Google Sign-In Firebase: ${e.code} ${e.message}');
    } on PlatformException catch (e, st) {
      debugPrint(
        'GoogleSignInService PlatformException code=${e.code} '
        'message=${e.message} details=${e.details}\n$st',
      );
      throw AuthException(
        'Google Sign-In فشل (${e.code}): ${e.message ?? ''} — '
        'إن كان 10 أو sign_in_failed راجع SHA وpackage في Firebase',
      );
    } catch (e, st) {
      debugPrint('GoogleSignInService: $e\n$st');
      throw AuthException('Google Sign-In failed: ${e.toString()}');
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();
      
      // Sign out from Google
      await _googleSignIn.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  /// Check if user is currently signed in
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user profile information
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return UserProfile(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }
}

/// Authentication result model
class AuthResult {
  final User user;
  final bool isNewUser;

  AuthResult({
    required this.user,
    required this.isNewUser,
  });
}

/// User profile model
class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.emailVerified,
  });
}

/// Authentication exception
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => message;
}
