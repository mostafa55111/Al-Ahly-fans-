import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_execution_mode.dart';

/// يقرأ `crowd_authority_mode` من Remote Config مع fallback محلي.
class CrowdAuthorityConfigService {
  CrowdAuthorityConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remote = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remote;

  static const _paramMode = 'crowd_authority_mode';
  static const _defaults = {_paramMode: 'local'};

  CrowdAuthorityMode _cached = CrowdAuthorityMode.local;
  bool _ready = false;

  CrowdAuthorityMode get mode => _cached;
  bool get isReady => _ready;

  Future<void> bootstrap() async {
    try {
      await _remote.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 1),
        ),
      );
      await _remote.setDefaults(_defaults);
      await _remote.fetchAndActivate();
      _cached = CrowdAuthorityModeX.fromWire(_remote.getString(_paramMode));
      _ready = true;
      debugPrint('[CrowdAuthorityConfig] mode=${_cached.wireName}');
    } catch (e, st) {
      debugPrint('[CrowdAuthorityConfig] bootstrap failed: $e\n$st');
      _cached = CrowdAuthorityMode.local;
      _ready = true;
    }
  }

  AuthorityExecutionMode resolveExecutionMode() =>
      _cached.toExecutionMode();
}
