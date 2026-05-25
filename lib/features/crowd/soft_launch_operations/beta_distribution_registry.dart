import 'package:flutter/foundation.dart';

/// مرحلة توزيع التجريب — بدون نظام إدارة مستخدمين عام.
enum BetaDistributionPhase {
  internal,
  closedBeta,
  softLaunch,
  publicLocked,
}

class BetaDeviceRecord {
  const BetaDeviceRecord({
    required this.deviceId,
    required this.phase,
    required this.releaseChannel,
    required this.cohort,
    this.isOwnerDevice = false,
    this.isInternalTester = false,
    this.isApprovedBeta = false,
  });

  final String deviceId;
  final BetaDistributionPhase phase;
  final String releaseChannel;
  final String cohort;
  final bool isOwnerDevice;
  final bool isInternalTester;
  final bool isApprovedBeta;
}

/// سجل توزيع داخلي — ذاكرة فقط.
class BetaDistributionRegistry {
  BetaDistributionRegistry._();

  static final BetaDistributionRegistry instance = BetaDistributionRegistry._();

  BetaDistributionPhase _globalPhase = BetaDistributionPhase.publicLocked;
  final Map<String, BetaDeviceRecord> _devices = {};

  BetaDistributionPhase get globalPhase => _globalPhase;

  void setGlobalPhase(BetaDistributionPhase phase) {
    _globalPhase = phase;
  }

  void register({
    required String deviceId,
    required String releaseChannel,
    required String cohort,
    bool ownerDevice = false,
    bool internalTester = false,
    bool approvedBeta = false,
  }) {
    _devices[deviceId] = BetaDeviceRecord(
      deviceId: deviceId,
      phase: _globalPhase,
      releaseChannel: releaseChannel,
      cohort: cohort,
      isOwnerDevice: ownerDevice,
      isInternalTester: internalTester,
      isApprovedBeta: approvedBeta,
    );
  }

  BetaDeviceRecord? lookup(String deviceId) => _devices[deviceId];

  List<BetaDeviceRecord> get allDevices => List.unmodifiable(_devices.values);

  int get internalCount =>
      _devices.values.where((d) => d.isInternalTester).length;

  int get ownerDeviceCount =>
      _devices.values.where((d) => d.isOwnerDevice).length;

  int get approvedBetaCount =>
      _devices.values.where((d) => d.isApprovedBeta).length;

  @visibleForTesting
  void resetForTests() {
    _globalPhase = BetaDistributionPhase.publicLocked;
    _devices.clear();
  }
}
