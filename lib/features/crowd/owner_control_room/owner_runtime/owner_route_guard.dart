import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_guard.dart';

/// مسارات غرفة التحكم — مالك فقط.
abstract final class OwnerRouteGuard {
  static Future<bool> canOpenControlRoom({User? user}) async {
    if (!getIt.isRegistered<OwnerGuard>()) return false;
    return getIt<OwnerGuard>().canAccessAdmin(user: user);
  }

  static Future<void> assertOwnerOrThrow({User? user}) async {
    final ok = await canOpenControlRoom(user: user);
    if (!ok) {
      throw StateError('owner_only');
    }
  }
}
