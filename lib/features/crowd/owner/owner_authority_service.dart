import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_identity.dart';

/// يحمّل قائمة مالك التطبيق من `app_configs/owner_emails`.
class OwnerAuthorityService {
  OwnerAuthorityService({
    required FirebaseDatabase database,
    required FirebaseAuth auth,
  })  : _db = database,
        _auth = auth;

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  OwnerIdentity _identity = const OwnerIdentity();
  bool _loaded = false;

  OwnerIdentity get identity => _identity;

  Future<void> bootstrap() async {
    try {
      final snap = await _db.ref('app_configs/owner_emails').get();
      final emails = <String>{};
      if (snap.exists && snap.value != null) {
        final v = snap.value;
        if (v is List) {
          for (final e in v) {
            final s = e?.toString().trim().toLowerCase() ?? '';
            if (s.isNotEmpty) emails.add(s);
          }
        } else if (v is Map) {
          v.forEach((_, val) {
            final s = val?.toString().trim().toLowerCase() ?? '';
            if (s.isNotEmpty) emails.add(s);
          });
        } else if (v is String && v.contains('@')) {
          emails.add(v.trim().toLowerCase());
        }
      }
      final canonical =
          FanAppIdentity.normalizeEmail(FanAppIdentity.crossAppSuperAdminEmail);
      _identity = OwnerIdentity(whitelistedEmails: {canonical});
      if (emails.isNotEmpty && !emails.contains(canonical)) {
        debugPrint(
          '[OwnerAuthority] RTDB owner list ignored — canonical owner only',
        );
      }
      _loaded = true;
      debugPrint('[OwnerAuthority] owner gate: $canonical');
    } catch (e, st) {
      debugPrint('[OwnerAuthority] bootstrap: $e\n$st');
      final canonical =
          FanAppIdentity.normalizeEmail(FanAppIdentity.crossAppSuperAdminEmail);
      _identity = OwnerIdentity(whitelistedEmails: {canonical});
      _loaded = true;
    }
  }

  bool get isLoaded => _loaded;

  bool isCurrentUserOwner() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return _identity.isOwnerEmail(user.email);
  }

  Future<bool> isOwnerUser(User? user) async {
    if (!_loaded) await bootstrap();
    if (user == null) return false;
    return _identity.isOwnerEmail(user.email);
  }
}
