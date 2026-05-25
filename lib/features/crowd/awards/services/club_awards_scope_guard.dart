import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';

/// تحقق debug — عزل النادي في مسارات الجوائز.
class ClubAwardsScopeGuard {
  ClubAwardsScopeGuard._();

  static void assertClubPath(String clubTag, String path) {
    assert(() {
      final expected = FanAppIdentity.registryAppId.trim().toLowerCase();
      final tag = clubTag.trim().toLowerCase();
      if (tag != expected) {
        debugPrint(
          '[ClubAwardsScope] ASSERT path=$path tag=$tag expected=$expected',
        );
      }
      if (!path.contains('/$expected/') && !path.endsWith('/$expected')) {
        debugPrint(
          '[ClubAwardsScope] ASSERT path mismatch: $path for club $expected',
        );
      }
      return true;
    }());
  }

  static void assertClubTag(String clubTag) {
    assert(() {
      final expected = FanAppIdentity.registryAppId.trim().toLowerCase();
      if (clubTag.trim().toLowerCase() != expected) {
        debugPrint(
          '[ClubAwardsScope] ASSERT clubTag=$clubTag expected=$expected',
        );
      }
      return true;
    }());
  }
}
