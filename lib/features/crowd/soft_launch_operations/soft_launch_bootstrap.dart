import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_governor.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_remote_config.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_surface_gate.dart';

/// تهيئة الإطلاق الناعم — Phase Launch 2.
class SoftLaunchBootstrap {
  SoftLaunchBootstrap._();

  static final SoftLaunchGovernor governor = SoftLaunchGovernor();

  static Future<void> initialize() async {
    await SoftLaunchRemoteConfig.installDefaults();
    if (SoftLaunchSurfaceGate.visible) {
      final snap = governor.operationalSnapshot();
      debugPrint('[SoftLaunch] initialized $snap');
    }
  }
}
