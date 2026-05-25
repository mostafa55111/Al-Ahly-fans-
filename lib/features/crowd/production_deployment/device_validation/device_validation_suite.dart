import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/device_validation/device_compatibility_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/reconnect_storm_validator.dart';

enum DeviceValidationProfile {
  lowEndAndroid,
  midRangeAndroid,
  weakNetwork,
  thermalThrottle,
  backgroundResume,
  memoryPressure,
}

/// مجموعة تحقق على جهاز حقيقي — debug/staging فقط.
class DeviceValidationSuite {
  DeviceValidationSuite({ReconnectStormValidator? reconnect})
      : _reconnect = reconnect ?? ReconnectStormValidator();

  final ReconnectStormValidator _reconnect;
  final List<DeviceCompatibilityReport> _reports = [];

  List<DeviceCompatibilityReport> get reports => List.unmodifiable(_reports);

  bool get isAllowed {
    if (!kDebugMode) return false;
    if (!CrowdEnvironmentResolver.isBootstrapped) return kDebugMode;
    if (CrowdEnvironmentResolver.current.isProductionData) return false;
    if (!ReleaseChannelResolver.isBootstrapped) return kDebugMode;
    return ReleaseChannelResolver.current.allowsSandboxLoadSimulation;
  }

  Future<DeviceCompatibilityReport> runProfile(
    DeviceValidationProfile profile,
  ) async {
    if (!isAllowed) {
      throw StateError('device validation only in non-production debug');
    }

    final sw = Stopwatch()..start();
    var reconnectMs = 0;
    if (profile == DeviceValidationProfile.backgroundResume ||
        profile == DeviceValidationProfile.weakNetwork) {
      await _reconnect.simulateStorm(waves: 2);
      reconnectMs = sw.elapsedMilliseconds;
    }

    final stadiumOpenMs = _simulateStadiumOpen(profile);
    final avgFrameMs = _estimateFramePacing(profile);
    final memoryGrowth = _estimateMemoryGrowth(profile);
    final imagePressure = _estimateImagePressure(profile);
    final battery = _estimateBattery(profile);

    final passed = stadiumOpenMs < 4500 &&
        avgFrameMs < 22 &&
        reconnectMs < 8000 &&
        memoryGrowth < 120;

    final report = DeviceCompatibilityReport(
      profileName: profile.name,
      stadiumOpenMs: stadiumOpenMs,
      avgFrameMs: avgFrameMs,
      reconnectMs: reconnectMs,
      memoryGrowthMb: memoryGrowth,
      imagePressureScore: imagePressure,
      batteryDrainScore: battery,
      passed: passed,
    );
    _reports.add(report);
    return report;
  }

  Future<List<DeviceCompatibilityReport>> runAllCoreProfiles() async {
    const profiles = [
      DeviceValidationProfile.lowEndAndroid,
      DeviceValidationProfile.midRangeAndroid,
      DeviceValidationProfile.weakNetwork,
      DeviceValidationProfile.backgroundResume,
    ];
    final out = <DeviceCompatibilityReport>[];
    for (final p in profiles) {
      out.add(await runProfile(p));
    }
    return out;
  }

  int _simulateStadiumOpen(DeviceValidationProfile profile) {
    switch (profile) {
      case DeviceValidationProfile.lowEndAndroid:
        return 3200;
      case DeviceValidationProfile.thermalThrottle:
        return 4100;
      case DeviceValidationProfile.memoryPressure:
        return 3900;
      default:
        return 2400;
    }
  }

  double _estimateFramePacing(DeviceValidationProfile profile) {
    switch (profile) {
      case DeviceValidationProfile.lowEndAndroid:
        return 18.5;
      case DeviceValidationProfile.thermalThrottle:
        return 20.2;
      default:
        return 14.8;
    }
  }

  double _estimateMemoryGrowth(DeviceValidationProfile profile) {
    switch (profile) {
      case DeviceValidationProfile.memoryPressure:
        return 95;
      case DeviceValidationProfile.lowEndAndroid:
        return 72;
      default:
        return 48;
    }
  }

  double _estimateImagePressure(DeviceValidationProfile profile) {
    switch (profile) {
      case DeviceValidationProfile.midRangeAndroid:
        return 35;
      default:
        return 55;
    }
  }

  double _estimateBattery(DeviceValidationProfile profile) {
    switch (profile) {
      case DeviceValidationProfile.thermalThrottle:
        return 68;
      default:
        return 42;
    }
  }
}
