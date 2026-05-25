import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel.dart';

/// يقرأ `release_channel` من Remote Config مع `--dart-define`.
class ReleaseChannelResolver {
  ReleaseChannelResolver._();

  static ReleaseChannel? _channel;

  static bool get isBootstrapped => _channel != null;

  static ReleaseChannel get current {
    assert(_channel != null, 'ReleaseChannelResolver.bootstrap() first');
    return _channel!;
  }

  static Future<void> bootstrap({FirebaseRemoteConfig? remoteConfig}) async {
    final define = const String.fromEnvironment(
      'RELEASE_CHANNEL',
      defaultValue: '',
    );
    var channel = ReleaseChannelX.fromWire(define);

    try {
      final rc = remoteConfig ?? FirebaseRemoteConfig.instance;
      final rcWire = rc.getString('release_channel');
      if (rcWire.trim().isNotEmpty) {
        channel = ReleaseChannelX.fromWire(rcWire);
      }
    } catch (e) {
      debugPrint('[ReleaseChannel] RC read skipped: $e');
    }

    if (kReleaseMode && channel == ReleaseChannel.internal) {
      channel = ReleaseChannel.production;
    }

    _channel = channel;
    debugPrint('[ReleaseChannel] ${channel.wireName}');
  }

  @visibleForTesting
  static void resetForTest() => _channel = null;
}
