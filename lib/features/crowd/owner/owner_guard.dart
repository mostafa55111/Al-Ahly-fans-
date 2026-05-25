import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_authority_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/secure_owner_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_auth_service.dart';

/// بوابة وصول المالك — لا مسارات إدارة للعامة.
class OwnerGuard {
  OwnerGuard(this._owners);

  final OwnerAuthorityService _owners;

  Future<bool> canAccessAdmin({User? user}) async {
    if (getIt.isRegistered<OwnerAuthService>()) {
      return getIt<OwnerAuthService>().hasPrivilegedSession();
    }
    final u = user ?? FirebaseAuth.instance.currentUser;
    if (getIt.isRegistered<SecureOwnerResolver>()) {
      return getIt<SecureOwnerResolver>().isOwner(u);
    }
    return _owners.isOwnerUser(u);
  }

  Future<bool> canMutateCms({User? user}) => canAccessAdmin(user: user);

  Future<bool> canPublishSession({User? user}) => canAccessAdmin(user: user);
}
