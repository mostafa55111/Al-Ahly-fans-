import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/exceptions/fan_app_registry_exception.dart';

/// سجلّ بريد موحّد في Firestore لربط كل إيميل بتطبيق «المنزل» (أهلي / زملك).
///
/// قواعد أمان مقترحة (انشرها في Firebase Console → Firestore Rules):
/// ```
/// match /fan_app_registry/{id} {
///   allow read: if true;
///   allow create: if request.auth != null
///     && request.resource.data.primaryUid == request.auth.uid;
///   allow update: if request.auth != null
///     && request.auth.uid == resource.data.primaryUid
///     && request.resource.data.homeApp == resource.data.homeApp;
/// }
/// ```
class FanAppRegistryService {
  FanAppRegistryService(this._firestore);

  static const String collectionName = 'fan_app_registry';

  final FirebaseFirestore _firestore;

  static String docIdForEmail(String email) {
    final n = FanAppIdentity.normalizeEmail(email);
    final digest = sha256.convert(utf8.encode(n));
    return digest.toString();
  }

  Future<String?> getHomeApp(String email) async {
    final key = FanAppIdentity.normalizeEmail(email);
    if (key.isEmpty) return null;
    try {
      final snap = await _firestore
          .collection(collectionName)
          .doc(docIdForEmail(key))
          .get();
      if (!snap.exists) return null;
      final v = snap.data()?['homeApp'];
      if (v is String && v.isNotEmpty) return v;
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FanAppRegistryService.getHomeApp: $e');
      }
      rethrow;
    }
  }

  Future<void> writeRegistryAfterSignUp({
    required String email,
    required String uid,
  }) async {
    if (FanAppIdentity.isCrossAppSuperAdmin(email)) return;
    final ref = _firestore
        .collection(collectionName)
        .doc(docIdForEmail(email));
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        final h = snap.data()?['homeApp'] as String?;
        if (h != null && h != FanAppIdentity.registryAppId) {
          throw FanAppRegistryException(FanAppIdentity.wrongAppMessageFor(h));
        }
        tx.set(
          ref,
          {
            'primaryUid': uid,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return;
      }
      tx.set(ref, {
        'homeApp': FanAppIdentity.registryAppId,
        'email': FanAppIdentity.normalizeEmail(email),
        'primaryUid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> assertSameHomeAppAfterSignInOrSignOut({
    required String email,
    required Future<void> Function() performSignOut,
  }) async {
    final normalized = FanAppIdentity.normalizeEmail(email);
    if (normalized.isEmpty) return;
    if (FanAppIdentity.isCrossAppSuperAdmin(normalized)) return;
    final snap = await _firestore
        .collection(collectionName)
        .doc(docIdForEmail(normalized))
        .get();
    if (!snap.exists) return;
    final h = snap.data()?['homeApp'] as String?;
    if (h != null && h != FanAppIdentity.registryAppId) {
      await performSignOut();
      throw FanAppRegistryException(FanAppIdentity.wrongAppMessageFor(h));
    }
  }
}
