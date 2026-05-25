import 'package:flutter/foundation.dart';

/// قنوات الإصدار — تحكم في أدوات التشغيل والسجلات.
enum ReleaseChannel {
  internal,
  alpha,
  beta,
  production,
}

extension ReleaseChannelX on ReleaseChannel {
  String get wireName => name;

  bool get allowsVerificationDashboard =>
      this == ReleaseChannel.internal || this == ReleaseChannel.alpha;

  bool get allowsChaosInjection => this == ReleaseChannel.internal;

  bool get allowsSandboxLoadSimulation =>
      this != ReleaseChannel.production;

  bool get verboseOperationalLogs =>
      this == ReleaseChannel.internal || this == ReleaseChannel.alpha;

  bool get strictProductionGuards => this == ReleaseChannel.production;

  static ReleaseChannel fromWire(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'internal':
        return ReleaseChannel.internal;
      case 'alpha':
        return ReleaseChannel.alpha;
      case 'beta':
        return ReleaseChannel.beta;
      case 'production':
      case 'prod':
        return ReleaseChannel.production;
      default:
        return kReleaseMode
            ? ReleaseChannel.production
            : ReleaseChannel.internal;
    }
  }
}
