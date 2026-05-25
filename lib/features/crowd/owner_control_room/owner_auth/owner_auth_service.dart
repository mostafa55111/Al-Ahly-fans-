import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/secure_owner_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_secure_session.dart';

enum OwnerSignInResult { success, invalidCredentials, notOwner, networkError }

/// تسجيل دخول المالك عبر Firebase Auth + جلسة آمنة.
class OwnerAuthService {
  OwnerAuthService({
    required FirebaseAuth auth,
    required SecureOwnerResolver resolver,
    required OwnerSecureSession secureSession,
  })  : _auth = auth,
        _resolver = resolver,
        _secureSession = secureSession;

  final FirebaseAuth _auth;
  final SecureOwnerResolver _resolver;
  final OwnerSecureSession _secureSession;

  Future<OwnerSignInResult> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
  if (normalized.isEmpty || password.isEmpty) {
      return OwnerSignInResult.invalidCredentials;
    }
    try {
      await _auth.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final user = _auth.currentUser;
      if (!await _resolver.isOwner(user)) {
        await _signOutInternal();
        return OwnerSignInResult.notOwner;
      }
      await _secureSession.open(
        uid: user!.uid,
        email: normalized,
      );
      await _refreshGuard();
      return OwnerSignInResult.success;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        return OwnerSignInResult.invalidCredentials;
      }
      return OwnerSignInResult.networkError;
    } catch (_) {
      return OwnerSignInResult.networkError;
    }
  }

  Future<void> signOut() async {
    await _signOutInternal();
    await _refreshGuard();
  }

  Future<void> _signOutInternal() async {
    await _secureSession.clear();
    await _auth.signOut();
  }

  /// إعادة التحقق عند استئناف التطبيق — يُنهي الجلسة عند انتهاء الصلاحية.
  Future<bool> revalidateOnResume() async {
    final user = _auth.currentUser;
    if (user == null) {
      await _secureSession.clear();
      await _refreshGuard();
      return false;
    }
    if (!await _resolver.isOwner(user)) {
      await _signOutInternal();
      await _refreshGuard();
      return false;
    }
    if (!await _secureSession.isActiveForUid(user.uid)) {
      await _signOutInternal();
      await _refreshGuard();
      return false;
    }
    await _secureSession.touch();
    await _refreshGuard();
    return true;
  }

  Future<bool> hasPrivilegedSession() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (!await _resolver.isOwner(user)) return false;
    return _secureSession.isActiveForUid(user.uid);
  }

  Future<void> _refreshGuard() async {
    if (getIt.isRegistered<OwnerSessionGuard>()) {
      await getIt<OwnerSessionGuard>().assertOwnerAccess();
    }
  }
}
