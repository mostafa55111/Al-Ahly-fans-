import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gomhor_alahly_clean_new/core/config/firebase_oauth_config.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/services/fan_app_registry_service.dart';
import 'package:gomhor_alahly_clean_new/core/services/user_initial_app_guard.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/entities/auth_user.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/exceptions/fan_app_registry_exception.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/repositories/auth_repository.dart';

/// تنفيذ Repository المصادقة باستخدام Firebase Auth + تسجيل موحّد في Firestore
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseDatabase? database,
    GoogleSignIn? googleSignIn,
    required FanAppRegistryService fanAppRegistry,
    UserInitialAppGuard? initialAppGuard,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _database = database ?? FirebaseDatabase.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const <String>['email', 'profile'],
              serverClientId: FirebaseOAuthConfig.firebaseAuthWebClientId,
            ),
        _registry = fanAppRegistry,
        _initialAppGuard = initialAppGuard ??
            UserInitialAppGuard(FirebaseFirestore.instance);

  final FirebaseAuth _firebaseAuth;
  final FirebaseDatabase _database;
  final GoogleSignIn _googleSignIn;
  final FanAppRegistryService _registry;
  final UserInitialAppGuard _initialAppGuard;

  FanAppRegistryService get _reg => _registry;

  AuthUser _mapFirebaseUser(User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
    );
  }

  Future<void> _performFullSignOut() async {
    await Future.wait<void>([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut().catchError((_) => null),
    ]);
  }

  Future<void> _assertEmailHomeMatchesOrSignOut(String? email) async {
    if (email == null || email.isEmpty) return;
    await _reg.assertSameHomeAppAfterSignInOrSignOut(
      email: email,
      performSignOut: _performFullSignOut,
    );
  }

  /// سجلّ البريد + قفل [initial_app] في Firestore للمستخدمين العاديين فقط.
  Future<void> _runPostAuthGuards(User user) async {
    if (FanAppIdentity.isCrossAppSuperAdmin(user.email)) return;
    await _assertEmailHomeMatchesOrSignOut(user.email);
    await _initialAppGuard.ensureMatchingOrSignOut(
      user: user,
      performSignOut: _performFullSignOut,
    );
  }

  @override
  Stream<AuthUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        try {
          await _runPostAuthGuards(user);
        } on FanAppRegistryException {
          return null;
        } catch (e, st) {
          debugPrint('AuthRepositoryImpl authStateChanges guard: $e\n$st');
        }
        return _mapFirebaseUser(user);
      });

  @override
  AuthUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user == null ? null : _mapFirebaseUser(user);
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final trimmed = email.trim();
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: trimmed,
        password: password.trim(),
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('فشل تسجيل الدخول: بيانات المستخدم غير متوفرة');
      }
      await _runPostAuthGuards(user);
      await _syncUserToDatabase(user);
      return _mapFirebaseUser(user);
    } on FanAppRegistryException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final trimmed = email.trim();
    try {
      if (trimmed.isNotEmpty && !FanAppIdentity.isCrossAppSuperAdmin(trimmed)) {
        final other = await _reg.getHomeApp(trimmed);
        if (other != null && other != FanAppIdentity.registryAppId) {
          throw FanAppRegistryException(
            FanAppIdentity.wrongAppMessageFor(other),
          );
        }
      }
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: trimmed,
        password: password.trim(),
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('فشل إنشاء الحساب');
      }
      await user.updateDisplayName(displayName);
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser ?? user;
      await _runPostAuthGuards(refreshedUser);
      await _syncUserToDatabase(refreshedUser, overrideName: displayName);
      if (trimmed.isNotEmpty && !FanAppIdentity.isCrossAppSuperAdmin(trimmed)) {
        await _reg.writeRegistryAfterSignUp(email: trimmed, uid: refreshedUser.uid);
      }
      return _mapFirebaseUser(refreshedUser);
    } on FanAppRegistryException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use' &&
          trimmed.isNotEmpty &&
          !FanAppIdentity.isCrossAppSuperAdmin(trimmed)) {
        final other = await _reg.getHomeApp(trimmed);
        if (other != null && other != FanAppIdentity.registryAppId) {
          throw FanAppRegistryException(
            FanAppIdentity.wrongAppMessageFor(other),
          );
        }
      }
      throw Exception(_mapAuthError(e));
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('تم إلغاء تسجيل الدخول');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        debugPrint(
          'Google Sign-In: idToken فارغ — راجع serverClientId (Web client type 3) في الكود وgoogle-services.json',
        );
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('فشل تسجيل الدخول بحساب Google');
      }
      await _runPostAuthGuards(user);
      if (user.email != null &&
          user.email!.isNotEmpty &&
          !FanAppIdentity.isCrossAppSuperAdmin(user.email)) {
        await _reg.writeRegistryAfterSignUp(
          email: user.email!,
          uid: user.uid,
        );
      }
      await _syncUserToDatabase(user);
      return _mapFirebaseUser(user);
    } on FanAppRegistryException {
      rethrow;
    } on FirebaseAuthException catch (e, st) {
      debugPrint(
        'Google Sign-In FirebaseAuthException code=${e.code} message=${e.message}\n$st',
      );
      throw Exception(_mapAuthError(e));
    } on PlatformException catch (e, st) {
      _logGooglePlatformException(e, st);
      throw Exception(_googleSignInPlatformMessage(e));
    } catch (e, st) {
      debugPrint('Google Sign-In Error: $e\n$st');
      throw Exception(
        'تعذر تسجيل الدخول بجوجل. تأكد من تفعيل Google Sign-In في Firebase وتطابق package/SHA مع Console.',
      );
    }
  }

  void _logGooglePlatformException(PlatformException e, StackTrace st) {
    debugPrint(
      'Google Sign-In PlatformException: code=${e.code} message=${e.message} '
      'details=${e.details} (10 / sign_in_failed غالباً إعدادات OAuth أو SHA)',
    );
    debugPrint('$st');
  }

  String _googleSignInPlatformMessage(PlatformException e) {
    final code = e.code;
    final details = e.details?.toString() ?? '';
    if (code == 'sign_in_failed' ||
        details.contains('10') ||
        details.contains('12500')) {
      return 'تعذر Google Sign-In — تحقق من: (1) Web Client ID في الكود '
          '(2) SHA-1/256 في Firebase لتطبيقك (3) إعادة تنزيل google-services.json. '
          'Raw: $code ${e.message ?? ''}';
    }
    if (code == 'sign_in_canceled' || code == '12501') {
      return 'تم إلغاء تسجيل الدخول';
    }
    return 'Google Sign-In: ${e.message ?? code}';
  }

  @override
  Future<String> sendPhoneVerificationCode({
    required String phoneNumber,
  }) async {
    final completer = Completer<String>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final uc = await _firebaseAuth.signInWithCredential(credential);
          debugPrint(
            'PhoneAuth verificationCompleted: دخول تلقائي uid=${uc.user?.uid}',
          );
        } on FirebaseAuthException catch (e, st) {
          debugPrint(
            'PhoneAuth verificationCompleted فشل: code=${e.code} '
            'message=${e.message}\n$st',
          );
        } catch (e, st) {
          debugPrint('PhoneAuth verificationCompleted خطأ: $e\n$st');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint(
          'PhoneAuth verificationFailed: code=${e.code} '
          'message=${e.message}',
        );
        if (!completer.isCompleted) {
          completer.completeError(Exception(_mapAuthError(e)));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  @override
  Future<AuthUser> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('فشل تأكيد رقم الهاتف');
      }
      await _runPostAuthGuards(user);
      await _syncUserToDatabase(user);
      return _mapFirebaseUser(user);
    } on FanAppRegistryException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _performFullSignOut();
  }

  Future<void> _syncUserToDatabase(User user, {String? overrideName}) async {
    try {
      final ref = _database.ref('users/${user.uid}');
      final snapshot = await ref.get();
      final existing = snapshot.value is Map
          ? Map<dynamic, dynamic>.from(snapshot.value as Map)
          : <dynamic, dynamic>{};

      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? existing['email'] ?? '',
        'phoneNumber': user.phoneNumber ?? existing['phoneNumber'] ?? '',
        'name': overrideName ??
            user.displayName ??
            existing['name'] ??
            'مشجع أهلاوي',
        'username': existing['username'] ??
            (user.email?.split('@').first ??
                'ahly_fan_${user.uid.length >= 5 ? user.uid.substring(0, 5) : user.uid}'),
        'profilePic': user.photoURL ?? existing['profilePic'] ?? '',
        'bio': existing['bio'] ?? '',
        'followers': existing['followers'] ?? 0,
        'following': existing['following'] ?? 0,
        'likes': existing['likes'] ?? 0,
        'createdAt': existing['createdAt'] ?? ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      };
      await ref.update(data);
    } catch (e) {
      debugPrint('AuthRepository: _syncUserToDatabase error -> $e');
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد مستخدم بالفعل — جرّب تسجيل الدخول';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، يجب أن تكون 6 أحرف على الأقل';
      case 'operation-not-allowed':
        return 'هذه الطريقة غير مفعّلة في Firebase Console';
      case 'too-many-requests':
        return 'تم إرسال محاولات كثيرة، حاول لاحقاً';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت';
      case 'invalid-verification-code':
        return 'كود التحقق غير صحيح';
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صحيح';
      case 'invalid-app-credential':
      case 'missing-client-identifier':
        return 'فشل توثيق التطبيق (هاتف) — راجع google-services وSHA وتفعيل Phone Auth';
      case 'captcha-check-failed':
        return 'فشل التحقق reCAPTCHA — حدّث Google Play services أو جرّب شبكة أخرى';
      default:
        return e.message ?? 'حدث خطأ غير متوقع: ${e.code}';
    }
  }
}
