import 'package:flutter/foundation.dart';

/// يمنع تكديس مسارات الجمهور/الطبقات الغامرة — debug warnings فقط.
class CrowdNavigationRuntimeGuard {
  CrowdNavigationRuntimeGuard._();

  static final CrowdNavigationRuntimeGuard instance =
      CrowdNavigationRuntimeGuard._();

  int _crowdScreenMounts = 0;
  int _immersiveShellMounts = 0;
  int _hallOverlayMounts = 0;
  int _pushedCrowdRoutes = 0;

  int get crowdScreenMounts => _crowdScreenMounts;
  int get immersiveShellMounts => _immersiveShellMounts;

  /// true إذا كان هذا أول mount مسموح.
  bool registerCrowdScreenMount() {
    _crowdScreenMounts++;
    if (kDebugMode && _crowdScreenMounts > 1) {
      debugPrint(
        '[CrowdNavGuard] duplicate CrowdScreen mount (count=$_crowdScreenMounts)',
      );
    }
    return _crowdScreenMounts == 1;
  }

  void unregisterCrowdScreenMount() {
    if (_crowdScreenMounts > 0) _crowdScreenMounts--;
  }

  bool registerImmersiveShell() {
    _immersiveShellMounts++;
    if (kDebugMode && _immersiveShellMounts > 1) {
      debugPrint(
        '[CrowdNavGuard] nested CrowdFanImmersiveShell (count=$_immersiveShellMounts)',
      );
    }
    return _immersiveShellMounts == 1;
  }

  void unregisterImmersiveShell() {
    if (_immersiveShellMounts > 0) _immersiveShellMounts--;
  }

  void registerHallOverlay() {
    _hallOverlayMounts++;
    if (kDebugMode && _hallOverlayMounts > 1) {
      debugPrint(
        '[CrowdNavGuard] duplicate HallOfFame overlay layer (count=$_hallOverlayMounts)',
      );
    }
  }

  void unregisterHallOverlay() {
    if (_hallOverlayMounts > 0) _hallOverlayMounts--;
  }

  /// قبل Navigator.push لشاشة الجمهور — يعيد false لمنع التكرار.
  bool tryAcquireCrowdRoutePush() {
    if (_pushedCrowdRoutes > 0) {
      if (kDebugMode) {
        debugPrint(
          '[CrowdNavGuard] blocked duplicate crowd route push',
        );
      }
      return false;
    }
    _pushedCrowdRoutes++;
    return true;
  }

  void releaseCrowdRoutePush() {
    if (_pushedCrowdRoutes > 0) _pushedCrowdRoutes--;
  }
}
