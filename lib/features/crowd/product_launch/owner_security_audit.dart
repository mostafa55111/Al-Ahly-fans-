import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_authority_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/launch_contract.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';

/// تدقيق أمن المالك — بريد whitelist فقط، بدون bypass في release.
class OwnerSecurityAudit {
  OwnerSecurityAudit._();

  static final OwnerSecurityAudit instance = OwnerSecurityAudit._();

  final List<String> _findings = [];

  void runReleaseChecks({OwnerAuthorityService? owners}) {
    _findings.clear();
    if (ReleaseModeGuard.isStrictRelease) {
      _add('multi_admin_disabled:owner_email_only');
      _add('uid_bypass_disabled:email_gate_only');
      _add('local_debug_bypass_disabled');
    }
    if (owners != null &&
        owners.isLoaded &&
        owners.identity.whitelistedEmails.isEmpty) {
      _add('warning:owner_whitelist_empty');
    }
  }

  void auditAdminElevationAttempt({
    required String path,
    required bool viaRtdbAdminNode,
  }) {
    if (viaRtdbAdminNode && ReleaseModeGuard.isStrictRelease) {
      _add('blocked:rtdb_admins_node_not_owner_gate:$path');
      LaunchContract.warnUnsupported(
        'public_admin_roles',
        reason: 'owner_security_audit',
      );
    }
  }

  void _add(String finding) {
    _findings.add(finding);
    if (kDebugMode) debugPrint('[OwnerSecurityAudit] $finding');
  }

  List<String> get findings => List.unmodifiable(_findings);

  bool get passedReleaseChecks =>
      !_findings.any((f) => f.startsWith('blocked:'));

  Map<String, dynamic> snapshot() => {
        'findings': _findings,
        'passed': passedReleaseChecks,
        'strictRelease': ReleaseModeGuard.isStrictRelease,
      };
}
