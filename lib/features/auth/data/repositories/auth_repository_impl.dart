import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/entities/auth_user.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/repositories/auth_repository.dart';

/// تنفيذ Repository المصادقة باستخدام Firebase Auth
/// يحوّل User من Firebase إلى AuthUser في طبقة Domain
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseDatabase _database;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseDatabase? database,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _database = database ?? FirebaseDatabase.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// تحويل User من Firebase إلى AuthUser
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

  @override
  Stream<AuthUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(
            (user) => user == null ? null : _mapFirebaseUser(user),
          );

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
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('فشل تسجيل الدخول: بيانات المستخدم غير متوفرة');
      }
      await _syncUserToDatabase(user);
      return _mapFirebaseUser(user);
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
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('فشل إنشاء الحساب');
      }
      await user.updateDisplayName(displayName);
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser ?? user;
      await _syncUserToDatabase(refreshedUser, overrideName: displayName);
      return _mapFirebaseUser(refreshedUser);
    } on FirebaseAuthException catch (e) {
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
      await _syncUserToDatabase(user);
      return _mapFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      throw Exception(
        'تعذر تسجيل الدخول بجوجل. تأكد من تفعيل Google Sign-In في Firebase وإضافة SHA-1/SHA-256 للتطبيق.',
      );
    }
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
        // في بعض أجهزة أندرويد يتم التحقق التلقائي
        try {
          await _firebaseAuth.signInWithCredential(credential);
        } catch (_) {}
      },
      verificationFailed: (FirebaseAuthException e) {
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
      await _syncUserToDatabase(user);
      return _mapFirebaseUser(user);
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
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut().catchError((_) => null),
    ]);
  }

  /// حفظ بيانات المستخدم في Realtime Database
  Future<void> _syncUserToDatabase(User user, {String? overrideName}) async {
    try {
      final ref = _database.ref('users/${user.uid}');
      final snapshot = await ref.get();
      final existing =
          snapshot.value is Map ? Map<dynamic, dynamic>.from(snapshot.value as Map) : <dynamic, dynamic>{};

      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? existing['email'] ?? '',
        'phoneNumber': user.phoneNumber ?? existing['phoneNumber'] ?? '',
        'name': overrideName ??
            user.displayName ??
            existing['name'] ??
            'مشجع أهلاوي',
        'username': existing['username'] ??
            (user.email?.split('@').first ?? 'ahly_fan_${user.uid.substring(0, 5)}'),
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

  /// ترجمة أخطاء Firebase إلى رسائل واضحة بالعربية
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
        return 'هذا البريد مستخدم بالفعل';
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
      default:
        return e.message ?? 'حدث خطأ غير متوقع: ${e.code}';
    }
  }
}
