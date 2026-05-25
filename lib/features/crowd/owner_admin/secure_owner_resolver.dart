import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_authority_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';

/// مصدر واحد لصلاحية المالك — بريد Auth + RTDB + نطاق البيئة.
class SecureOwnerResolver {
  SecureOwnerResolver(this._owners);

  final OwnerAuthorityService _owners;

  Future<bool> isOwner(User? user) async {
    if (user == null) return false;
    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;

    if (FanAppIdentity.isCrossAppSuperAdmin(email)) return true;

    if (!await _owners.isOwnerUser(user)) {
      return _isStagingScopedOwner(email);
    }
    return true;
  }

  bool _isStagingScopedOwner(String email) {
    if (ReleaseModeGuard.isStrictRelease) return false;
    if (!CrowdEnvironmentResolver.isBootstrapped) return false;
    if (CrowdEnvironmentResolver.current.isProductionData) return false;
    try {
      final csv = FirebaseRemoteConfig.instance
          .getString('crowd_staging_owner_emails');
      if (csv.trim().isEmpty) return false;
      final allowed = csv
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.contains('@'));
      return allowed.contains(email);
    } catch (e) {
      debugPrint('[SecureOwnerResolver] staging scope: $e');
      return false;
    }
  }

  String clubScope() => FanAppIdentity.registryAppId;
}
