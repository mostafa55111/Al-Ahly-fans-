import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/secure_owner_resolver.dart';

enum OwnerAuditAction {
  login,
  sessionPublish,
  cardUpload,
  cardDelete,
  lineupPublish,
  emergencyRollback,
  authorityModeSwitch,
  sessionFreeze,
}

/// سجل تدقيق المالك — append-only تحت owner_audit/{club}.
class OwnerAuditLog {
  OwnerAuditLog({
    required FirebaseDatabase database,
    required FirebaseAuth auth,
    required SecureOwnerResolver resolver,
  })  : _db = database,
        _auth = auth,
        _resolver = resolver;

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;
  final SecureOwnerResolver _resolver;

  String get _club => _resolver.clubScope();

  DatabaseReference _entries() =>
      _db.ref('owner_audit/$_club/entries');

  Future<void> append({
    required OwnerAuditAction action,
    String? matchId,
    Map<String, dynamic>? details,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (!await _resolver.isOwner(user)) return;

    final payload = <String, dynamic>{
      'action': action.name,
      'email': user.email ?? '',
      'uid': user.uid,
      'matchId': matchId ?? '',
      'club': _club,
      'atMs': DateTime.now().millisecondsSinceEpoch,
      if (details != null) 'details': details,
    };

    try {
      await _entries().push().set(payload);
    } catch (e, st) {
      debugPrint('[OwnerAudit] append failed: $e\n$st');
    }
  }

  Future<void> logLogin() => append(action: OwnerAuditAction.login);

  Future<void> logSessionPublish(String matchId) => append(
        action: OwnerAuditAction.sessionPublish,
        matchId: matchId,
      );

  Future<void> logCardUpload(String cardId) => append(
        action: OwnerAuditAction.cardUpload,
        details: {'cardId': cardId},
      );

  Future<void> logCardDelete(String cardId) => append(
        action: OwnerAuditAction.cardDelete,
        details: {'cardId': cardId},
      );

  Future<void> logLineupPublish(String matchId) => append(
        action: OwnerAuditAction.lineupPublish,
        matchId: matchId,
      );

  Future<void> logEmergencyRollback(String reason) => append(
        action: OwnerAuditAction.emergencyRollback,
        details: {'reason': reason},
      );

  Future<void> logAuthorityMode(String mode) => append(
        action: OwnerAuditAction.authorityModeSwitch,
        details: {'mode': mode},
      );

  Future<void> logSessionFreeze(String matchId, bool frozen) => append(
        action: OwnerAuditAction.sessionFreeze,
        matchId: matchId,
        details: {'frozen': frozen},
      );
}
