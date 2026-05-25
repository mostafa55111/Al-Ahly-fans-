import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/exceptions/fan_app_registry_exception.dart';

/// قفل التطبيق عبر حقل `initial_app` في مستند Firestore `users/{uid}`.
class UserInitialAppGuard {
  UserInitialAppGuard(this._firestore);

  final FirebaseFirestore _firestore;

  /// مطابق لطلب المنتج — اسم الحقل في Firestore.
  static const String firestoreField = 'initial_app';

  /// أول دخول يضبط [initial_app] = تطبيق البناء الحالي؛ تعارض لاحق ⇒ [performSignOut] ثم استثناء.
  Future<void> ensureMatchingOrSignOut({
    required User user,
    required Future<void> Function() performSignOut,
  }) async {
    if (FanAppIdentity.isCrossAppSuperAdmin(user.email)) return;

    final doc = _firestore.collection('users').doc(user.uid);
    final snap = await doc.get();
    final data = snap.data();
    final existing = data?[firestoreField]?.toString().trim();

    if (existing == null || existing.isEmpty) {
      await doc.set(
        {
          firestoreField: FanAppIdentity.registryAppId,
          'initial_app_set_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    if (existing != FanAppIdentity.registryAppId) {
      await performSignOut();
      throw FanAppRegistryException(
        FanAppIdentity.initialAppLockMessageForStoredApp(existing),
      );
    }
  }
}
