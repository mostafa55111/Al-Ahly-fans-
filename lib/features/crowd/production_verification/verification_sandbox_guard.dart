import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel_resolver.dart';

/// يمنع محاكاة التحميل على جلسات الإنتاج الحية.
class VerificationSandboxGuard {
  VerificationSandboxGuard._();

  static const productionPathPrefixes = [
    'match_votes/',
    'match_vote_shards/',
    'awards/',
  ];

  static bool get isVerificationAllowed {
    if (!kDebugMode) return false;
    if (CrowdEnvironmentResolver.isBootstrapped &&
        !CrowdEnvironmentResolver.current.allowsSandboxSessions) {
      return false;
    }
    if (ReleaseChannelResolver.isBootstrapped &&
        !ReleaseChannelResolver.current.allowsVerificationDashboard) {
      return false;
    }
    return true;
  }

  static bool isSandboxSessionId(String sessionId) {
    final id = sessionId.trim().toLowerCase();
    return id.startsWith('sandbox_') ||
        id.startsWith('verify_') ||
        id.startsWith('loadtest_');
  }

  static void assertSandboxSession(String sessionId) {
    if (!isVerificationAllowed) {
      throw StateError('verification_disabled_in_release');
    }
    CrowdEnvironmentResolver.assertNotProductionSandbox(sessionId);
    if (!isSandboxSessionId(sessionId)) {
      throw StateError(
        'blocked: session "$sessionId" is not a sandbox id '
        '(use sandbox_ / verify_ / loadtest_ prefix)',
      );
    }
  }

  static String newSandboxSessionId(String scenario) {
    final safe = scenario.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    return 'sandbox_${safe}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
