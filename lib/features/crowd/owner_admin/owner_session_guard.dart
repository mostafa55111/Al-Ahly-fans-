import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_audit_log.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/secure_owner_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_secure_session.dart';

/// يتحقق من المالك عند الإقلاع وعند تغيّر Auth — يغلق الأسطح فوراً عند عدم التطابق.
class OwnerSessionGuard {
  OwnerSessionGuard({
    required FirebaseAuth auth,
    required SecureOwnerResolver resolver,
    OwnerAuditLog? audit,
    OwnerSecureSession? secureSession,
  })  : _auth = auth,
        _resolver = resolver,
        _audit = audit,
        _secureSession = secureSession;

  final FirebaseAuth _auth;
  final SecureOwnerResolver _resolver;
  final OwnerAuditLog? _audit;
  final OwnerSecureSession? _secureSession;

  final ValueNotifier<bool> adminSurfaceAllowed = ValueNotifier<bool>(false);

  StreamSubscription<User?>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _reevaluate(_auth.currentUser);
    _sub = _auth.authStateChanges().listen(_reevaluate);
  }

  Future<void> _reevaluate(User? user) async {
    final allowed = await _resolver.isOwner(user);
    var privileged = allowed;
    if (allowed && _secureSession != null) {
      privileged = await _secureSession!.isActiveForUid(user?.uid);
    }
    if (!privileged && _secureSession != null) {
      await _secureSession!.clear();
    }
    if (adminSurfaceAllowed.value != privileged) {
      adminSurfaceAllowed.value = privileged;
    }
    if (privileged) {
      await _audit?.logLogin();
    }
  }

  Future<bool> assertOwnerAccess() async {
    final user = _auth.currentUser;
    final ok = await _resolver.isOwner(user);
    var privileged = ok;
    if (ok && _secureSession != null) {
      privileged = await _secureSession!.isActiveForUid(user?.uid);
      if (privileged) {
        await _secureSession!.touch();
      }
    }
    if (!privileged) {
      await _secureSession?.clear();
    }
    adminSurfaceAllowed.value = privileged;
    return privileged;
  }

  void dispose() {
    _sub?.cancel();
    adminSurfaceAllowed.dispose();
  }
}
