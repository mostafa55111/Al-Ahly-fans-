import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/environment_profile.dart';

/// يحل بيئة التشغيل من `--dart-define=CROWD_ENV=` مع fallback آمن.
class CrowdEnvironmentResolver {
  CrowdEnvironmentResolver._();

  static EnvironmentProfile? _profile;

  static EnvironmentProfile get current {
    assert(_profile != null, 'CrowdEnvironmentResolver.bootstrap() first');
    return _profile!;
  }

  static bool get isBootstrapped => _profile != null;

  static Future<void> bootstrap({String? overrideWire}) async {
    final wire = (overrideWire ??
            const String.fromEnvironment(
              'CROWD_ENV',
              defaultValue: '',
            ))
        .trim()
        .toLowerCase();

    final env = _parse(wire);
    _profile = EnvironmentProfile.forEnv(
      env,
      clubTag: FanAppIdentity.registryAppId,
    );

    if (_profile!.isProductionData && kDebugMode) {
      debugPrint(
        '[CrowdEnv] WARNING: production profile in debug build — '
        'verify CROWD_ENV',
      );
    }
    debugPrint('[CrowdEnv] ${_profile!.environment.name} '
        'ns=${_profile!.rtdbNamespace} sandbox=${_profile!.allowsSandboxSessions}');
  }

  static DeploymentEnvironment _parse(String wire) {
    if (wire == 'staging') return DeploymentEnvironment.staging;
    if (wire == 'production' || wire == 'prod') {
      return DeploymentEnvironment.production;
    }
    if (wire == 'development' || wire == 'dev') {
      return DeploymentEnvironment.development;
    }
    if (kReleaseMode) return DeploymentEnvironment.production;
    return DeploymentEnvironment.development;
  }

  /// يمنع كتابة بيانات sandbox على مسارات الإنتاج.
  static void assertNotProductionSandbox(String sessionId) {
    if (!isBootstrapped) return;
    if (!current.allowsSandboxSessions &&
        _looksLikeSandbox(sessionId)) {
      throw StateError(
        'sandbox session "$sessionId" blocked in ${current.environment.name}',
      );
    }
  }

  static bool _looksLikeSandbox(String id) {
    final s = id.trim().toLowerCase();
    return s.startsWith('sandbox_') ||
        s.startsWith('verify_') ||
        s.startsWith('loadtest_');
  }

  @visibleForTesting
  static void resetForTest() => _profile = null;
}
